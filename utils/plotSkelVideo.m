function [] = plotSkelVideo(video_configs, input_struct, output_file)
% function [] = plotSkelVideo(skel_file, video_file, output_file, skel_tracking_start_frame, conf_thres, footfalls, footfalls_final, fps, plotfootfalls, additional_data)
% ffmpeg -i Belmont12-top.mp4 -vcodec mjpeg -acodec copy output.mkv
% for i in *.mp4;   do name=`echo "$i" | cut -d'.' -f1`;   echo "$name";   ffmpeg -i "$i" -vcodec mjpeg -acodec copy "${i}.mkv"; done



if video_configs.plot_skels
    
    % Load skel from CSV if needed
    if video_configs.plot_from_csv
        [skel, input_struct.start_frame] = loadCSVtoSkel(input_struct.input_skel);
    else
        skel = input_struct.input_skel;
    end
    
    frames = length(skel.Nose);
    
    
    % Set up the bounds
    min_x = min(skel.x_range(:, 1));
    max_x = max(skel.x_range(:, 2));
    
    min_y = min(skel.y_range(:, 1));
    max_y = max(skel.y_range(:, 2));
    
    skel_tracking_start_frame = input_struct.start_frame;
    
    
    
else % Not plotting the skeletons
    frames = inf; % don't need this variable if we're not plotting the skel
    skel_tracking_start_frame = 1;
end

footfall_det_length = video_configs.footfall_det_length;
fps = input_struct.fps;
num_frames_to_skip = video_configs.num_frames_to_skip;
plotfootfalls = video_configs.plot_footfalls;

left_colour = video_configs.left_colour;
right_colour = video_configs.right_colour;
footfall_colour = video_configs.footfall_colour;

conf_thres = 0;



% Only load the video file if we have to plot the underlay
if video_configs.plot_vid_underlay
    v = VideoReader(input_struct.video_file);
    
    num_vid_frames = v.NumFrames;
    need_ffmpeg = 0;
    if (num_vid_frames == 0)
        need_ffmpeg = 1;
        
    end
    video_configs.path_to_ffprobe = 'C:/Users/andre/Downloads/ffmpeg-4.3.1-2021-01-01-full_build/ffmpeg-4.3.1-2021-01-01-full_build/bin/ffprobe.exe';
    
    ffm_line=sprintf('%s -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "%s"',video_configs.path_to_ffprobe, input_struct.video_file);
    [status, num_frames] = system(ffm_line);
    num_vid_frames = str2num(num_frames);

%     num_vid_frames = videoframets(video_configs.path_to_ffmpeg, char(input_struct.video_file));
    video_frame = extractImageWithFFMPEG(input_struct.video_file,1, video_configs.path_to_ffmpeg, video_configs.temp_im_folder);
    
    width = size(video_frame, 2);
    height = size(video_frame, 1);
    
    

elseif video_configs.plot_skels
    num_vid_frames = inf;
    width = max_x;
    height = max_y;
else
    fprintf("Not plotting skel or video, exiting (%s)...\n", output_file);
    return
end


viz_start_frame = max(1, skel_tracking_start_frame);
viz_stop_frame = min(num_vid_frames, skel_tracking_start_frame + frames);
local_frame = 1;

% Output vid
writerObj = VideoWriter(char(output_file));
writerObj.FrameRate = fps;
open(writerObj);

f = figure('Menu','none','ToolBar','none', 'visible','off', 'Renderer', 'painters', 'Position', [1 1 width height]);
a = axes('Units','Normalize','Position',[0 0 1 1]);

    % for frame = viz_start_frame:viz_stop_frame - 1
