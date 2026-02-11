% Example 4: Copy/paste extraction for App Designer
%
% This script shows the standalone helper that builds editable field controls
% in a scrollable grid layout.

profile = struct();
profile.Name = "Jane";
profile.Age = uint16(31);
profile.IsActive = true;
profile.Role = categorical({'Engineer'},{'Engineer','Manager','Analyst'});
profile.StartDate = datetime('today');

% Optional per-field config
profile.Bio = "";
profile.Bio_ = @(p) uitextarea(p, 'Placeholder', 'Write a short bio...');

fig = uifigure('Name','App Designer Extraction Demo','Position',[100 100 620 420]);
main = uigridlayout(fig,[2 1]);
main.RowHeight = {'1x', 36};

[scrollGrid, controls, readStruct] = createStructFieldEditor(main, profile, ...
    'LabelPosition', 'left'); %#ok<NASGU,ASGLU>
scrollGrid.Layout.Row = 1;

btn = uibutton(main, 'Text', 'Dump Struct To Console', ...
    'ButtonPushedFcn', @(~,~) disp(readStruct()));
btn.Layout.Row = 2;
