close all, clear all

in_path = "not_used/";          % This is used for labelling data (ignore in this release)
out_path = "sample_data/";      % This is the input directory for the processed trajectories (or output if labelling/preparing)
make_subfolders = 0;            % Enable this when labelling data, not needed if only calculating gait features


dataset_name = "TRI";           % Make sure we have code to handle this dataset in the PosetrackerConfigs class 
% dataset_name = "CUSTOM";      % Uncomment this line to create a custom dataset (you will need to define dataset specific handlers for each operation that requires it)

configs = PosetrackerConfigs(dataset_name, in_path, out_path, make_subfolders);
configs.do_labelling = 0;       % Ignore in this release
configs.do_discont_check = 0;   % Ignore in this release
configs.detectors = {'alphapose', 'openpose', 'detectron'};  % TODO: change this as needed. Names of detectors to use

% configs.ffpath = 'C:/Users/andre/Downloads/ffmpeg-4.3.1-2021-01-01-full_build/ffmpeg-4.3.1-2021-01-01-full_build/bin/ffmpeg.exe'; % This isn't always needed, but is used as a fallback when MATLAB operations fail

% Calculate gait features
ft_configs = GaitFeatureConfigs(["DBSCAN", "original"], dataset_name);
ft_configs.raw_or_filt = 'interpolated'; 
% ft_configs.manual_step_root = "/home/saboa/data/objective_2/manual_annotations_global";  % path to manual steps only needed when "manual" option is selected (these can be generated easily using: https://github.com/andreasabo-ibbme/step_labeller)
ft_configs = ft_configs.setOutputRoot(fullfile(out_path, "gait_features"));
calculateGaitFeatures(configs, ft_configs);

% Reexport the final trajectories to be centred at 100
is_kinect = 0;
is_3D = 0;
export_configs = ExportConfigs(fullfile(out_path, 'centred_at_100'), is_kinect, is_3D);
export_configs.center_hip = 1;
reference_file = fullfile(ft_configs.output_root, "alphapose_DBSCAN.csv");
centreCSVsat100(configs, export_configs, "raw", reference_file); % This will interpolate and filter the raw (alternatively, can just pass in the clean data and these operations are redundant)



