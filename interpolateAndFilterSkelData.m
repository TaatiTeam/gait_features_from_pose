function [interpolated_and_smoothed_skel] = interpolateAndFilterSkelData(skel,detector, filter_cutoff_hz, is_kinect, fps, conf_thres, interpolate_only)

if ~exist('interpolate_only', 'var')
    interpolate_only = 0;
end

interpolated_and_smoothed_skel = skel;
conf_thres = conf_thres/100;
% Step 1: Set poorly tracked points to NaN
fields = getSkelFields(is_kinect, detector);
if ~interpolate_only && ~strcmp(detector, 'romp')
    for joint = 1:length(fields)
        joint_name = fields{joint};
        for t = 1:length(skel.(joint_name))
            joint_data = skel.(joint_name);
            if (joint_data(t, 3) < conf_thres)
                skel.(joint_name)(t, 1:2) = NaN;
            end
        end
    end
end

% Using same values as Becky's work
[b, a] = butter(1,filter_cutoff_hz / fps, 'low'); % 8 Hz

dim_range = 1:2;
if strcmp(detector, 'romp')
    dim_range = 1:3;
end

% Step 2: Interpolate each joint over time
for joint = 1:length(fields)
    joint_name = fields{joint};
    joint_over_time = interpolated_and_smoothed_skel.(joint_name)(:, dim_range);
    interpolated_x = fillmissing(joint_over_time(:, 1), 'linear');
    interpolated_y = fillmissing(joint_over_time(:, 2), 'linear');
    interpolated_and_smoothed_skel.(joint_name)(:, 1) = interpolated_x;
    interpolated_and_smoothed_skel.(joint_name)(:, 2) = interpolated_y;
    
    if strcmp(detector, 'romp')
        interpolated_z = fillmissing(joint_over_time(:, 3), 'linear');

        interpolated_and_smoothed_skel.(joint_name)(:, 3) = interpolated_z;
    end
    
    % Step 3: Apply low pass filter, interpolate any NaNs that arise
    if ~interpolate_only
        
        for xy = dim_range
            try
                interpolated_and_smoothed_skel.(joint_name)(:, xy) = filtfilt(b, a, interpolated_and_smoothed_skel.(joint_name)(:, xy));
            catch
                fprintf("Failed to interpolate: %s", joint_name);
                interpolated_and_smoothed_skel.(joint_name)(:, xy) = interpolated_and_smoothed_skel.(joint_name)(:, xy);
            end
        end
    end
end

end % function

