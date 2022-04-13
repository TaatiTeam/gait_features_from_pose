function [configs] = fixFlips(configs)


% Alias
fc = configs.fix_flip_configs;

root_folder = fc.input_folder;
root_folder_label = configs.labelling_configs.output_folder;
input_csv = fc.input_csv;



% Set up the files to process
all_walks_table = readtable(fc.input_csv);
all_walks_table_temp = readtable(fc.input_csv);
col_names = all_walks_table.Properties.VariableNames;

walks_with_flips = all_walks_table.flip_anywhere;
detectors = all_walks_table.detector;
walk_ids = all_walks_table.walk_id;


% Read from the output csv folder if we stopped halfway through relabelling
try
    out_T = readtable(fc.output_csv);
    
    true_flip_temp =  out_T.true_flip;
catch
    true_flip_temp = NaN*ones(height(all_walks_table), 1);
    
end

if (size(true_flip_temp, 1) == 0)
    true_flip_temp = NaN*ones(length(walk_ids), 1);
end


all_walks_table.true_flip = true_flip_temp;
% fields = getSkelFields(configs.is_kinect);

close all
fig = figure('units','normalized','outerposition',[0 0 1 1]); hold on

for i = 1:length(walks_with_flips)
    
    
    output_folder_detector_raw = fullfile(fc.output_folder, detectors{i}, "raw");
    output_folder_detector_smoothed = fullfile(fc.output_folder, detectors{i}, "interpolated");
    
    if ~exist(output_folder_detector_raw, 'dir')
        mkdir(output_folder_detector_raw);
    end
    if ~exist(output_folder_detector_smoothed, 'dir')
        mkdir(output_folder_detector_smoothed);
    end
    
    output_raw_file = fullfile(output_folder_detector_raw, walk_ids{i});
    output_smoothed_file = fullfile(output_folder_detector_smoothed, walk_ids{i});
    

    
    % Load the file of interest
    csv_file = fullfile(root_folder, detectors{i}, "raw", walk_ids{i});
    csv_file_label = fullfile(root_folder_label, detectors{i}, "raw", walk_ids{i});
    
    if ~exist(csv_file, 'file') % Dealing with dravet and lakeside dataset that has walks in form DV_XX.walk_name.csv
        csv_file = fullfile(root_folder, detectors{i}, "raw", strcat(walk_ids{i}, '.csv'));
        csv_file_label = fullfile(root_folder_label, detectors{i}, "raw", strcat(walk_ids{i}, '.csv'));
        
        output_raw_file = fullfile(output_folder_detector_raw, strcat(walk_ids{i}, '.csv'));
        output_smoothed_file = fullfile(output_folder_detector_smoothed, strcat(walk_ids{i}, '.csv'));
    end
    
    if exist(output_smoothed_file, 'file') && exist(output_raw_file, 'file') && fc.skip_if_output_file_exists
        continue;
    end
    
    try
        T = readtable(csv_file);
    catch 
        %TODO: error handling when we can't read the file
    end
    
    all_walks_table.true_flip(i) = 0;
    start_frame = T.start_frame(1);
    
%     joints = fc.joints;
    [~, joints] = getKeypointOrderInCSV(detectors{i});
    sides = ['L', 'R'];

    export_file = 1;
    clf(fig)
    set(0, 'CurrentFigure', fig)
    % Fix the flips
%     if walks_with_flips(i) && isnan(true_flip_temp(i)) && configs.do_flip_fix && ~configs.is_3d
    if fc.force_label_all || (walks_with_flips(i) && isnan(true_flip_temp(i)) && configs.do_flip_fix && ~strcmp(detectors{i}, 'kinect'))
        done_flipping = 0;
        fprintf("Now flipping: %d/%d: %s\n", sum(walks_with_flips(1:i)), sum(walks_with_flips), csv_file);
        while ~done_flipping
            skel = table2skel(T, 1, configs.is_kinect); % T may have changed from last iteration, so update
            flip_locs = struct(); % Reset the flip locations for this iteration
