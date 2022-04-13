function [] = calculateGaitFeatures(configs, gait_fts_configs)
% Go through all of the walks and calculate gait features using each method
all_walks_source  = configs.clean_trajectory_folder;

% Go through each detector
for d = 1:length(configs.detectors)
    detector = configs.detectors{d};
    num_gait_features = 13;
    if strcmp(detector, 'romp')
        num_gait_features = 22;
    end
    all_walks_for_det = fullfile(all_walks_source, detector, gait_fts_configs.raw_or_filt);
    walk_csvs = dir(all_walks_for_det + "/*csv");
    
    % Go through all footfall methods
    for t = 1:length(gait_fts_configs.footfall_methods)
        ff_method = gait_fts_configs.footfall_methods(t);
        gait_features_all = NaN*zeros(length(walk_csvs), num_gait_features);
        T = table('Size', [length(walk_csvs), 6], ...
            'VariableTypes', {'string', 'string', 'string', 'string', 'string', 'string'}, ...
            'VariableNames', {'patient', 'walk', 'vid_name', 'direction', 'crop', 'detector'});
        
        full_output_file = fullfile(gait_fts_configs.output_root, ...
                            strcat(detector, "_", ff_method, ".csv"));
        
        % Go through all walks
        for i = 1:length(walk_csvs)
            walk_csv = fullfile(walk_csvs(i).folder, walk_csvs(i).name);
            
            % Load walks and manual annotations (if needed)
            skelT = readtable(walk_csv);
            
            start_frame = skelT.start_frame(1);
            fps = skelT.fps(1);
            
            T(i, :).patient = skelT.patient_id(1);
            T(i, :).walk = skelT.walk_id(1);
            T(i, :).vid_name = walk_csvs(i).name;
            T(i, :).detector = detector;
            T(i, :).direction = "forward";
            try
                if skelT.is_backward(1)
                    T(i, :).direction = "backward";
                end
            catch
                if ~strcmp(skelT.is_backward{1}, 'false')
                    T(i, :).direction = "backward";
                end
            end
            
            
            if fps == 0
                fps = 30;
            end
            
            
            configs.getWalkAndPatientID(walk_csv);
            
            % TODO: backwards compatibility for walks without the fields
            % below
            
            additional_info = struct;
            additional_info.x_res = skelT.width;
            additional_info.y_res = skelT.height;

            additional_info.fps = fps;
            additional_info.is_backward = skelT.is_backward(1);
            additional_info.start_frame = start_frame;
            additional_info.is_3d  = configs.is_3d;
            
            
            % Filter skel if needed
            export_conf = 1;
            is_kinect = 0;
            skel = table2skel(skelT, export_conf, is_kinect);
            
            [skel] = interpolateAndFilterSkelData(skel, detector, gait_fts_configs.filter_cutoff, 0, fps, getConfThres(detector), 0);
            skel.time = skelT.time;
            gait_fts_configs = gait_fts_configs.setConstants(gait_fts_configs.dataset, detector);

            % Get the footfalls using the required method
            if strcmp(ff_method, "manual")
                additional_info.manual_steps = fullfile(gait_fts_configs.manual_step_root, ...
                    strcat(skelT.walk_id(1), ".csv"));
                [footfalls_good, footfalls_all, start_is_left] = stepDetectionManual(skel, additional_info);
                
            elseif strcmp(ff_method, "DBSCAN")
                [footfalls_good, footfalls_all, start_is_left] = stepDetectionDBSCAN(skel, additional_info, gait_fts_configs);
                
            elseif strcmp(ff_method, "peak3d")
                [footfalls_good, footfalls_all, start_is_left] = stepDetection3DPeak(skel, additional_info, gait_fts_configs);
                
                
            end
            
            % Now calculate the gait features using the footsteps and
            % signal
            if strcmp(detector, 'romp')
                % 3D gait features
                 additional_info.mult_factor = 1000;
                 [gait_features] = computeFeatsFromFootfalls_3d(skelT, skel, footfalls_good, start_is_left, additional_info);

            else
                % 2D gait features 
                [gait_features] = computeFeatsFromFootfalls(skelT, skel, footfalls_good, start_is_left);
            end
            
            gait_features_all(i, :) = gait_features;

        end % end cur walk
        
        if configs.is_3d
            gait_feature_table = array2table(gait_features_all,...
                'VariableNames',{'speed', 'cadence', 'steptime_mean', 'steplength_mean', 'stepwidth_mean', ...
                'CVSteptime', 'CVSteplength', 'CVStepwidth', 'sdSacrML', 'rmsSacrMLvel', 'romSacrML', ...
                'symSteptime', 'symStepLength', 'symStepWidth', ...
                'MOS_mean_final_new', 'MOS_min_final_new', 'percent_time_new', ...
                'stepsofwalk', 'skel_id', 'fps', 'start_frame', 'num_frames_in_trajectory'});
            
        else
            gait_feature_table = array2table(gait_features_all,...
                'VariableNames',{'cadence',	'avgMOS', 'avgminMOS', 'timeoutMOS', 'avgstepwidth'...
                'CVstepwidth', 'CVsteptime', 'SIStepTime', 'stepsofwalk', 'skel_id', 'fps', 'start_frame', 'num_frames_in_trajectory'});
            
        end
 
        % Combine the two tables
        table_to_export = [T gait_feature_table];
        writetable(table_to_export,full_output_file);
    
    end % end step detection method
end % end detector



end