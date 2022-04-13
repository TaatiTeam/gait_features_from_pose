function [T] = updateTableWithSkelData(skel, T, is_kinect, is_3d)
detector = T.detector{1};
skel = recalculateSkelXYRange(skel, is_kinect, is_3d, detector);

fields = getSkelFields(is_kinect, detector);

for f = 1:length(fields)
    field = fields{f};
    joint_x = field + "_x";
    joint_y = field + "_y";
    joint_z = field + "_z";
    joint_conf = field + "_conf";
    
    
    T.(joint_x) = skel.(field)(:, 1);
    T.(joint_y) = skel.(field)(:, 2);
    
    if ~is_kinect % video pose-tracker have confidence
        T.(joint_conf) = skel.(field)(:, 3);
        
    elseif is_3d
        T.(joint_z) = skel.(field)(:, 3);
        
    end
end

T.x_min = skel.x_range(:, 1);
T.x_max = skel.x_range(:, 2);

T.y_min = skel.y_range(:, 1);
T.y_max = skel.y_range(:, 2);

if is_3d
    T.z_min = skel.z_range(:, 1);
    T.z_max = skel.z_range(:, 2);
end
end