%             close all;            % Close the open plots so the only plot is the one from this iteration
            clf(fig)
            set(0, 'CurrentFigure', fig)

            if (mod(length(joints), 2) == 0)
                plot_width = length(joints) / 2;
                
            else
                plot_width = cast(length(joints) / 2, 'uint8');
                plot_width = cast(plot_width, 'double');
            end
            
            for j = 1:length(joints)
                subplot(2,plot_width,j), hold on,
                joint = joints{j};
                plot(skel.("L" + joint)(:, 1)), plot(skel.("R" + joint)(:, 1))
                title(joint + " Horizontal Position")
                
            end
            legend("Left" , "Right");
            
            keep_going = input("Keep going with flipping? (Yes: 1, No: 0): ");
            
            if ~keep_going
                done_flipping = 1;
                continue
            end
            % ======================= Remove large drops =======================
            drop_input = input("Drop by percentile? Try with ~98-99% and repeat if needed. PLEASE SAVE BETWEEN EACH ITERATION TO BE ABLE TO GO BACK: ");
            try
                percentileToDrop = drop_input; % Already as double
                if percentileToDrop > 0 && percentileToDrop <= 100
                    fprintf("Dropping percentile: %d\n", percentileToDrop);
                    
                    
                    for j = 1:length(joints)
                        for k = 1:2
                        
                            joint = sides(k) + joints{j};
