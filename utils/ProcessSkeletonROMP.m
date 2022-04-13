function [skel_struct] = ProcessSkeletonROMP(cur_person_data, skel, frame, detector)

order_of_keypoints = getKeypointOrderInCSV(detector);

op_to_54_mapping = [{'Nose', 25}; {'Neck', 13}; ...
        {'RShoulder', 18}; {'RElbow', 20}; {'RWrist', 22}; ...
        {'LShoulder', 17}; {'LElbow', 19}; {'LWrist', 21}; ...
        {'MidHip', 50}; {'RHip', 46}; {'RKnee', 6}; {'RAnkle', 9}; ...
        {'LHip', 47}; {'LKnee', 5}; {'LAnkle', 8}; ...
        {'REye', 26}; {'LEye', 27}; {'REar', 28}; {'LEar', 29}; ...
        {'LToe', 30}; {'LFootBall', 31}; {'LHeel', 32}; {'RToe', 33}; ...
        {'RFootBall', 34}; {'RHeel', 35}];

% If we didnt get a skeleton to append to, create an empty one to add
% to
placeholder_conf = 100;
if (~isstruct(skel))
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        
        data_cur_frame = cur_person_data.j3d_op25(i, :);
        data = zeros(frame-1, 3);
        data = [data; data_cur_frame];
        skel_struct.(cur_part_name) = data;
        
        data_2d = zeros(frame-1, 3);
        j = op_to_54_mapping{i, 2};
        data_2d = [data_2d;cur_person_data.pj2d(j, :), placeholder_conf];

        skel_struct.op2d.(cur_part_name) = data_2d;
        
    end
    
else % This skeleton already exists so append to it
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        prev_data = skel.(cur_part_name);
        prev_data_2d = skel.op2d.(cur_part_name);
        [l w] = size(prev_data);
        if (l + 1 ~= frame)
            % Add spacers in the middle if we didn't see this skeleton in the
            % last frame
            to_add_frames = frame - l - 1;
            add_data = zeros(to_add_frames, 3);
            prev_data = [prev_data; add_data];
            prev_data_2d = [prev_data_2d; add_data];
        end
        data_cur_frame = cur_person_data.j3d_op25(i, :);

        data = [prev_data; data_cur_frame];
        skel_struct.(cur_part_name) = data;
        

        j = op_to_54_mapping{i, 2};
        data_2d = [prev_data_2d;cur_person_data.pj2d(j, :), placeholder_conf];
        skel_struct.op2d.(cur_part_name) = data_2d;

        
    end
end


end
