function [skel, failed_detections_log, is_valid_skel, skel_id] = labelPatientInImage(im_labelling_struct, aux_data)
is_valid_skel = 1;
skel_id = nan;
valid_skel = 0;
skel_id_row_in_epart = 10;

% Expand out local variabless
patient_id = im_labelling_struct.patient_id;
walk_id = im_labelling_struct.walk_id;
raw_skel_matching_data = im_labelling_struct.raw_skel_matching_data;
walk_base = im_labelling_struct.walk_base;
search_Eparticipant_files = im_labelling_struct.search_Eparticipant_files;
failed_detections_log = im_labelling_struct.failed_detections_log;

if ~(iscell(raw_skel_matching_data))
    [skel_id, valid_skel] = getSkeletonID(walk_id, raw_skel_matching_data, walk_base, search_Eparticipant_files);
end


if (search_Eparticipant_files)
    % After everything is reprocessed, this should be used
    Epart_file = aux_data.epart_file;
    try
        data = csvread(Epart_file);
        if (length(data) >= skel_id_row_in_epart)
            skel_id = data(skel_id_row_in_epart);
            valid_skel = 1;
            if(skel_id < 0)
                valid_skel = 0;
            end
            
        end
    catch % Either could not read file or too long
    end
end





skel = NaN;
im_path=char(aux_data.preview_image_path);


try
    v = VideoReader(aux_data.vid_file);
    have_vid = 1;
catch
    have_vid = 0;
end


if(isnan(skel_id) || ~valid_skel)
    
    if (~aux_data.skip_videos_without_labelled_skeleton)
        %plotting on image

        try            
            if have_vid
                % Check if MATLAB has access to the codec needed to read this video (this
                % is more of an issue on Linux). If we don't have the codec, we'll to use
                % FFMPEG to extract the images and metadata
                video_frame = read(v, aux_data.start_frame + 100);
                if isempty(video_frame)
                    
                    % Retry using FFMPEG
                    video_frame = extractImageWithFFMPEG(aux_data.vid_file,aux_data.start_frame, im_labelling_struct.path_to_ffmpeg, im_labelling_struct.temp_im_folder);
                end
                
            else
                try
                    video_frame = extractImageWithFFMPEG(aux_data.vid_file,aux_data.start_frame, im_labelling_struct.path_to_ffmpeg, im_labelling_struct.temp_im_folder);
                    
                catch
                    video_frame = imread(im_path);
                    
                end
            end
        catch
            err_message = 'Missing skel label, and cannot find image file for manual labelling';
            err_code = 1;
            err_file = {walk_base};
            
            [failed_detections_log] = logError(failed_detections_log, err_message, err_code, err_file, patient_id, walk_id);
            
            fprintf('Cannot find %s, SKIPPING\n', im_path);
            
            is_valid_skel = 0;
            return;
            
        end
        
        close all
        fig = figure('Position', [0, 0, 1440, 1440]);
        imshow(video_frame);
        hold on
        
        colour_list = ['b', 'g', 'r', 'c', 'y', 'm', 'k', 'w', 'w', 'w'];
        markersize = 2*length(colour_list)-5:-2:2;
        for i = 1:length(aux_data.skels)
            colour = colour_list(i);
            % ROMP configs
            if sum(contains('op2d', fieldnames(aux_data.skels(i))))
                
                x_scale = size(video_frame, 2) / 2;
                y_scale = size(video_frame, 1) / 2;
                plot((aux_data.skels(i).op2d.LAnkle(:, 1) + 1) * x_scale,(aux_data.skels(i).op2d.LAnkle(:, 2) + 1) * y_scale,'o', 'MarkerSize', markersize(i), 'MarkerFaceColor', colour, 'MarkerEdgeColor', colour);
                plot((aux_data.skels(i).op2d.RAnkle(:, 1) + 1) * x_scale,(aux_data.skels(i).op2d.RAnkle(:, 2) + 1) * y_scale,'o', 'MarkerSize', markersize(i), 'MarkerFaceColor', colour, 'MarkerEdgeColor', colour);
            else
                plot(aux_data.skels(i).LAnkle(:, 1),aux_data.skels(i).LAnkle(:, 2),'o', 'MarkerFaceColor', colour, 'MarkerEdgeColor', colour);
                plot(aux_data.skels(i).RAnkle(:, 1),aux_data.skels(i).RAnkle(:, 2),'o', 'MarkerFaceColor', colour, 'MarkerEdgeColor', colour);
            end
        end
        
        %prompt to choose which skel is patient
        prompt = 'Which skeleton is the participant? \nBlue - 1, Green - 2, Red - 3, Cyan - 4, Yellow - 5, Magenta - 6, Black - 7\nEnter 0 if participant is not tracked\nEnter input: ';
        skel_id = input(prompt);
                
        % Save the label we input to eparticipant file
        cur_feature_row = NaN*zeros(1, im_labelling_struct.num_gait_features);
        cur_feature_row(skel_id_row_in_epart) = skel_id;
        
        csvwrite(aux_data.epart_file, cur_feature_row);
    else
        % Skip becasue it doesnt have a label... log as error event
        err_message = 'Do not have skel label for participant ';
        err_code = 1;
        err_file = {im_path};
        
        [failed_detections_log] = logError(failed_detections_log, err_message, err_code, err_file, patient_id, walk_id);
        
        is_valid_skel = 0;
        return;
        
    end
end


% We loaded a skel ID, but its above 0
if (skel_id < 1)
    
    err_message = 'Subject not tracked';
    err_code = 1;
    err_file = {im_path};
    
    [failed_detections_log] = logError(failed_detections_log, err_message, err_code, err_file, patient_id, walk_id);
    
    
    is_valid_skel = 0;
    skel = 0;
    return;
    
end


% We have a valid skel id
skel = aux_data.skels(skel_id);

end
