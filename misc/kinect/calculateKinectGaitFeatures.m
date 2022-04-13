clear all, close all, clc
%% Hacky file to quickly export Kinect trajectories and gait features

search_folder = "N:\\AMBIENT/Lakeside/extractions_lakeside"; % This folder only has Kinect videos
full_output_file = "N:\\AMBIENT/Lakeside/extractions_lakeside/kinect_gait_fts.csv";
trajectory_folder = "N:\\AMBIENT/Lakeside/kinect_joint_trajectories";
subfolders = GetSubDirsSecondLevelOnly(search_folder);
unlabelled_walks = [];
error_labels = [];
num_gait_features = 22;
gait_features_all = NaN*zeros(length(subfolders), num_gait_features);
T = table('Size', [length(subfolders), 6], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'patient', 'walk', 'vid_name', 'direction', 'crop', 'detector'});


export_configs = ExportConfigs(trajectory_folder, 1, 1);
export_configs.save_clinical_scores = 0;
export_configs.save_demographics = 0;

for s = 1:length(subfolders)
    fullpath = join([search_folder, subfolders{s}], filesep);
    split_name = strsplit(subfolders{s}, filesep);
    AMB_id = split_name{1};
    label_file = join([fullpath, 'skel_label.txt'], filesep);
    
    T(s, :).patient = split_name{1};
    T(s, :).walk = split_name{2};
    T(s, :).vid_name = strcat(split_name{1}, ".", split_name{2});
    T(s, :).detector = "Kinect";
    T(s, :).direction = "forward";
    
    if ~exist(label_file, 'file')
        unlabelled_walks = [unlabelled_walks; fullpath];
        continue;
    end

    [error_in_skel_label, skel_struct, smoothed_skel_struct] = loadKinectSkeleton(fullpath, label_file);
    if error_in_skel_label
        error_labels = [error_labels; fullpath];
        continue;
    end
    
    % GAIT FEATURES
    [footfall_locs_final,footfall_locs, start_is_left] = stepDetection3DPeak(smoothed_skel_struct, NaN, NaN, 1);
    skelT = struct;
    skelT.fps = 30;
    skelT.start_frame = 1; % placeholder
    [gait_features] = computeFeatsFromFootfalls_3d(skelT, ...
        smoothed_skel_struct, footfall_locs_final, start_is_left);
    gait_features_all(s, :) = gait_features;
    
    % Export the trajectories
    % Set up the walk data
    walk_data.fps = 30;
    frame_duration = 1/walk_data.fps;
    walk_data.detector = 'kinect';
    walk_data.num_frames = size(skel_struct.RHip, 1);
    walk_data.timestamps = 0: 1/frame_duration : 1/frame_duration * walk_data.num_frames - frame_duration;
    walk_data.timestamps = (walk_data.timestamps)';
    walk_data.walk_id = T(s, :).walk;
    walk_data.patient_id = T(s, :).patient;
    walk_data.subwalk = "";
    walk_data.is_backward = 0;
    
    walk_data.start_frame = 1;
    walk_data.fixOP = 0;
    walk_data.width = 1920;
    walk_data.height = 1080;
    
    exportSkelDataToCSV(export_configs, walk_data, skel_struct, smoothed_skel_struct);
    
    
end

% Create final table
gait_feature_table = array2table(gait_features_all,...
    'VariableNames',{'speed', 'cadence', 'steptime_mean', 'steplength_mean', 'stepwidth_mean', ...
    'CVSteptime', 'CVSteplength', 'CVStepwidth', 'sdSacrML', 'rmsSacrMLvel', 'romSacrML', ...
    'symSteptime', 'symStepLength', 'symStepWidth', ...
    'MOS_mean_final_new', 'MOS_min_final_new', 'percent_time_new', ...
    'stepsofwalk', 'skel_id', 'fps', 'start_frame', 'num_frames_in_trajectory'});

% Combine the two tables
table_to_export = [T gait_feature_table];
writetable(table_to_export,full_output_file);


%% Save a list of the walks that we don't have a skel_label for. This could
% be because the walk is aided, or because the Kinect didn't track any
% skeletons. Save the list of files to analyze later. 
unlabelled_walk_file = "N:\\AMBIENT/Lakeside/extractions_lakeside/kinect_unlabelled.txt";
error_walk_file = "N:\\AMBIENT/Lakeside/extractions_lakeside/kinect_error_label.txt";

fileID = fopen(unlabelled_walk_file,'w');
fprintf(fileID,'%s\n',unlabelled_walks);
fclose(fileID);

fileID = fopen(error_walk_file,'w');
fprintf(fileID,'%s\n',error_labels);
fclose(fileID);