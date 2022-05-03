function [smoothed_patient_data, is_valid_skel, skel_id, first_frame, configs] = extractFramesToArrayUsingConfig(configs, walk_data)
aux_data= struct();
configs.labelling_configs = configs.labelling_configs.RefreshJoiningConstants(walk_data.detector, configs.is_3d);

% Extract data to local variables
[vid_width, vid_height] = configs.getVideoRes(walk_data.video_path);

fps = walk_data.fps;
subsequent_frame_skel_closeness_thres = configs.labelling_configs.subsequent_frame_skel_closeness_thres;
conf_thres = configs.labelling_configs.conf_thres;
smoothing_window_size = configs.labelling_configs.smoothing_window_size;
closeness_based_on_lower_body = configs.labelling_configs.closeness_based_on_lower_body;
search_Eparticipant_files = configs.labelling_configs.search_Eparticipant_files;
epart_file = walk_data.epart_path;

patient_id = walk_data.patient_id;
walk_id = walk_data.walk_id;
walk_base = walk_data.walk_base;

pred_file = walk_data.pred_path;
detector = walk_data.detector;

% Legacy options
fixOP = 0;

% Read the csv into a table. The readtable() function was observed to skip
% rows in the Dravet dataset so data will be manually read
if strcmp(detector, 'romp')
    skels = extractFromROMP(pred_file, walk_data, detector);
else
    [~, skels, walk_data] =  extractFrom2Ddetectors(pred_file, walk_data, detector);
end

% Assume that the participant is present in the first frame of the video
sorted_skels_count = 0;
for skel = 1:length(skels)
    
    % Check if there is any data at the first time stamp
    sum_all_joints = 0;
    count_seen_lower_body_joints = 0;
  
    fields = getKeypointOrderInCSV(detector);
    % We need to see a lower body point
    fn = {'RHip';'RKnee';'RAnkle';'LHip';'LKnee';'LAnkle'};
    
    for f = 1:length(fields)
        field = fields{f};
%         sum_all_joints = sum_all_joints + sum(skels(skel).(field)(1, 1:2));
        
        if sum(contains(fn, field)) && sum(skels(skel).(field)(1, 1:2)) > 0
            count_seen_lower_body_joints = count_seen_lower_body_joints + 1;
        end
    end
    
    
    if (count_seen_lower_body_joints > 2)
        sorted_skels_count = sorted_skels_count + 1;
        
        fn = fieldnames(skels(skel));
        
        for joint = 1:length(fn)
            cur_joint = fn{joint};
            
            if strcmp(cur_joint, 'op2d')
                subfields = fieldnames(skels(skel).(cur_joint));
                for s = 1:length(subfields)
                    cur_subjoint = subfields{s};
                    sorted_skels(skel).(cur_joint).(cur_subjoint) = skels(skel).(cur_joint).(cur_subjoint)(1, :);
                end
            else
                sorted_skels(skel).(cur_joint) = skels(skel).(cur_joint)(1, :);
            end
        end
    end
end

% There are no skeletons in the first frame, lets check if they started at
% a later frame
if sorted_skels_count == 0
    found_first_frame = 0;
    first_frame = -1;
else
    found_first_frame = 1;
    first_frame = walk_data.start_frame;
end


