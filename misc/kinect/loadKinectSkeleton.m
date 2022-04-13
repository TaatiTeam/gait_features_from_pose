function [error_in_skel_label, skel_struct, skel_struct_smooth] = loadKinectSkeleton(fullpath, label_file)
    label = importdata(label_file);
    skel_struct = NaN;
    skel_struct_smooth = NaN;
    error_in_skel_label = 0;
    skel_file = fullfile(fullpath, strcat('Skeleton_', string(label), '.csv'));
    try
    if ~exist(skel_file, 'file')
        error_in_skel_label = 2;
        return
    end
    catch
        % Poorly encoded -1 as 44, 48
        error_in_skel_label = 1;
        return
    end
    
    % Load raw data
    skel_struct = processKinectFromCSVFile(skel_file);
    skel_struct_smooth = skel_struct;
    % Filter - from SM_InitialProcessingCode from Sina
    [b, a] = butter(4,0.5);
    fields = getSkelFields(1, NaN);
    for joint = 1:length(fields)
        joint_name = fields{joint};
        for t = 1:length(skel_struct_smooth.(joint_name))
            joint_data = skel_struct_smooth.(joint_name);
            for d = 1:size(joint_data,2)
                try
                joint_data(:, d) = filtfilt(b,a,joint_data(:, d));
                catch
                end
            end
            skel_struct_smooth.(joint_name) = joint_data;
        end
    end

end