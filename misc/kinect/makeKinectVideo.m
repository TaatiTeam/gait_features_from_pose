function [] = makeKinectVideo(fullpath, skeleton_files, output_file)
if length(skeleton_files) == 0
    return
end
fps = 10;
all_skels = {};
num_frames = 0;
min_x = 999999999;
min_y = 999999999;
max_x = -999999999;
max_y = -999999999;
for i = 1:length(skeleton_files)
    path_to_csv = join([fullpath, skeleton_files{i}], filesep);
    [skel_struct] = processKinectFromCSVFile(path_to_csv);
    all_skels{i} = skel_struct;
    num_frames = max(num_frames, length(skel_struct.LAnkle(:, 1)));
    s = fieldnames(skel_struct);
    for f_i = 1:length(s)
        field = s{f_i};
        min_x = min(min_x, min(skel_struct.(field)(:, 1)));
        min_y = min(min_y, min(skel_struct.(field)(:, 2)));
        
        max_x = max(max_x, max(skel_struct.(field)(:, 1)));
        max_y = max(max_y, max(skel_struct.(field)(:, 2)));
    end
end


% Output vid
writerObj = VideoWriter(char(output_file));
writerObj.FrameRate = fps;
open(writerObj);
width = 640;
height = 480;

f = figure('Menu','none','ToolBar','none', 'visible','off', 'Renderer', 'painters', 'Position', [1 1 width height]);
a = axes('Units','Normalize','Position',[0 0 1 1]);



for frame = 1:num_frames
    set(gcf, 'Menu','none','ToolBar','none', 'visible','off', 'Renderer', 'painters', 'Position', [1 1 width height])
    set(gca, 'Units','Normalize','Position',[0 0 1 1]);
    f.Resize = 'off';
    hold on
    grid on
    
    xlim([min_x, max_x])
    ylim([min_y, max_y])
    
    for c = 1:length(all_skels)
        cur_skel = all_skels{c};
        plotKinectSkel(cur_skel, c, frame);
    end
    
    drawnow
    F_local = getframe(gcf) ;
    writeVideo(writerObj, F_local);
    clf(f, 'reset');
    
end
close(writerObj);
close all;
end

