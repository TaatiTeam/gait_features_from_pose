function [ skel_dist ] = ComputeSkelDist(mean_skel, cur_skel, frame, conf_thres, closeness_based_on_lower_body, is_3d, norm_by_hip)
if nargin < 4
    conf_thres = 0.4;
    is_3d = 0;
    norm_by_hip = 0;
end
skel_dist = 0;
fn = fieldnames(cur_skel);
if closeness_based_on_lower_body
    fn = {'RHip';'RKnee';'RAnkle';'LHip';'LKnee';'LAnkle'};
end

num_joints_included = 0;

hip_norm_factor = 1;
if norm_by_hip
    dims = 1:2;
    if is_3d
        dims = 1:3;
    end
    hip_norm_factor = norm(cur_skel.RHip(frame, dims) - cur_skel.LHip(frame, dims));
    
end


if ~is_3d
    for i=1:length(fn)
        cur_joint = fn{i};
        cur_skel_joint_data = cur_skel.(cur_joint)(frame, 1:2);
        cur_joint_conf = cur_skel.(cur_joint)(frame, 3);
        mean_skel_joint_conf = mean_skel.(cur_joint)(3);
        if (abs(cur_joint_conf) < conf_thres) || (abs(mean_skel_joint_conf) < conf_thres)
            continue;
        end
        
        % Only sum the joint if it is not zero
        if sum(cur_skel_joint_data) == 0
            continue;
        end
        if sum(mean_skel.(cur_joint)) == 0
            continue;
        end
        num_joints_included = num_joints_included + 1;
        skel_dist = skel_dist + norm(mean_skel.(cur_joint)(1:2) - cur_skel_joint_data);
        i;
    end
    
    
else
    for i=1:length(fn)
        cur_joint = fn{i};
        cur_skel_joint_data = cur_skel.(cur_joint)(frame, :);
        cur_joint_conf = 100;
        mean_skel_joint_conf = 100;
        if (cur_joint_conf < conf_thres) || (mean_skel_joint_conf < conf_thres)
            continue;
        end
        
        % Only sum the joint if it is not zero
        if sum(cur_skel_joint_data) == 0
            continue;
        end
        if sum(mean_skel.(cur_joint)) == 0
            continue;
        end
        num_joints_included = num_joints_included + 1;
        skel_dist = skel_dist + norm(mean_skel.(cur_joint) - cur_skel_joint_data);
        i;
    end
    
end

% Rescale the contribution of the joints
skel_dist = skel_dist * length(fn) / num_joints_included / hip_norm_factor;

end

