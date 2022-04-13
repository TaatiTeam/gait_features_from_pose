close all, clear all, clc


path_to_ims = "/home/saboa/data/belmont_from_ndrive/image_for_paper";
path_to_dets = "/home/saboa/data/belmont_from_ndrive/";
path_to_dets = "/home/saboa/data/belmont_raw_processed/";
raw_vids_path = "/home/saboa/data/belmont_raw_vids/";
output_path = fullfile(path_to_ims, 'out_blurred_final');

interpolate_op_frame = 1;
pull_images_using_ffmpeg = 0;

if ~exist(output_path, 'dir')
    mkdir(output_path);
end

ims = dir(path_to_ims);
ims=ims(~ismember({ims.name},{'.','..'}));
fps = 30;

detectors = {'detectron', 'alphapose', 'openpose'};
% detectors = {'openpose'};

for i_num = 1:length(ims)
    if (ims(i_num).isdir)
        continue;
    end
    blurred_image_name = fullfile(ims(i_num).folder, ims(i_num).name);
    blurred_image = imread(blurred_image_name);
    
    video_name_split = strsplit(ims(i_num).name, "_");
    video_name = video_name_split{1};
    frame_count_split = strsplit(video_name_split{2}, ".");
    frame_num = str2num(frame_count_split{1});
    
    time_step = frame_num / fps;
    
    walk_base = fullfile(path_to_dets, video_name);
    video_configs = VideoPlottingConfigs();
    video_file = fullfile(raw_vids_path, strcat(video_name, '.mp4'));
    
    timestamps = videoframets(video_configs.path_to_ffmpeg, char(video_file));
    
    
    if pull_images_using_ffmpeg
        video_frame = extractImageWithFFMPEG(video_file,frame_num, video_configs.path_to_ffmpeg, video_configs.temp_im_folder);
        blurred_image = video_frame;
    end
    for d = 1:length(detectors)
        
        detector = detectors{d};
        [pred_path,epart_path] = getEpartAndPredFileFromDetector(detector, walk_base);
        
        T = readtable(pred_path);
        num_frames = height(T);
        
        % Fix if parsing issue
        if ~(size(T, 2) == 2)
            num_frames = height(T);
            frame_col = 1:num_frames;
            T_new = table('Size',[num_frames 2],'VariableTypes', {'double','string'}, 'VariableNames', {'Var1', 'Var2'});
            T_new.Var1 = frame_col';
            for frame = 1:num_frames
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
                T_new.Var2(frame) = raw_frame_data;
                
                
            end
            T = T_new;
        end
        
        iRow = -1;
        if strcmp(detector, 'openpose') && interpolate_op_frame
            frame_time = timestamps(frame_num);
            adjusted_frame = int16(frame_time * fps);
%             adjusted_frame = int16(num_frames / length(timestamps) * frame_num);
            
            iRow = find(T.Var1 == adjusted_frame);
            
        else
            iRow = find(T.Var1 == frame_num);
        end
        
        order_of_keypoints = getKeypointOrderInCSV(detector);
        conf_thres = 0;
        
        
        raw_frame_data = T.Var2(iRow);
        raw_skels = strsplit( raw_frame_data{1} , ';' );
        for s = 1:length(raw_skels)
            cur_raw_skel = strsplit(raw_skels{s}, ',');
            cur_raw_skel_double = str2double(cur_raw_skel);
            
            % Extract this data to skel struct
            for i = 1:length(order_of_keypoints)
                cur_part_name = order_of_keypoints{i};
                data = [cur_raw_skel_double((i-1)*3 + 1), ...
                    cur_raw_skel_double((i-1)*3 + 2), ...
                    cur_raw_skel_double((i-1)*3 + 3)];
                skel.(cur_part_name) = data;
            end
            
            close all
            imshow(blurred_image);
            hold on
            skel_frame = 1;
            left_colour = 'b';
            right_colour = 'r';
            
            
            % Plot the skeleton over the image
            plotLine(skel, "LAnkle", "LKnee", skel_frame, left_colour, 0);
            plotLine(skel, "LKnee", "LHip", skel_frame, left_colour, 0);
            plotLine(skel, "LHip", "RHip", skel_frame, left_colour, 0);
            plotLine(skel, "LHip", "LShoulder", skel_frame, left_colour, conf_thres);
            plotLine(skel, "LShoulder", "LElbow", skel_frame, left_colour, conf_thres);
            plotLine(skel, "LShoulder", "RShoulder", skel_frame, left_colour, conf_thres);
            plotLine(skel, "LElbow", "LWrist", skel_frame, left_colour, conf_thres);
            
            % Right
            plotLine(skel, "RAnkle", "RKnee", skel_frame, right_colour, 0);
            plotLine(skel, "RKnee", "RHip", skel_frame, right_colour, 0);
            plotLine(skel, "RHip", "RShoulder", skel_frame, right_colour, conf_thres);
            plotLine(skel, "RShoulder", "RElbow", skel_frame, right_colour, conf_thres);
            plotLine(skel, "RElbow", "RWrist", skel_frame, right_colour, conf_thres);
            
            saveas(gcf, strcat(output_path, filesep, video_name, "_", num2str(frame_num)...
                , "_", detector, "_", num2str(s), ".jpg"));
        end
        
    end
end