start_frame = 1;
if sorted_skels_count < length(skels)
    for t = 1:length(skels(1).Nose)
        if found_first_frame % check if there are any other skeletons that start within the sliding window
            if sorted_skels_count >= length(skels)
                break; % Found all of the skeletons
            end
            for t2 = start_frame:(start_frame+smoothing_window_size)
                for skel = (sorted_skels_count+1):length(skels)
                    % Check if there is any data at the first time stamp
                    sum_all_joints = 0;
                    count_seen_lower_body_joints = 0;
                    
                    fields = fieldnames(skels(skel));
                      
                    for f = 1:length(fields)
                        field = fields{f};
                        try
                            sum_all_joints = sum_all_joints + sum(skels(skel).(field)(t2, 1:2));
                            if sum(contains(fn, field)) && sum(skels(skel).(field)(t2, 1:2)) > 0
                                count_seen_lower_body_joints = count_seen_lower_body_joints + 1;
                            end
                        catch % Not enough timesteps here
                        end
                        
                    end
                    
                    if count_seen_lower_body_joints > 2 % Add the skeleton
                        
                        for joint = 1:length(fields)
                            cur_joint = fields{joint};
                            
                            if strcmp(cur_joint, 'op2d')
                                subfields = fieldnames(skels(skel).(cur_joint));
                                for s = 1:length(subfields)
                                    cur_subjoint = subfields{s};

                                    sorted_skels(skel).(cur_joint).(cur_subjoint) = ones(t2-start_frame+1, 3).*skels(skel).(cur_joint).(cur_subjoint)(t2, :);
                                end
                            else
                                sorted_skels(skel).(cur_joint) = ones(t2-start_frame+1, 3).*skels(skel).(cur_joint)(t2, :);
                            end
                        end
                        start_frame = t;
                        first_frame = t;
                        sorted_skels_count = sorted_skels_count+1;
                    end
                end
            end
            break;
            
        else % we need to find the first skeleton first
            for skel = 1:length(skels)
                % Check if there is any data at the first time stamp
                sum_all_joints = 0;
                count_seen_lower_body_joints = 0;
                fields = fieldnames(skels(skel));
                  
                keypoints_fields = getKeypointOrderInCSV(detector);
                for f = 1:length(fields)
                    field = fields{f};
                    
                    if sum(contains(fn, field)) && sum(contains(field, keypoints_fields))
                        if sum(skels(skel).(field)(t, 1:2))
                            count_seen_lower_body_joints = count_seen_lower_body_joints + 1;
                        end
                    end
                    
                end
                
                if count_seen_lower_body_joints > 2 % Add the skeleton
                    found_first_frame = 1;
                    first_frame = t;
                    
                    for joint = 1:length(fields)
                        cur_joint = fields{joint};

                        if strcmp(cur_joint, 'op2d')
                            subfields = fieldnames(skels(skel).(cur_joint));
                            for s = 1:length(subfields)
                                cur_subjoint = subfields{s};
                                sorted_skels(skel).(cur_joint).(cur_subjoint) = skels(skel).(cur_joint).(cur_subjoint)(t, :);
                            end
                        else
                            sorted_skels(skel).(cur_joint) = skels(skel).(cur_joint)(t, :);
                        end
                        
                    end
                    start_frame = t;
                    sorted_skels_count = sorted_skels_count+1;
                end
            end
        end
    end
end


try
    len_ss = length(sorted_skels);
    % Remove the bad skels
    for sSkel_id = len_ss:-1:1
        if isempty(sorted_skels(sSkel_id).Nose)
            sorted_skels(sSkel_id) = [];
        end
    end
catch
    if deleteEmptyOP && detector == 1
        detector;
        fprintf("Found empty prediction file - DELETING: %s\n", pred_file);
        delete(pred_file)
        
        is_valid_skel = 0;
        skel_id = 0;
        smoothed_patient_data = 0;
        return;
    end
end


% Iterate through each frame and assign the detections to a skel
last_frame_count = zeros(1, length(sorted_skels));

for frame = (start_frame+1):(walk_data.stop_frame - walk_data.start_frame)
    frames_seen = frame - start_frame + 1;
    
    for sorted_skel_ind = 1:length(sorted_skels)
        
        cur_skel = sorted_skels(sorted_skel_ind);
        
        % Compute the mean skel
        if frames_seen <= smoothing_window_size+1
            mean_skel = ComputeMeanSkel(cur_skel, 1:frames_seen-1);
        else
            mean_skel = ComputeMeanSkel(cur_skel, frames_seen-1-smoothing_window_size:frames_seen-1);
        end
        
        % Compute distance to each potential skel from mean_skel
        for potential_skel_ind = 1:length(skels)
            cur_potential_skel = skels(potential_skel_ind);
            
            if size(cur_potential_skel.Nose, 1) < frame
                distance(potential_skel_ind) = Inf;
                distance_avg(potential_skel_ind) = Inf;
                continue; % No data in this skeleton at this frame
            end
            
            [skel_dist_sum, skel_dist_per_joint] = ComputeSkelDist(mean_skel, cur_potential_skel,...
                frame, conf_thres/100/2, closeness_based_on_lower_body,...
                configs.labelling_configs.label_using_3d, configs.labelling_configs.norm_by_hip);
            
            distance(potential_skel_ind) = skel_dist_sum;
            distance_avg(potential_skel_ind) = skel_dist_per_joint;
        end
        
        % Assign this skel to the sorted skeleton that is closest, assuming
        % it is within the threshold
        [val_min, ind_min] = min(distance_avg);
        
        
        if (val_min < subsequent_frame_skel_closeness_thres)
            last_frame_count(sorted_skel_ind) = frames_seen;
            sorted_skels(sorted_skel_ind) = AddToSkel(sorted_skels(sorted_skel_ind), skels(ind_min), frame);
        else % Not close enough; add Nan at this time step
            val_min;
            
            sorted_skels(sorted_skel_ind) = AddToSkel(sorted_skels(sorted_skel_ind), nan, frame);
        end
        
    end % End sorted skel process
