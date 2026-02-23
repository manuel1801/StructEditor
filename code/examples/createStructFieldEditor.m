function [scrollGrid, controls, readStructFcn] = createStructFieldEditor(parent, data, opts)
% createStructFieldEditor Create editable UI controls for struct fields in a scrollable container.
%
% Copy/paste helper intended for App Designer apps.
%
% Inputs
%   parent : UI container handle (e.g. app.UIFigure, app.GridLayout, app.Panel)
%   data   : scalar struct to edit
%   opts   : name-value options
%       LabelPosition : "left" (default) or "above"
%       RowHeight     : numeric scalar, default 28
%       RowSpacing    : numeric scalar, default 10
%       ColumnSpacing : numeric scalar, default 10
%
% Outputs
%   scrollGrid   : the scrollable uigridlayout
%   controls     : struct of created component handles keyed by field name
%   readStructFcn: function handle returning updated struct values
%
% Supported automatic field types
%   char/string         -> uieditfield('text')
%   scalar double/single-> uieditfield('numeric')
%   scalar integers     -> uispinner
%   numeric/logical arrays and matrices -> uitable
%   scalar logical      -> uicheckbox
%   categorical         -> uidropdown
%   datetime            -> uidatepicker
%
% Optional config fields (same pattern as StructEditor)
%   data.FieldName_ = @(p) customComponentHandle
%   data.FieldName_ = {'A','B','C'}   % convenience for char -> dropdown
%   data.FieldName_ = 'hidden'        % hide field

arguments
    parent
    data (1,1) struct
    opts.LabelPosition (1,1) string {mustBeMember(opts.LabelPosition,["left","above"])} = "left"
    opts.RowHeight (1,1) double {mustBePositive} = 28
    opts.RowSpacing (1,1) double {mustBeNonnegative} = 10
    opts.ColumnSpacing (1,1) double {mustBeNonnegative} = 10
end

controls = struct();
outputData = data;
fieldNames = string(fieldnames(data));
fieldNames = fieldNames(~endsWith(fieldNames, "_"));

scrollGrid = uigridlayout(parent);
scrollGrid.Scrollable = 'on';
scrollGrid.Padding = [6 6 6 6];
scrollGrid.ColumnSpacing = opts.ColumnSpacing;

n = numel(fieldNames);
if opts.LabelPosition == "left"
    scrollGrid.ColumnWidth = {180, '1x'};
    scrollGrid.RowHeight = repmat({opts.RowHeight}, 1, n);
    scrollGrid.RowSpacing = opts.RowSpacing;
else
    scrollGrid.ColumnWidth = {'1x'};
    scrollGrid.RowHeight = repmat({20, opts.RowHeight, opts.RowSpacing}, 1, n);
    scrollGrid.RowSpacing = 0;
end

visibleRow = 0;
for i = 1:n
    fieldName = fieldNames(i);
    value = data.(fieldName);

    config = [];
    cfgName = fieldName + "_";
    if isfield(data, cfgName)
        config = data.(cfgName);
    end

    if isequal(config, 'hidden') || isequal(config, "hidden")
        continue
    end

    visibleRow = visibleRow + 1;
    label = uilabel(scrollGrid, 'Text', localVarname2label(char(fieldName)) + ":");

    if opts.LabelPosition == "left"
        label.Layout.Row = visibleRow;
        label.Layout.Column = 1;
        label.HorizontalAlignment = 'right';
    else
        label.Layout.Row = visibleRow*3-2;
        label.Layout.Column = 1;
        label.HorizontalAlignment = 'left';
        label.VerticalAlignment = 'bottom';
    end

    h = iCreateControl(scrollGrid, value, config);
    h.Tag = char(fieldName);

    if opts.LabelPosition == "left"
        h.Layout.Row = visibleRow;
        h.Layout.Column = 2;
        controlRow = visibleRow;
    else
        h.Layout.Row = visibleRow*3-1;
        h.Layout.Column = 1;
        controlRow = visibleRow*3-1;
    end

    if isa(h, 'matlab.ui.control.Table')
        h.Data = iValueForControl(value);
        h.ColumnEditable = true(1, size(h.Data,2));
        h.CellEditCallback = @(src, ~) iOnTableChanged(src, fieldName);
        scrollGrid.RowHeight{controlRow} = max(120, opts.RowHeight*3);
    elseif isprop(h, 'Value')
        h.Value = iValueForControl(value);
        h.ValueChangedFcn = @(~, evt) iOnChanged(evt, fieldName);
    end

    controls.(fieldName) = h;
end

if opts.LabelPosition == "left"
    scrollGrid.RowHeight = repmat({opts.RowHeight}, 1, max(visibleRow,1));
else
    scrollGrid.RowHeight = repmat({20, opts.RowHeight, opts.RowSpacing}, 1, max(visibleRow,1));
end

% Re-apply any taller row height chosen for table controls.
controlNames = string(fieldnames(controls));
for i = 1:numel(controlNames)
    h = controls.(controlNames(i));
    if isa(h, 'matlab.ui.control.Table')
        scrollGrid.RowHeight{h.Layout.Row} = max(120, opts.RowHeight*3);
    end
end

readStructFcn = @() outputData;

    function iOnChanged(evt, fname)
        oldValue = outputData.(fname);
        newValue = evt.Value;

        if isa(oldValue, 'categorical')
            cats = categories(oldValue);
            outputData.(fname) = categorical({char(newValue)}, cats);
        elseif isnumeric(oldValue)
            outputData.(fname) = cast(newValue, 'like', oldValue);
        else
            outputData.(fname) = newValue;
        end
    end

    function iOnTableChanged(src, fname)
        oldValue = outputData.(fname);
        newValue = src.Data;

        if islogical(oldValue)
            outputData.(fname) = logical(newValue);
        else
            outputData.(fname) = cast(newValue, 'like', oldValue);
        end
    end
end

function h = iCreateControl(parent, value, config)
if ~isempty(config)
    if isa(config, 'function_handle')
        h = config(parent);
        return
    elseif ischar(config)
        h = feval(config, parent);
        return
    elseif iscell(config) && ischar(value)
        h = uidropdown(parent, 'Items', config);
        return
    end
end

if (isnumeric(value) || islogical(value)) && ~isscalar(value)
    h = uitable(parent);
    return
end

switch class(value)
    case {'char','string'}
        h = uieditfield(parent, 'text');
    case {'single','double'}
        h = uieditfield(parent, 'numeric', 'AllowEmpty', 'on');
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
        h = uispinner(parent, ...
            'Limits', double([intmin(class(value)), intmax(class(value))]), ...
            'AllowEmpty', 'on', ...
            'ValueDisplayFormat', '%d');
    case 'logical'
        h = uicheckbox(parent, 'Text', '');
    case 'categorical'
        h = uidropdown(parent, 'Items', categories(value));
    case 'datetime'
        h = uidatepicker(parent);
    otherwise
        h = uieditfield(parent, 'text');
end
end

function out = iValueForControl(value)
if isnumeric(value) && isempty(value)
    out = [];
    return
end

switch class(value)
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64'}
        out = double(value);
    case 'categorical'
        out = char(value);
    case 'datetime'
        out = value;
    otherwise
        out = value;
end
end

function label = localVarname2label(name)
label = regexprep(name, '([a-z])([A-Z])', '$1 $2');
label = regexprep(label, '_', ' ');
if ~isempty(label)
    label(1) = upper(label(1));
end
end
