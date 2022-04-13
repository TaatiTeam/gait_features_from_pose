function [] = exportVidsForFootfallLabelling(configs, vid_plot_configs, out_path)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

interpolated_or_raw = "interpolated";
input_struct = struct;
all_walks = configs.labelling_configs.GetWalksList();
output_folder = fullfile(out_path, "vids_with_framenum");



for row = 1:length(all_walks)
%     vid_path = fullfile(vid_files(v).folder, vid_files(v).name);
    walk_base = fullfile(configs.labelling_configs.input_folder, all_walks{row});
    [video_path, fps, ~, ~] = configs.getFPSAndNumFrames(walk_base);
    input_struct.fps = fps;

    walk_only = strsplit(all_walks{row}, filesep);
    walk_only = walk_only{end};
    output_file = fullfile(output_folder, strcat(all_walks{row}, ".mp4"));
    filepath = fileparts(output_file);
    if ~exist(filepath, 'dir')
        mkdir(filepath);
    end
    fprintf("============================================== %d/%d\n", row, length(all_walks));
    input_struct.video_file = video_path;
    
    % Go through all detectors
    if vid_plot_configs.plot_skels
        
        for d = 1:length(vid_plot_configs.detectors)
            detector = vid_plot_configs.detectors{d};
            
            det_root = fullfile(vid_plot_configs.skel_dir, detector, interpolated_or_raw);
            all_tracked_skels = dir(fullfile(det_root, strcat(walk_only, "*")));
            
            % Go through all available directions
            for a = 1:length(all_tracked_skels)
                input_struct.input_skel = fullfile(all_tracked_skels(a).folder, all_tracked_skels(a).name);
                vid_plot_configs.plot_from_csv = 1;
                output_file = fullfile(output_folder, strcat(all_tracked_skels(a).name, ".mp4"));
                plotSkelVideo(vid_plot_configs, input_struct, output_file);
            end
            
        end
    else
        plotSkelVideo(vid_plot_configs, input_struct, output_file);
    end
    
end
end

