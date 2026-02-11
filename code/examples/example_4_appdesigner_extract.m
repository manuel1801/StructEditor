function [updatedProfile, wasCanceled] = example_4_appdesigner_extract()
% Example 4: Copy/paste extraction for App Designer
%
% This function shows the standalone helper that builds editable field
% controls in a scrollable grid layout and returns the edited struct when
% the button is pushed.

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

[scrollGrid, ~, readStruct] = createStructFieldEditor(main, profile, ...
    'LabelPosition', 'left');
scrollGrid.Layout.Row = 1;

updatedProfile = profile;
wasCanceled = true;

fig.CloseRequestFcn = @onCancel;

btn = uibutton(main, 'Text', 'Save & Return Struct', ...
    'ButtonPushedFcn', @onSaveAndClose);
btn.Layout.Row = 2;

uiwait(fig)

if isvalid(fig)
    delete(fig)
end

    function onSaveAndClose(~, ~)
        updatedProfile = readStruct();
        wasCanceled = false;
        uiresume(fig)
    end

    function onCancel(~, ~)
        updatedProfile = profile;
        wasCanceled = true;
        uiresume(fig)
    end
end
