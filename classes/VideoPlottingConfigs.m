classdef VideoPlottingConfigs
    % This class ensures that we have all necessary fields for plotting
    % skeleton videos
    
    properties
        plot_from_csv = 0           % Is the input data a CSV file we need to first parse?
        plot_vid_underlay = 0       % Should we plot the colour video underneath?
        plot_skels = 1
        
        plot_footfalls = 0          % Should we plot the footfalls?
        footfalls               % These are all detected footfalls
        footfalls_final         % These are the footfalls from the region being analyzed
        
        num_frames_to_skip = 5  % How many frames at the beginnning should we ignore for the skeleton? 
                                % This is used to deal wiht filtering
                                % inaccuraries that may arise
        
        is_kinect = 0
        is_3d = 0 
        vertical_flip = 0;
        
        detectors = {'openpose'};
        skel_dir;
        
        % Style options
        left_colour = 'b'
        right_colour = 'r'
        footfall_colour = 'y'
        footfall_size = 150
        footfall_det_length = 1; % How many frames should we plot the footfalls for?
        
        %         path_to_ffprobe = '/usr/bin/ffprobe';
%         path_to_ffmpeg = '/usr/bin/ffmpeg';
        
        path_to_ffprobe = 'C:/Users/andre/Downloads/ffmpeg-4.3.1-2021-01-01-full_build/ffmpeg-4.3.1-2021-01-01-full_build/bin/ffprobe.exe'
        path_to_ffmpeg = 'C:/Users/andre/Downloads/ffmpeg-4.3.1-2021-01-01-full_build/ffmpeg-4.3.1-2021-01-01-full_build/bin/ffmpeg.exe';
        
        temp_im_folder = '/home/saboa/tmp_im'; % if extracting with ffmpeg
        % we need to save the image here temporarily
        % Need to have write
        % permission here
        
        
    end
    
    methods
        function obj = VideoPlottingConfigs()
        end
        
    end
end

