function [flips_in_walk, detail_string, flipped_skel, output_table] = flipAnalysisAuto(skel, configs, walk_name, detector)
flips_in_walk = 0;

skip = configs.discont_configs.skip;
correct_vs_not_ratio = configs.discont_configs.correct_vs_not_ratio;
num_frames_to_smooth = configs.discont_configs.num_frames_to_smooth;
max_freq_x_dir_init = configs.discont_configs.max_freq_x_dir_init;
start_in_middle = configs.discont_configs.start_in_middle;

if start_in_middle
    [flips_in_walk, detail_string, flipped_skel, output_table] =  flipAnalysisAutoMiddle(skel, configs, walk_name, detector);
    return;
end
[~, fields_struct] = getSkelFields(configs.is_kinect, detector);


left_joints = fields_struct.left_joints;
right_joints = fields_struct.right_joints;
joints_all = fields_struct.joints_all;
is_lower_body = fields_struct.is_lower_body;

table_suffixes = {'_flipped_frames', '_flipped_percentage', '_total_frames', '_flip_locations'};

output_table = table(string(walk_name), 'VariableNames', {'walk_id'});
flip_anywhere = 0;
flipped_skel = skel;
ll_flip_t = [];
lower_body_flip = 0;
upper_body_flip = 0;


for j = 1:length(left_joints)
    left_joint = left_joints{j};
    right_joint = right_joints{j};
    
    left_joint_data = skel.(left_joint);
    right_joint_data = skel.(right_joint);
    
    left_joint_data_flipped = [];
    right_joint_data_flipped = [];
    
    flipped_frame_count = 0;
    detail_string = "";

    if max_freq_x_dir_init
        left_less = left_joint_data(:, 1) < right_joint_data(:, 1);
        percent_left_less = sum(left_less) / length(left_less);
    end
    
    for t = 1:length(left_joint_data)
        if t <= skip + 1 
            if max_freq_x_dir_init && percent_left_less > 0.5 % left is the smaller x value
                if left_joint_data(t, 1) < right_joint_data(t, 1)
                    left_joint_data_flipped = [left_joint_data_flipped; left_joint_data(t, :)];
                    right_joint_data_flipped = [right_joint_data_flipped; right_joint_data(t, :)];
                else
                    left_joint_data_flipped = [left_joint_data_flipped; right_joint_data(t, :)];
                    right_joint_data_flipped = [right_joint_data_flipped; left_joint_data(t, :)];
                end
                
            elseif max_freq_x_dir_init % left is the larger x value
                if left_joint_data(t, 1) < right_joint_data(t, 1)
                    left_joint_data_flipped = [left_joint_data_flipped; right_joint_data(t, :)];
                    right_joint_data_flipped = [right_joint_data_flipped; left_joint_data(t, :)];
                else
                    left_joint_data_flipped = [left_joint_data_flipped; left_joint_data(t, :)];
                    right_joint_data_flipped = [right_joint_data_flipped; right_joint_data(t, :)];
                end
                
            else
                left_joint_data_flipped = [left_joint_data_flipped; left_joint_data(t, :)];
                right_joint_data_flipped = [right_joint_data_flipped; right_joint_data(t, :)];
            end
            continue;
        end
        
        smooth_frame_count = min(t - 2, num_frames_to_smooth);
        % Compare the distance to the right and left joint for each joint
        ll_dist = vecnorm(mean(left_joint_data_flipped(end - smooth_frame_count :end, :), 'omitnan') - left_joint_data(t,:),2,2);
        lr_dist = vecnorm(mean(left_joint_data_flipped(end - smooth_frame_count :end, :), 'omitnan') - right_joint_data(t,:),2,2);
        rr_dist = vecnorm(mean(right_joint_data_flipped(end - smooth_frame_count :end, :), 'omitnan') - right_joint_data(t,:),2,2);
        rl_dist = vecnorm(mean(right_joint_data_flipped(end - smooth_frame_count :end, :), 'omitnan') - left_joint_data(t,:),2,2);
        
        correct_label_dist = ll_dist + rr_dist;
        incorrect_label_dist = rl_dist + lr_dist;
        
        diff_ratio = abs(correct_label_dist - incorrect_label_dist) / (correct_label_dist + incorrect_label_dist);
        
        % One is correct, the other is not. Keep the correct one, drop the
        % wrong one
        if (diff_ratio <  correct_vs_not_ratio )
            
            % Keeping left
            if (ll_dist < rr_dist)
                left_joint_data_flipped = [left_joint_data_flipped;left_joint_data(t,:)];
                right_joint_data_flipped = [right_joint_data_flipped;NaN*right_joint_data(t,:)];

            % Keeping right
            else
                left_joint_data_flipped = [left_joint_data_flipped;NaN*left_joint_data(t,:)];
                right_joint_data_flipped = [right_joint_data_flipped;right_joint_data(t,:)];
            end
            
            
        
        % Correct label
        elseif isnan(correct_label_dist) || isnan(incorrect_label_dist) || ...
            (correct_label_dist <= incorrect_label_dist)
            left_joint_data_flipped = [left_joint_data_flipped;left_joint_data(t,:)];
            right_joint_data_flipped = [right_joint_data_flipped;right_joint_data(t,:)];
            
        else % flip this joint
            left_joint_data_flipped = [left_joint_data_flipped;right_joint_data(t,:)];
            right_joint_data_flipped = [right_joint_data_flipped;left_joint_data(t,:)];
            flipped_frame_count = flipped_frame_count + 1;
            flips_in_walk = 1;
            flip_anywhere = 1;
            detail_string = strcat(detail_string, ", ", string(t));
            
            if is_lower_body(j)
                lower_body_flip =1;
            else
                upper_body_flip =1;
            end
            
        end
        
%         output_table = 

        flipped_skel.(left_joint) = left_joint_data_flipped;
        flipped_skel.(right_joint) = right_joint_data_flipped;
        
    end  % for t
    output_table = [output_table table(flipped_frame_count, ...
    flipped_frame_count/length(left_joint_data), length(left_joint_data), {detail_string} ...
    , 'VariableNames', ...
{strcat(joints_all{j}, table_suffixes{1}), strcat(joints_all{j}, table_suffixes{2}), ...
strcat(joints_all{j}, table_suffixes{3}), strcat(joints_all{j}, table_suffixes{4})})];


end %for j
output_table = [output_table table(flip_anywhere, lower_body_flip, upper_body_flip, 'VariableNames', {'flip_anywhere', 'lower_body_flip', 'upper_body_flip'})];


end % end func

