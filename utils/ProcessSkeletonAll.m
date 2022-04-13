function [skel_struct] = ProcessSkeletonAll(skel_string, skel, frame, detector)
% Get matlab version
[v d] = version;
if (str2num(v(1)) < 9) % old verison
    split_str = strsplit( skel_string{1} , ',' );
else % new version
    split_str = split( skel_string , ',' );
end

split_str = str2double(split_str);

order_of_keypoints = getKeypointOrderInCSV(detector);


% if sum(isnan(split_str)) && ~isstruct(skel)% No data, append 0's
if isnan(split_str) & ~isstruct(skel)% No data, append 0's
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        data = zeros(frame, 3);
        skel_struct.(cur_part_name) = data;
    end
    return
end

if isnan(split_str) % No data, append 0's
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        data = zeros(1, 3);
        try
        prev_data = skel.(cur_part_name);
        catch
            a = 1;
        end
        data = [prev_data; data];
        skel_struct.(cur_part_name) = data;
    end
    return
end


% If we didnt get a skeleton to append to, create an empty one to add
% to
if (~isstruct(skel))
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        data = zeros(frame-1, 3);
        data = [data; split_str((i-1)*3 + 1), split_str((i-1)*3 + 2), split_str((i-1)*3 + 3)];
        skel_struct.(cur_part_name) = data;
    end
    
else % This skeleton already exists so append to it
    for i = 1:length(order_of_keypoints)
        cur_part_name = order_of_keypoints{i};
        prev_data = skel.(cur_part_name);
        [l w] = size(prev_data);
        if (l + 1 ~= frame)
            % Add spacers in the middle if we didn't see this skeleton in the
            % last frame
            to_add_frames = frame - l - 1;
            add_data = zeros(to_add_frames, 3);
            prev_data = [prev_data; add_data];
        end
        
        data = [prev_data; split_str((i-1)*3 + 1), split_str((i-1)*3 + 2), split_str((i-1)*3 + 3)];
        skel_struct.(cur_part_name) = data;
    end
end


end
