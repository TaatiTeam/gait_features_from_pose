function [preview_im,epart_path] = getPreviewImAndEpart(detector, walk_base, optional_suffix)
if ~exist('optional_suffix','var')
    optional_suffix = '';
end



err = 0;
if strcmp(detector, "openpose")
    preview_im = fullfile(walk_base,  'frame_50.jpg');
elseif strcmp(detector, "detectron")  % Detectron
    preview_im = fullfile(walk_base, 'predimg50_detectron.jpg');
elseif strcmp(detector, "alphapose")
    preview_im = fullfile(walk_base,  'predimg50.jpg');
elseif strcmp(detector, 'romp')
    preview_im = fullfile(walk_base,  'frame_50.jpg'); % This doesn't get made by ROMP
else
    err = 1;
end


if ~isempty(optional_suffix)
    walk_base = fullfile(walk_base, optional_suffix);
    if ~exist(walk_base, 'dir')
        mkdir(walk_base);
    end
end

if strcmp(detector, "openpose")
    epart_path = fullfile(walk_base,  'Eparticipant_openpose.csv');
elseif strcmp(detector, "detectron")  % Detectron
    epart_path = fullfile(walk_base, 'Eparticipant_detectron.csv');
elseif strcmp(detector, "alphapose")
    epart_path = fullfile(walk_base,  'Eparticipant_alphapose.csv');
elseif strcmp(detector, "romp")
    epart_path = fullfile(walk_base,  'Eparticipant_romp.csv');
else
    err = 1;
end



if err
    s = sprintf("invalid walk name: %s", detector);
    throw(MException('detector:invalidValue', s));
end

end