for frame = viz_start_frame:viz_stop_frame - 1
    % for frame = viz_start_frame:100

    set(gcf, 'Menu','none','ToolBar','none', 'visible','off', 'Renderer', 'painters', 'Position', [1 1 width height])
    set(gca, 'Units','Normalize','Position',[0 0 1 1]);
    f.Resize = 'off';
    hold on
    grid on
    if video_configs.plot_vid_underlay
        try
            if need_ffmpeg
                video_frame = extractImageWithFFMPEG(input_struct.video_file,frame, video_configs.path_to_ffmpeg, video_configs.temp_im_folder);
            else
                video_frame = read(v,frame);
            end
        catch
            break;
        end
        imshow(video_frame);
    else
        xlim([min_x, max_x])
        ylim([min_y, max_y])
    end
    if mod(frame, 50) == 0
        fprintf(strcat(num2str(frame), '/', num2str(viz_stop_frame), '\n'))
        
    end
    
    if video_configs.plot_skels
        % Get the skeletons to plot at this time
        if frame > num_frames_to_skip && frame <= (skel_tracking_start_frame + frames)
            hold on
            skel_frame = frame + 1 - skel_tracking_start_frame;
            if skel_frame < 1
                continue
            end
            plotLine(skel, "LAnkle", "LKnee", skel_frame, left_colour, 0, width, height);
            plotLine(skel, "LKnee", "LHip", skel_frame, left_colour, 0, width, height);
            plotLine(skel, "LHip", "RHip", skel_frame, left_colour, 0, width, height);
            plotLine(skel, "LHip", "LShoulder", skel_frame, left_colour, conf_thres, width, height);
            plotLine(skel, "LShoulder", "LElbow", skel_frame, left_colour, conf_thres, width, height);
            plotLine(skel, "LShoulder", "RShoulder", skel_frame, left_colour, conf_thres, width, height);
            plotLine(skel, "LElbow", "LWrist", skel_frame, left_colour, conf_thres, width, height);
            
            % Right
            plotLine(skel, "RAnkle", "RKnee", skel_frame, right_colour, 0, width, height);
            plotLine(skel, "RKnee", "RHip", skel_frame, right_colour, 0, width, height);
            plotLine(skel, "RHip", "RShoulder", skel_frame, right_colour, conf_thres, width, height);
            plotLine(skel, "RShoulder", "RElbow", skel_frame, right_colour, conf_thres, width, height);
            plotLine(skel, "RElbow", "RWrist", skel_frame, right_colour, conf_thres, width, height);
            

            if plotfootfalls
                % Check if this is when a footfall is detected
                for j=1:size(footfalls,1)
                    % Checking left footfall
                    if abs(skel_frame - footfalls(j,1)) <= footfall_det_length
                        scatter(skel.LAnkle(skel_frame, 1), skel.LAnkle(skel_frame, 2),video_configs.footfall_size, footfall_colour, 'filled')
                    end
                    % Checking right footfall
                    
                    if abs(skel_frame - footfalls(j,2)) <= footfall_det_length
                        scatter(skel.RAnkle(skel_frame, 1), skel.RAnkle(skel_frame, 2),video_configs.footfall_size, footfall_colour, 'filled')
                    end
                end
                
                try
                    if skel_frame >= min(footfalls_final) && skel_frame <= max(footfalls_final)
                        text(10, 20, "Analyzing this part of walk", 'FontSize', 14, 'Color', 'g');
                        
                    end
                catch
                end
            end
%             text(width - 40 , height - 20, string(skel_frame), 'FontSize', 18, 'Color', 'g');
            
%             xlim([min_x, max_x])
%             ylim([min_y, max_y])
            
        end
    end % plot skel
%     text( 10 , height - 20, string(frame), 'FontSize', 18, 'Color', 'r');
    if video_configs.vertical_flip
        set(gca, 'YDir','reverse');
    end
    
    
    
    %     set(gca, 'XDir','reverse')
    %         plotLine(skel, 'ShoulderLeft' , 'ElbowLeft', colour)
    %         plotLine(skel, 'ShoulderRight' , 'ElbowRight', 'k')
    %         plotLine(skel, 'WristLeft' , 'ElbowLeft', colour)
    %         plotLine(skel, 'WristRight' , 'ElbowRight', 'k')
    %         plotLine(skel, 'HipLeft' , 'KneeLeft', colour)
    %         plotLine(skel, 'HipRight' , 'KneeRight', colour)
    %         plotLine(skel, 'AnkleLeft' , 'KneeLeft', colour)
    %         plotLine(skel, 'AnkleRight' , 'KneeRight', colour)
    %         plotLine(skel, 'SpineBase' , 'SpineMid', colour)
    %         plotLine(skel, 'SpineMid' , 'Neck', colour)
    %         txt = num2str(i);
    %         text(positions.SpineMid(1),positions.SpineMid(2),positions.SpineMid(3),txt);
    %
    %
    
    drawnow
    F_local = getframe(gcf) ;
    writeVideo(writerObj, F_local);
%     F(local_frame) = getframe(gcf) ;
    clf(f, 'reset');
%     close(f);
    local_frame  = local_frame + 1;

    
end


% write the frames to the video
% for i=1:length(F)
%     % convert the image to a frame
%     frame = F(i) ;
%     writeVideo(writerObj, frame);
% end
% close the writer object
close(writerObj);

clear F
end

