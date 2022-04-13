function [skel, additional_data] = table2skel(T, export_conf, is_kinect, additional_data)
if ~exist('additional_data', 'var')
    additional_data = struct();
end

detector = T.detector(1);
% The fields for 2D detectors
if is_kinect
    export_conf = 0;
end

fields = getSkelFields(is_kinect, detector);
skel = struct();

% These are used by the discont analysis workflow
all_confs_by_joint_export = 0;
all_confs_export = 0;
if (isfield(additional_data, 'all_confs_by_joint'))
    all_confs_by_joint_export = 1;
end

if (isfield(additional_data, 'all_confs_detector'))
    all_confs_export = 1;
end


for f = 1:length(fields)
    field = fields{f};
    f_x = char(strcat(field, "_x"));
    f_y = char(strcat(field, "_y"));
    
    x = T.(f_x);
    y = T.(f_y);
    
    
    if export_conf && ~strcmp(detector, 'romp')
        f_conf = char(strcat(field, "_conf"));
        conf = T.(f_conf);
        
        skel.(field) = [x, y, conf];
        
    elseif strcmp(detector, 'romp')
        f_z = char(strcat(field, "_z"));
        z = T.(f_z);
        skel.(field) = [x, y, z];
        conf = 100 * ones(size(z));

    else
        skel.(field) = [x, y];
    end
    
    if all_confs_by_joint_export
        try
         additional_data.all_confs_by_joint.(strcat(field)) = [additional_data.all_confs_by_joint.(strcat(field)); conf];
        catch % This field doesn't exist yet, create it now
         additional_data.all_confs_by_joint.(strcat(field)) = [conf];
        end
    end
    
    if all_confs_export 
        additional_data.all_confs_detector = [additional_data.all_confs_detector ; conf];
    end
    
end

skel.x_range = [T.x_min, T.x_max];
skel.y_range = [T.y_min, T.y_max];

end

