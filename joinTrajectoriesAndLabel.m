function [configs] = joinTrajectoriesAndLabel(configs)
if (~configs.do_labelling)
    return
end


% alias
lc = configs.labelling_configs;
% Find all of the walks in the root folder
all_walks = lc.GetWalksList();
if isempty(lc.split_csv)
    split_table = 0;
else
    split_table = LoadSplitDataTable(lc.split_csv, configs.split_depth);
end

for detector = 1:length(configs.detectors)
    
    det_name = configs.detectors{detector};
    
    
    
    % Reset saved data for this detector===================================
    invalid_walks = {};
    bad_walk_count = 1; % This is index for logging so must be positive
    num_gait_features = 12;
    
    
    % Initialize all gait features to be NaN. If the analysis is successful,
    % this will be filled in with valid numbers
    SAS_scores = NaN*zeros(length(all_walks), 1);
    UPDRS_scores = NaN*zeros(length(all_walks), 1);
    
    ages = NaN*zeros(length(all_walks), 1);
    sexes = NaN*zeros(length(all_walks), 1);
    
    % Done resetting saved data for this detector==========================
    
    
    for row = 1:length(all_walks)
        walk_base = fullfile(lc.input_folder, all_walks{row});
        SAS_score = SAS_scores(row);
        UPDRS_score = UPDRS_scores(row);
        age = ages(row);
        sex = sexes(row);
        
        [pred_path,epart_path] = getEpartAndPredFileFromDetector(det_name, walk_base);
        
        % We already labelled this file and don't want to relabel
        if lc.skip_if_epart_file_exists
            if exist(epart_path, 'file') == 2 % if isfile(pred_file)
                continue;
            end
        end
        
        [walk_id, patient_id, is_backward] = configs.getWalkAndPatientID(walk_base);
        
        
        failed_detections_log = configs.error_log;
        % See if we can get the info for this video
        [video_path, fps, num_frames, timestamps] = configs.getFPSAndNumFrames(walk_base);
        
        
        % Check if we have a valid pred_file
        is_valid = 0;
        if exist(pred_path, 'file') == 2 && exist(video_path, 'file') == 2% if isfile(pred_file)
            is_valid = 1;
        end
        
        
        
        % Log if we cannot process this walk
        if(~is_valid)
            
            err_file = {walk_base};
            
            state = str2double(walk_base(end));
            if (state > 1)
                err_message = 'Walk bout folder not found - colour\n';
                err_code = 0;
            else
                err_message = 'Walk bout folder not found - bw\n';
                err_code = -1;
            end
            
            fprintf(err_message);
            
            [failed_detections_log] = logError(failed_detections_log, err_message, err_code, err_file, patient_id, walk_id);
            
            invalid_walks{bad_walk_count} = walk_base;
            bad_walk_count = bad_walk_count + 1;
            continue;
        end
        
        
        if ~istable(split_table)
            num_sections = 0;
            
            
        else
            walk_row_inds = find(strcmp(split_table.video_name, walk_id) ==1 & strcmp(split_table.patient, patient_id)==1);
            num_sections = numel(walk_row_inds);
        end
        % Put all of the necessary data into a struct to reduce the number
        % of input parameters to our labelling function

        walk_data = struct;
        walk_data.walk_base = walk_base;
        walk_data.video_path = video_path;
        walk_data.fps = fps;
        walk_data.pred_path = pred_path;
        walk_data.epart_path = epart_path;
        walk_data.walk_id = walk_id;
        walk_data.patient_id = patient_id;
        walk_data.is_backward = is_backward;
        walk_data.num_frames = num_frames;
        walk_data.detector = det_name;
        walk_data.num_gait_features = num_gait_features;
        walk_data.timestamps = timestamps;
        
        
        walk_data.clinical_scores.SAS_gait = SAS_score;
        walk_data.clinical_scores.UPDRS_gait = UPDRS_score;
        walk_data.demographic_data.age = age;
        walk_data.demographic_data.sex = sex;
        configs.error_log = failed_detections_log;
        
        % These will be overwritten if we have multiple sections
        walk_data.start_frame = 1;
        walk_data.stop_frame = length(timestamps); 
        walk_data.subwalk = '';
        
        if num_sections == 0 && ~istable(split_table)
            fprintf('Now processing: %s, %d/%d\n', walk_base, row, length(all_walks));

            [~, ~, ~, ~, configs] = extractFramesToArrayUsingConfig(configs, walk_data);
            continue;
        end
        
        % If we have multiple sections, process one by one
        for s = 1:num_sections

            start_time = split_table.start_time(walk_row_inds(s));
            stop_time = split_table.end_time(walk_row_inds(s));
            
            start_time = minutes(start_time); % This is actually the time in seconds
            stop_time = minutes(stop_time); % This is actually the time in seconds
            start_frame = min(find(timestamps >= start_time));
            stop_frame = max(find(timestamps <= stop_time));
                    
            direction = split_table.suffix(walk_row_inds(s));
            dir_parts = strsplit(direction, '_');
            if strcmp(dir_parts{1}, "backward")
                is_backward = 1;
            else
                is_backward = 0;
            end
            walk_data.is_backward = is_backward;
            walk_data.patient = split_table.patient(walk_row_inds(s));
            walk_data.start_frame = start_frame;
            walk_data.stop_frame = min(stop_frame, length(timestamps));
            walk_data.subwalk = split_table.suffix(walk_row_inds(s));
            fprintf('Now processing: %s, %d/%d\n', strcat(walk_base, '-', walk_data.subwalk), row, length(all_walks));

            [~, ~, ~, ~, configs] = extractFramesToArrayUsingConfig(configs, walk_data);

        end
 
    end
end
end