% 
%                             joint_data = flip(abs(diff(flip((skel.(joint)(:, 1))), 1))); % only use xvalues to do the drops
%                             joint_data_1_start = skel.(joint)(1:2:end, 1); % only use xvalues to do the drops
%                             joint_data_2_start = skel.(joint)(2:2:end, 1); % only use xvalues to do the drops
%                             min_length = min(length(joint_data_1_start), length(joint_data_2_start));
                            joint_data2 = abs(diff((skel.(joint)(:, 1)), 2)); % only use xvalues to do the drops
                            diff_thres = abs(prctile(joint_data2,percentileToDrop)); % Note that NaNs are treated as values
                        
                            to_remove = joint_data2 > diff_thres;
                            remove_inds = find(to_remove) + 1;
                            
                            if (isempty(remove_inds))
                                [~, remove_inds] = max(joint_data2);
                                remove_inds = remove_inds + 1;
                            end
                            
                            
                            % Do the removal
                            x_loc = joint + "_x";
                            y_loc = joint + "_y";
                            conf_loc = joint + "_conf";
                            conf_val = 0;
                            if strcmp(detectors{i}, "romp")
                                conf_loc = joint + "_z";
                                conf_val = NaN;
                            end
                            
                            
                            T.(x_loc)(remove_inds) = NaN;
                            T.(y_loc)(remove_inds) = NaN;
                            T.(conf_loc)(remove_inds) = conf_val;
                            
                            
                        end
                    end
                    
                    continue; %update plots
                end
                
  
            catch
                percentileToDrop;
            end
            
            
            % ======================= Saving =======================
            change_input = input("Reload data or change input: 101 for discont reload, 102 for non-discont load, 103 for load of cur file\n 22 to save: ");
            
            
            
            try
                change_input_int = int16(change_input);
                if change_input_int == 22
                    fprintf("saving raw file to: %s\n", output_raw_file);
                    
                    writetable(T, output_raw_file);
                    continue;
                    
                elseif change_input_int == 101
                    T = readtable(csv_file);
                    continue;
                elseif change_input_int == 102
                    T = readtable(csv_file_label);
                    continue;
                    
                elseif change_input_int == 103
                    try
                        T = readtable(output_raw_file);
                        fprintf("loaded from to load: %s\n", output_raw_file);
                        
                        continue;
                    catch
                        fprintf("failed to load: %s\n", output_raw_file);
                        continue;
                    end
                end
            catch
            end
            
            
            
            
            % ============================= Cropping ===========================
            crop = input("Need to crop? Enter start and end of crop separated by comma: ", "s");
            if ~isempty(crop) % Cropping
                % Try to parse the string into a list
                inds = strsplit(crop, ",");
                ind_ints = [];
                for ints = 1:length(inds)
                    try
                        value = int16(str2double(inds{ints}));
                        ind_ints = [ind_ints, value];
                    catch
                        fprintf("Could not interpret %s as int\n", inds{ints});
                    end
                    
                end
                
                if length(ind_ints) ~= 2
                    fprintf("Incorrect format for cropping. Please try again\n");
                    continue
                end
                start_crop = ind_ints(1);
                end_crop = ind_ints(2);
                
                length_of_data = end_crop - start_crop + 1;
                
                if length_of_data < 1
                    fprintf("Incorrect format for cropping. Please try again\n");
                    continue;
                end
                
                % Idea: Copy all fields (including time) to the top of the
                % table, then delete everything at the bottom.
                
                all_fields = T.Properties.VariableNames;
                start_frame = start_frame + start_crop - 1;
                for col_num = 1:length(all_fields)
                    cur_col = all_fields{col_num};
                    T.(cur_col)(1:length_of_data) =T.(cur_col)(start_crop:end_crop) ;
                end
                T(length_of_data:end, :) = [];
                all_walks_table.true_flip(i) = 1;
                
                
                % Update the start_frame
                start_frame_rep = repmat(start_frame, height(T), 1);
                T.start_frame = start_frame_rep;
                continue;
            end
            
            
            % ============================= Removing ===========================
            remove_data = input("Need to remove data? ", "s");
            if ~isempty(remove_data) % What joints to remove data for?
                remove_locs = struct();
                % Step 2: Label where we should remove the frames
                
                for j = 1:length(joints)
                    for k = 1:2
                        
                        joint = sides(k) + joints{j};
                        temp_in = input("Indices to remove " + joint + " at (0 for no remove): ", 's');
                        
                        if isempty(temp_in)
                            % Do nothing
                        else
                            % Try to parse the string into a list
                            inds = strsplit(temp_in, ",");
                            ind_ints = [];
                            
                            for ints = 1:length(inds)
                                try
                                    inds_2 = strsplit(inds{ints}, "-");
                                    value = int16(str2double(inds_2{1})):int16(str2double(inds_2{2}));
                                catch
                                    try
                                        value = int16(str2double(inds{ints}));
                                    catch
                                        fprintf("Could not interpret %s as int\n", inds{ints});
                                    end
                                    
                                end
                                ind_ints = [ind_ints, value];
                                
                            end
                            remove_locs.(joint) = ind_ints;
                        end
                    end
                end
                
                
                remove_joint_names = fieldnames(remove_locs);
                for remove_joint_num = 1:length(remove_joint_names)
                    joint = remove_joint_names{remove_joint_num};
                    for remove_loc_num = 1:length(remove_locs.(joint))
                        flip_loc = remove_locs.(joint)(remove_loc_num);
                        x_loc = joint + "_x";
                        y_loc = joint + "_y";
                        conf_loc = joint + "_conf";
                        conf_val = 0;
                        if strcmp(detectors{i}, "romp")
                            conf_loc = joint + "_z";
                            conf_val = NaN;
                        end
 
                            
                        T.(x_loc)(flip_loc) = NaN;
                        T.(y_loc)(flip_loc) = NaN;
                        T.(conf_loc)(flip_loc) = conf_val;
                        
                        
                    end
                end
                
                continue; % Replot everything and continue
                
            end
            
            % ============================= Flipping ===========================
            % Flipping
            all_joints = input("Enter flip locations for all (leave empty to enter joint by joint): ", 's');
            if isempty(all_joints)
                % Step 2: Label where we should flip the frames
                for j = 1:length(joints)
                    joint = joints{j};
                    
                    temp_in = input("Indices to flip " + upper(joints{j}) + "S at (0 for no flip): ", 's');
                    
                    if isempty(temp_in)
                        flip_locs.(joint) = 0;
                    else
                        % Try to parse the string into a list
                        inds = strsplit(temp_in, ",");
                        ind_ints = [];
                        
                        for ints = 1:length(inds)
                            try
                                inds_2 = strsplit(inds{ints}, "-");
                                value = int16(str2double(inds_2{1})):int16(str2double(inds_2{2}));
                            catch
                                try
                                    value = int16(str2double(inds{ints}));
                                catch
                                    fprintf("Could not interpret %s as int\n", inds{ints});
                                    
                                end
                                
                            end
                            ind_ints = [ind_ints, value];
                        end
                        flip_locs.(joint) = ind_ints;
                    end
                    
                    
                end
            else
                inds = strsplit(all_joints, ",");
                ind_ints = [];
                
                
                for ints = 1:length(inds)
                    try
                        inds_2 = strsplit(inds{ints}, "-");
                        value = int16(str2double(inds_2{1})):int16(str2double(inds_2{2}));
                    catch
                        value = int16(str2double(inds{ints}));
                        
                    end
                    ind_ints = [ind_ints, value];
                end
                for j = 1:length(joints)
                    joint = joints{j};
                    flip_locs.(joint) = ind_ints;
                end
            end
            
            
            
            
            % Step 3: Now flip the joints at the selected locations
            for j = 1:length(joints)
                
                joint = joints{j};
                
                flip_locs_joint = flip_locs.(joint);
                
                left_joint = "L" + joint;
                right_joint = "R" + joint;
                
                if flip_locs_joint ~= 0
                    all_walks_table.true_flip(i) = 1;
                    
                    for p = 1:length(flip_locs_joint)
                        flip_loc = flip_locs_joint(p);
                        % Copy from the skel struct to the T table
                        
                        % copying x
                        left_joint_x = left_joint + "_x";
                        right_joint_x = right_joint + "_x";
                        
                        T.(left_joint_x)(flip_loc) = skel.(right_joint)(flip_loc, 1);
                        T.(right_joint_x)(flip_loc) = skel.(left_joint)(flip_loc, 1);
                        
                        
                        % copying y
                        left_joint_y = left_joint + "_y";
                        right_joint_y = right_joint + "_y";
                        
                        T.(left_joint_y)(flip_loc) = skel.(right_joint)(flip_loc, 2);
                        T.(right_joint_y)(flip_loc) = skel.(left_joint)(flip_loc, 2);
                        
                        
                        if strcmp(detectors{i}, 'romp')
                            % copying y
                            left_joint_z = left_joint + "_z";
                            right_joint_z = right_joint + "_z";
                            
                            T.(left_joint_z)(flip_loc) = skel.(right_joint)(flip_loc, 3);
                            T.(right_joint_z)(flip_loc) = skel.(left_joint)(flip_loc, 3);
                            
                            
                        end
                        
                    end
                end
            end
        end % end while
        
        
    % This walk had a flip but it's fixed so DON'T OVERWRITE the file
    elseif walks_with_flips(i)
        export_file = 0;
    end
    
    % Saving for newly fixed flips and walks without flips
    if export_file
        % Save this data
        writetable(T, output_raw_file);
        % Now smooth the data and save it
        smooth_T = T;
        % Reload the skeleton from T
        skel = table2skel(smooth_T, 1, configs.is_kinect);
        
        conf_thres = getConfThres(detectors{i});
        filtered_skel = interpolateAndFilterSkelData(skel, detectors{i}, configs.filter_cutoff_hz, configs.is_kinect, smooth_T.fps(1), conf_thres, 0);
        smooth_T = updateTableWithSkelData(filtered_skel, smooth_T,configs.is_kinect, configs.is_3d);
        
        writetable(smooth_T, output_smoothed_file);
    end
    
    all_walks_table_temp([1],:) = [];
    writetable(all_walks_table, fc.output_csv);
    
end


end