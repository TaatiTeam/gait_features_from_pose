close all, clear all, clc

in_path = "sample_data/raw_posetracking";          % This is used for labelling data 
out_path = "sample_data/FINAL_labelled";           % This is the input directory for the processed trajectories (or output if labelling/preparing)
% out_path = "sample_data/";           % Uncomment this to run the gait feature calculation (NOT labelling) example
make_subfolders = 0;            % Enable this when labelling data, not needed if only calculating gait features

dataset_name = "TRI";           % Make sure we have code to handle this dataset in the PosetrackerConfigs class 
% dataset_name = "CUSTOM";      % Uncomment this line to create a custom dataset (you will need to define dataset specific handlers for each operation that requires it)

configs = PosetrackerConfigs(dataset_name, in_path, out_path, make_subfolders);
configs.do_labelling = 1;       % Should we label the participant?
configs.do_discont_check = 1;   % Should we fix the discontiuities and flips in the trajectory?
configs.detectors = {'alphapose'}; %, 'openpose', 'detectron'};  % TODO: change this as needed. Names of detectors to use

% Default MATLAB utilities sometimes fail to open all file types on all platforms so use FFMPEG (slower workflows, but more accurate)
configs.ffpath = 'C:/Users/andre/Downloads/ffmpeg-4.3.1-2021-01-01-full_build/ffmpeg-4.3.1-2021-01-01-full_build/bin/ffmpeg.exe'; 

% Extract the participant data to csvs
configs.labelling_configs.skip_if_epart_file_exists = 1; % Turn this on to avoid re-labelling walks (but turn off if re-processing with new configuration)
configs = joinTrajectoriesAndLabel(configs);

% Do discontinuity checking and fix any flips in the skeletons
configs= fixDiscontinuitiesAndFlips(configs);


% Calculate gait features
ft_configs = GaitFeatureConfigs(["DBSCAN", "original"], dataset_name); % 'manual' is also an option, but requires annotations of frames in which footfalls occur
ft_configs.raw_or_filt = 'interpolated'; 
% ft_configs.manual_step_root = "/home/saboa/data/objective_2/manual_annotations_global";  % path to manual steps only needed when "manual" option is selected (these can be generated easily using: https://github.com/andreasabo-ibbme/step_labeller)
ft_configs = ft_configs.setOutputRoot(fullfile(out_path, "gait_features"));
calculateGaitFeatures(configs, ft_configs);

% Reexport the final trajectories to be centred at 100
is_kinect = 0;
is_3D = 0;
export_configs = ExportConfigs(fullfile(out_path, 'centred_at_100'), is_kinect, is_3D);
export_configs.center_hip = 1;
reference_file = fullfile(ft_configs.output_root, "alphapose_original.csv");
centreCSVsat100(configs, export_configs, "raw", reference_file); % This will interpolate and filter the raw (alternatively, can just pass in the clean data and these operations are redundant)



