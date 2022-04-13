function [pred_path,epart_path] = getEpartAndPredFileFromDetector(detector, walk_base)
err = 0;
if strcmp(detector, "openpose")
    pred_path = fullfile(walk_base,  'openpose.csv');
    epart_path = fullfile(walk_base,  'Eparticipant_openpose.csv');
    
elseif strcmp(detector, "detectron")  % Detectron
    pred_path = fullfile(walk_base, 'output_detectron.txt');
    epart_path = fullfile(walk_base, 'Eparticipant_detectron.csv');
    
    
elseif strcmp(detector, "alphapose")
    pred_path = fullfile(walk_base,  'alphapose-results.csv');
    epart_path = fullfile(walk_base,  'Eparticipant_alphapose.csv');

elseif strcmp(detector, "romp")
    pred_path = fullfile(walk_base,  'romp_results.mat');
    epart_path = fullfile(walk_base,  'Eparticipant_romp.csv');
    
else
    err = 1;
end


if err
    s = sprintf("invalid walk name: %s", detector);
    throw(MException('detector:invalidValue', s));
end

end

