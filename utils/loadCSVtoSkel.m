function [skel, start_frame] = loadCSVtoSkel(csv_file)
T = readtable(csv_file);
start_frame = 1; 
skel = struct;
% The fields for 2D detectors
fields = {'Nose', 'LEye', 'REye', 'LEar', ...
    'REar', 'LShoulder', 'RShoulder', 'LElbow', ...
    'RElbow', 'LWrist', 'RWrist', 'LHip', ...
    'RHip', 'LKnee', 'RKnee', 'LAnkle', ...
    'RAnkle'};

for f = 1:length(fields)
    field = fields{f};
    f_x = char(strcat(field, "_x"));
    f_y = char(strcat(field, "_y"));
    f_conf = char(strcat(field, "_conf"));
    
    x = T.(f_x);
    y = T.(f_y);
    conf = T.(f_conf);
    
    skel.(field) = [x, y, conf];
    
end

try
    start_frame = T.start_frame(1);
catch
end


skel.x_range = [T.x_min, T.x_max];
skel.y_range = [T.y_min, T.y_max];
skel.time = [T.time];

end

