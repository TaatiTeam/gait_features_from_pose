classdef PosetrackerConfigs
    % This class stores the configuration data required to process raw
    % outputs from the posetrackers to skeleton CSV files that can be used
    % in later analyses
    
    properties
        % Steps in the pipeline
        do_labelling = 1
        do_discont_check = 1
        do_flip_fix = 1
        
        % Posetrackers to use
        detectors = {'openpose', 'detectron', 'alphapose'}; %'alphapose', 'openpose',  'detectron'};
        dataset = "TRI"; % Belmont, TRI, PD_Fasano
        is_kinect;
        is_3d;
        
        
        % Important constants
        filter_cutoff_hz = 8
        split_depth = 2
        
        % Specific configurations for each step
        labelling_configs
        discont_configs
        fix_flip_configs
        
        clean_trajectory_folder;
        
        % Error log location
        error_log_path = '/home/saboa/matlab_logs';     
        error_log
        
        % Console log level
        console_log_level = 0
        ffpath = '/usr/bin/ffmpeg';
        temp_im_folder = '/home/saboa/tmp_im';  % if extracting with ffmpeg
        % we need to save the image here temporarily
        % Need to have write
        % permission here
    end
    
    % Use this section to create static configurations if necessary.
    % Ideally this would go in the client code, but configurations can be
    % saved for the long-term here if necessary
    methods(Static)

    end
    
    
    methods
        function obj = PosetrackerConfigs(dataset, input_data_path, output_data_path, make_subfolders)
            % Perform all of the operations (labelling, discont checking,
            % flip fixing) for lakeside or TRI data
            if ~exist('make_subfolders','var')
                make_subfolders = 0;
            end
            % Create the temp_paths to use for discont and flipping
            label_output = fullfile(output_data_path, 'label_temp');
            discont_output = fullfile(output_data_path, 'discont_temp');
            final_output = fullfile(output_data_path, 'FINAL');
            obj.clean_trajectory_folder = final_output;
            folders_to_make = {label_output, discont_output, final_output};
            
            if make_subfolders
                for f = 1:length(folders_to_make)
                    fold = folders_to_make{f};
                    if ~exist(fold, 'dir')
                        mkdir(fold);
                    end
                end
            end
            obj.dataset = dataset;
            obj.labelling_configs = LabelingConfigs( dataset, input_data_path, label_output);
            obj.discont_configs = DiscontConfigs( dataset, label_output, discont_output);
            obj.fix_flip_configs = FixFlipConfigs(dataset, discont_output, final_output, obj.discont_configs.flipped_walks_detailed_output_file);
            obj.error_log = setUpErrorLog(obj.error_log_path);
            obj.is_kinect = 0;
            obj.is_3d = 0;
            
            obj = obj.setDataset(dataset);
        end
        
        function [obj] = setDetector(obj, detector)
            obj.detectors = detector;
            if (strcmp(obj.detectors, 'kinect_3d'))
                obj.is_kinect = 1;
                obj.is_3d = 1;
            elseif (strcmp(obj.detectors, 'kinect_2d'))
                obj.is_kinect = 1;
                obj.is_3d = 0;
            else
                obj.is_kinect = 0;
            end
            
        end
        
        % Utility functions dependent on dataset
        function [walk_id, patient_id, isbackward] = getWalkAndPatientID(obj, walk_base)
            % How we extract the walk and patient id is dependent on how
            % the files are named, and is thus dependent on dataset
            if strcmp(obj.dataset, "TRI")
                [walk_id, patient_id, isbackward] = getWalkAndPatientIDTRI(obj, walk_base);
            elseif strcmp(obj.dataset, "CUSTOM") % TODO: implement this
                error("Need to implement getWalkAndPatientID() in PosetrackerConfigs");
            elseif strcmp(obj.dataset, "PD_Fasano")
                [walk_id, patient_id, isbackward] = getWalkAndPatientIDPD(obj, walk_base);
            elseif strcmp(obj.dataset, "Dravet_homevids")
                [walk_id, patient_id, isbackward] = getWalkAndPatientIDPD(obj, walk_base);
                
            else
                error("ERROR in getWalkAndPatientID - don't have handler for %s", obj.dataset);
                
            end
        end
        
        
        function [video_path, walk_id, patient_id, timestamps] = getFPSAndNumFrames(obj, walk_base)
            % How we extract the walk and patient id is dependent on how
            % the files are named, and is thus dependent on dataset
            if strcmp(obj.dataset, "TRI")
                video_path = fullfile(walk_base, "Video.avi");
                
            elseif strcmp(obj.dataset, "Belmont")
                %TODO
            elseif strcmp(obj.dataset, "PD_Fasano")
                video_path = strcat(walk_base, ".avi");
                %TODO
            elseif strcmp(obj.dataset, "Dravet_homevids")
                [filepath,name,ext] = fileparts(walk_base);
                options = dir(fullfile(filepath, strcat(name, '*')));
                
                % select the first video available
                dirFlags = [options.isdir];
                options = options(~dirFlags);
                video_path_first = options(1);
                
                % Check if MOV file
                [~,~,ext] = fileparts(video_path_first.name);
                video_path = fullfile(video_path_first.folder, video_path_first.name);
                
                if strcmp(lower(ext), '.mov')
                    video_path = fullfile(video_path_first.folder, name, "RGB.avi");
                end
                %                 video_path = strcat(walk_base, ".mp4");
                
            else
                prompt("ERROR in getFPSAndNumFrames");
                
            end
            
            % Try to get the data from the VideoReader API but revert to
            % ffmpeg if that does not work
            [walk_id, patient_id, timestamps] = getFPSAndNumFramesFunc(obj, video_path);
        end
        
        
        function [width, height] = getVideoRes(obj, video_path)
            
            video_frame = extractImageWithFFMPEG(video_path,1, obj.ffpath, obj.temp_im_folder);
            
            width = size(video_frame, 2);
            height = size(video_frame, 1);
            
        end
        
    end % end public methods
    
    
    % Private methods
    methods (Access = private)
        function [obj] = setDataset(obj, dataset)
            
        end

        function [walk_id, patient_id, isbackward] = getWalkAndPatientIDTRI(~, walk_base)
            raw_path_split = strsplit(walk_base, filesep);
            walk_id = raw_path_split(end);
            walk_id = walk_id{1}; % cell to char
            
            patient_id = raw_path_split(end-1);
            patient_id = patient_id{1}; % cell to char
            
            
            parts = strsplit(walk_base, '_');
            isbackward = strcmp(parts{end-1}, "backward");
        end
        
        function [walk_id, patient_id, isbackward] = getWalkAndPatientIDPD(~, walk_base)
            raw_path_split = strsplit(walk_base, filesep);
            walk_id = raw_path_split(end);
            walk_id = walk_id{1}; % cell to char
            
            patient_id = raw_path_split(end-1);
            patient_id = patient_id{1}; % cell to char
            
            % For this dataset, the backwards/forwards depends on subsections of the bout
            isbackward = -1;
        end
        
        
        
        function [fps, num_frames, timestamps] = getFPSAndNumFramesFunc(obj, video_path)
            if ~(exist(video_path, 'file'))
                fps = -1;
                num_frames = -1;
                timestamps = [];
                return;
            end
            
            try
                v = VideoReader(video_path);
                timestamps = getTimestamps(obj, video_path);
                
                if v.NumFrames > 0
                    fps = v.NumFrames / v.Duration;
                    if length(timestamps) == 0
                        timestamps = 0:1/fps:v.NumFrames/fps - 1/fps;
                    end
                else
                    fps = length(timestamps) / v.Duration;
                end
                num_frames = v.NumFrames;
            catch
                fps = 30;
                timestamps = getTimestamps(obj, video_path);
                num_frames = length(timestamps);
            end
        end
        
        % Does error handling
        function [timestamps] = getTimestamps(obj, video_path)
            if ~(exist(video_path, 'file'))
                timestamps = [];
                return;
            end
            
            try
                timestamps = videoframets(obj.ffpath, char(video_path));
            catch
                timestamps = [];
                fprintf("Failed to load timestamps");
            end
        end
        
    end
end