end % end frame process

% Now remove the extra NaNs at the end of the sorted skel structs - these
% cause issues when we try to interpolate any missing data
for sorted_skel_ind = 1:length(sorted_skels)
    fields = fieldnames(sorted_skels(sorted_skel_ind));
    
    for f = 1:length(fields)
        cur_joint = fields{f};
        all_data = sorted_skels(sorted_skel_ind).(cur_joint);
        
        if strcmp(cur_joint, 'op2d')
            subfields = fieldnames(all_data);
            for s = 1:length(subfields)
                cur_subjoint = subfields{s};
                sorted_skels(sorted_skel_ind).(cur_joint).(cur_subjoint) = all_data.(cur_subjoint)(1:last_frame_count(sorted_skel_ind), :);
            end
        else
            sorted_skels(sorted_skel_ind).(cur_joint) = all_data(1:last_frame_count(sorted_skel_ind), :);
        end
    end
end

% Now visualize the detected skeletons and have the operator select which
% corresponds to the participant.
have_participant_label = 0;
if (search_Eparticipant_files) % If we should look at eparticipant files, check if we already have a detectron label for this walk
    
    if exist(epart_file, 'file') == 2
        have_participant_label = 1;
        is_valid_skel = 1;
        
        try
            data = csvread(epart_file);
            if (length(data) >= 10)
                skel_id = data(10);
                if isnan(skel_id)
                    have_participant_label = 0;
                end
                if(skel_id <= 0)
                    is_valid_skel = 0;
                end
            end
        catch
            have_participant_label = 0; % Something went wrong so can't use this label
        end
        
    end
    
    is_valid_skel = have_participant_label;
    
    try
        patient_skel = sorted_skels(skel_id);
    catch
        is_valid_skel = 0;
    end
end

% If we don't have the participant label, plot the images and prompt for label
if ~have_participant_label
    % Add all skeletons to data struct
    for skel_ids = 1:length(sorted_skels)
        aux_data.skels(skel_ids) = sorted_skels(skel_ids);
    end
    
    % Set up aux_data
    aux_data.skip_videos_without_labelled_skeleton = 0;
    [aux_data.preview_image_path, aux_data.epart_file] = getPreviewImAndEpart(detector, walk_base, walk_data.subwalk);
    aux_data.vid_file = walk_data.video_path;
    aux_data.start_frame = start_frame + walk_data.start_frame - 1;
    
    im_labelling_struct.patient_id = patient_id;
    im_labelling_struct.walk_id = walk_id;
    im_labelling_struct.raw_skel_matching_data = nan;
    im_labelling_struct.walk_base = walk_base;
    im_labelling_struct.search_Eparticipant_files = search_Eparticipant_files;
    im_labelling_struct.failed_detections_log = configs.error_log;
    im_labelling_struct.num_gait_features = walk_data.num_gait_features;
    im_labelling_struct.path_to_ffmpeg = configs.ffpath;
    im_labelling_struct.temp_im_folder = configs.temp_im_folder;
    
    [patient_skel, failed_detections_log, is_valid_skel, skel_id] ...
        = labelPatientInImage(im_labelling_struct, aux_data);
    configs.error_log = failed_detections_log;

elseif is_valid_skel % We loaded in the data from the eparticipant file
    patient_skel = sorted_skels(skel_id);
end


% If we don't have a valid skel, just return
if (~is_valid_skel)
    smoothed_patient_data = 0;
    return;
end

% Fill any nans
patient_skel = interpolateAndFilterSkelData(patient_skel, detector, configs.filter_cutoff_hz, configs.is_kinect,fps, conf_thres, 1); %interpolate only

% Interpolate and smooth over poorly tracked values
smoothed_patient_data = interpolateAndFilterSkelData(patient_skel, detector, configs.filter_cutoff_hz, configs.is_kinect,fps, conf_thres, 0); % now filter

% Now have the skeleton corresponding to the participant, save these for
% use in other programs
try
    [vid_width, vid_height] = configs.getVideoRes(walk_data.video_path);
    walk_data.start_frame = start_frame + walk_data.start_frame - 1;
    walk_data.fixOP = fixOP;
    walk_data.width = vid_width;
    walk_data.height = vid_height;
    
    % Use default constructor for 2D
    export_configs = ExportConfigs(configs.labelling_configs.output_folder, 0, configs.is_3d);
    exportSkelDataToCSV(export_configs, walk_data, patient_skel, smoothed_patient_data);
catch
    fprintf('failed to export to csv\n');
end

end


