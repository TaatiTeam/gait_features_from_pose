classdef DiscontConfigs
    
    properties
        input_folder
        output_folder
        dataset
        flipped_walks_detailed_output_file
        
        % Discont specific variables, in the future, these may change based
        % on dataset so are stored here
        num_frames_to_average = 10
        joint_diff_thres = 0.4   % This is percentage of 'height'
        do_discont_fix = 0       % Should we actually remove the discontinuities?
        
        do_second_pass_after_auto_flip = 1; % Should we check for discontinuities after fixing flips?
        num_frames_to_average2 = 15
        joint_diff_thres2 = 0.2   % This is percentage of 'height'      
        
        % How many frames should we skip when we do the flip analysis?
        % This is needed because interpolation leads to some issues at the
        % beginning of the sequence
        skip = 3;
        num_frames_to_smooth = 10;
        correct_vs_not_ratio = 0.05; % |A-B| / |A+B|
        max_freq_x_dir_init = 1; % Should we use the mean x value to initialize what is left and right (assumes most of the frames are correctly tracked)
        start_in_middle = 1;     % Assume the middle is the most certain part. Start joining from there
        
        process_raw = 1;   % By default, process the unfiltered data
        export_conf = 1;
        
        % Create skeleton videos
        export_vids = 0;                 % This exports all videos before the flip analysis
        export_vids_with_flips = 0;      % This exports the flipped skeletons
        export_plots = 0;                % This exports the x positions of the joints before and after flipping
    end
    
    methods
        function obj = DiscontConfigs(dataset, input_folder, output_folder)
            obj.dataset = dataset;
            obj.input_folder = input_folder;
            obj.output_folder = output_folder;
            obj.flipped_walks_detailed_output_file = fullfile(obj.output_folder, "all_flipped_walks_details.csv");
        end
        
        function [walks] = GetWalksList(obj, detector)
            if obj.process_raw
                root_folder = fullfile(obj.input_folder, detector, 'raw', '*.csv');
                
            else % interpolated
                root_folder = fullfile(obj.input_folder, detector, 'interpolated', '*.csv');
            end
            
            walks = dir(root_folder);
        end
        
        
    end
end

