function [interpolated_and_smoothed_skel, discont_fixed_skel, output_table] = findDiscontinuitiesAndInterpolate(skel, detector, vid_configs, configs, second_pass)
if ~exist('second_pass','var')
    second_pass = 0;
end
% Local variables
num_frames_to_average = configs.discont_configs.num_frames_to_average;
joint_diff_thres = configs.discont_configs.joint_diff_thres;
joints_to_average = 1:2; % Both x and y
if second_pass
    num_frames_to_average = configs.discont_configs.num_frames_to_average2;
    joint_diff_thres = configs.discont_configs.joint_diff_thres2;
    joints_to_average = 1; % only x
end


fps = vid_configs.fps;
fields = vid_configs.fields;
walk_id = vid_configs.walk_name;

% These values are set based on experiments on the TRI dataset
if strcmp(detector, "openpose")
    conf_thres = 65;
elseif strcmp(detector, "detectron")  % Detectron
    conf_thres = 15;
elseif strcmp(detector, "alphapose")
    conf_thres = 60;
else
    conf_thres = 0;
end

if second_pass
    conf_thres = 0;
end


output_table = table();
table_suffixes = {'_discont_frames', '_discont_percentage', '_total_frames', '_discont_locations'};


min_y_diff = skel.y_range(:, 2) - skel.y_range(:, 1);
% interpolated_skel = interpolate_and_filter_skel_data_all(skel, conf_thres, 0, fps); % just interpolate joints with low confidence, don't filter
interpolated_skel = interpolateAndFilterSkelData(skel, detector, configs.filter_cutoff_hz, configs.is_kinect, fps, conf_thres, 1);

if second_pass
    interpolated_skel = skel; % Don't interpolate what we removed or do any smoothing
end

% Do any joints have disc
any_discont = 0;
lower_body_discont = 0;
upper_body_discont = 0;
head_discont = 0;
body_discont = 0;

both_side_joints_struct = struct();
if configs.discont_configs.do_discont_fix || second_pass
    % Analyze each joint separately to determine if it moves too much from one
    % frame to the next
    for f = 1:length(fields)
        field = fields{f};
        cur_joint = interpolated_skel.(field);
        sliding_window = [];
        
        detail_string = "";
        discont_frame_count = 0;
        
        if f > 1 && mod(f,2) == 0
            cur_joint_has_flips = 0;
            cur_joint_flip_locs = [];
            cur_joint_name = field(2:end);
        end
        
        % Analyze the joint temporally
        for t = 1:length(cur_joint)
            joint_at_t = cur_joint(t, :);
            if t <= num_frames_to_average
                sliding_window = [sliding_window; joint_at_t];
                last_good_joint = mean(sliding_window, 1);
                continue;
            end
            
            % Is the current joint at the current timestep significantly
            % farther than the average for the positions in the sliding window?
            mean_in_window = mean(sliding_window, 1);
            diff_to_cur_joint = vecnorm(mean_in_window(joints_to_average) - joint_at_t(joints_to_average), 2, 2);
            
            if (diff_to_cur_joint <= joint_diff_thres * min_y_diff(t)) && ~sum(isnan(mean_in_window(joints_to_average)))
                last_good_joint = mean_in_window;
                
            elseif sum(isnan(mean_in_window(joints_to_average))) % The last n frames we have seen were "bad"
                diff_to_cur_joint = vecnorm(last_good_joint(joints_to_average) - joint_at_t(joints_to_average), 2, 2);
                
            end
            
            if (diff_to_cur_joint > joint_diff_thres * min_y_diff(t))
                interpolated_skel.(field)(t, :) = NaN;
                discont_frame_count = discont_frame_count + 1;
                any_discont = 1;
                detail_string = strcat(detail_string, ", ", string(t));
                
                if f > 1
                    cur_joint_has_flips = 1;
                    cur_joint_flip_locs = [cur_joint_flip_locs; t];
                end
                
                % First 5 joints are in the head, next 6 are the upper body,
                % and the remainder are the lower body. NOTE: this assumes a 2D
                % detector
                if f <= 5
                    head_discont = 1;
                elseif f <= 11
                    upper_body_discont = 1;
                    body_discont = 1;
                else
                    lower_body_discont = 1;
                    body_discont = 1;
                end
                
            end
            
            % Move the sliding window along
            sliding_window = [sliding_window(2:end, :); interpolated_skel.(field)(t, :)];
        end
        
        if f > 1
            both_side_joints_struct.(strcat(cur_joint_name, "_has_discont")) = cur_joint_has_flips;
            both_side_joints_struct.(strcat(cur_joint_name, "_discont_percentage")) = length(cur_joint_flip_locs) / length(cur_joint);
            allOneString = sprintf('%.0f,' , unique(cur_joint_flip_locs));
            allOneString = allOneString(1:end-1); % strip final comma
            both_side_joints_struct.(strcat(cur_joint_name, "_discont_locs")) = allOneString;
        end
        % Add data for this joint to the table
        output_table = [output_table table(discont_frame_count, ...
            discont_frame_count/length(cur_joint), length(cur_joint), {detail_string} ...
            , 'VariableNames', ...
            {strcat(field, table_suffixes{1}), strcat(field, table_suffixes{2}), ...
            strcat(field, table_suffixes{3}), strcat(field, table_suffixes{4})})];
        
        
        
    end
end
both_side_joints_table = struct2table(both_side_joints_struct, "AsArray", true);

output_table = [table(string(walk_id), string(detector), 'VariableNames', {'walk_id', 'detector'}) both_side_joints_table output_table table(any_discont, lower_body_discont, upper_body_discont, head_discont, body_discont,'VariableNames', {'discont_anywhere', 'lower_body_discont', 'upper_body_discont', 'head_discont', 'body_discont'})];

% Set up variables to export from function:
discont_fixed_skel = interpolated_skel; % Not smoothed
interpolated_and_smoothed_skel = interpolateAndFilterSkelData(interpolated_skel, detector, configs.filter_cutoff_hz, configs.is_kinect, fps, conf_thres, 1); % interpolated
end