function [skels] = extractFromROMP(pred_file, walk_data, detector)
    datastruct = load('-mat', pred_file);
    % Parse table into skeletons
    for frame = walk_data.start_frame:walk_data.stop_frame
        frame_string = strcat('frame_', num2str(frame));
        
        cur_frame_data = datastruct.(frame_string);
        
        % Loop through all of the people in this scene
        people_in_frame = fieldnames(cur_frame_data);
        for p = 1:length(people_in_frame)
            cur_person_data = cur_frame_data.(people_in_frame{p});
            
            
            try
                if (length(skels) >= p)  % We already have a skel so just append to it
                    skels(p) = ProcessSkeletonROMP(cur_person_data, skels(p), frame - walk_data.start_frame + 1, detector);
                else % First time seeing this skeleton
                    skels(p) = ProcessSkeletonROMP(cur_person_data, 0, frame - walk_data.start_frame + 1, detector);
                end
            catch
                skels(p) = ProcessSkeletonROMP(cur_person_data, 0, frame - walk_data.start_frame + 1, detector);
            end 
        end
    end
end

function [T, skels, walk_data] = extractFrom2Ddetectors(pred_file, walk_data, detector)
fid=fopen(pred_file);
tline = fgetl(fid);
tlines = cell(0,2);
while ischar(tline)
    [split_data] = strsplit(tline, '_');
    ar1 = split_data(1);
    tlines{end+1,1} = str2num(ar1{1});
    length(split_data);
    tlines{end,2} = split_data(2);
    
    tline = fgetl(fid);
end
fclose(fid);
T = cell2table(tlines);
% Get matlab version
[v d] = version;


if walk_data.stop_frame > height(T)
    walk_data.stop_frame = height(T);
end
% Parse table into skeletons
for frame = walk_data.start_frame:walk_data.stop_frame
    raw_frame_data = T.(2)(frame);
    if (str2num(v(1)) < 9)
        raw_frame_data = raw_frame_data{1};
        raw_split_skels = strsplit( raw_frame_data , ';' );
    elseif (size(T, 2) == 2)
        raw_split_skels = split( raw_frame_data , ';' );
    else
        % When read in, this was already split up, put it back together
        % into a string so that we can process it like we do the other
        % files
        % Separate out the first coordinate
        raw_frame_data = T.(1)(frame);
        raw_frame_data = raw_frame_data{1};
        raw_frame_data = strsplit( raw_frame_data , '_' );
        try
            raw_frame_data = raw_frame_data{2};
        catch
            raw_split_skels = '';
            continue;
        end
        for cord_ind = 2:size(T, 2)
            next_cord = T.(cord_ind)(frame);
            try
                next_cord = num2str(next_cord);
            catch
                try
                    next_cord = num2str(next_cord{1});
                    
                catch
                    split_parts = split( next_cord , ';' );
                    if(length(split_parts) > 1)
                        raw_frame_data = strcat(raw_frame_data, ',',next_cord);
                    end
                    
                    continue;
                end
                
                
            end
            raw_frame_data = strcat(raw_frame_data, ',',next_cord);
        end
        
        % Let's check that the next row in the table isn't a continuation
        % of this one
        try
            raw_frame_data_next = T.(1)(frame+1);
            raw_frame_data_next = raw_frame_data_next{1};
            if (raw_frame_data_next(1) == ';')
                %                 raw_frame_data_next = raw_frame_data_next(2:end);
                raw_frame_data = strcat(raw_frame_data, raw_frame_data_next);
                for cord_ind = 2:size(T, 2)
                    next_cord = T.(cord_ind)(frame+1);
                    try
                        next_cord = num2str(next_cord);
                    catch
                        split_parts = split( next_cord , ';' );
                        if(length(split_parts) > 1)
                            raw_frame_data = strcat(raw_frame_data, ',',next_cord);
                        end
                        
                        continue;
                        
                    end
                    raw_frame_data = strcat(raw_frame_data, ',',next_cord);
                end
            end
        catch
        end
        raw_split_skels = split( raw_frame_data , ';' );
    end
    
    
    for skel_num = 1:length(raw_split_skels)
        try
            if (length(skels) >= skel_num)  % We already have a skel so just append to it
                skels(skel_num) = ProcessSkeletonAll(raw_split_skels(skel_num), skels(skel_num), frame - walk_data.start_frame + 1, detector);
            else % First time seeing this skeleton
                skels(skel_num) = ProcessSkeletonAll(raw_split_skels(skel_num), 0, frame - walk_data.start_frame + 1, detector);
            end
        catch
            skels(skel_num) = ProcessSkeletonAll(raw_split_skels(skel_num), 0, frame - walk_data.start_frame + 1, detector);
        end
    end
    
    if ~exist('skels', 'var')
        skels = [];
    end
end
end



