function [result] = extractImageWithFFMPEG(input_video,frame_num, path_to_ffmpeg, temp_im_folder)
tmp = strcat(temp_im_folder, num2str(frame_num), '.jpg');
try
    ffm_line=sprintf('"%s" -i "%s" -vf "select=eq(n\\,"%i")" -vsync 0 %s 2> /dev/null -y',path_to_ffmpeg,input_video,frame_num, tmp);
    fprintf('Processing %s\n',tmp);

    system(ffm_line);
    fprintf('DONE processing %s\n',tmp);

    result = imread(tmp);
catch % The first approach may fail on windows so retry with a slightly different command
    ffm_line=sprintf('%s -i "%s" -vf "select=eq(n\\,%i)" -vframes 1 %s -y',path_to_ffmpeg,input_video,frame_num, tmp);
    fprintf('Processing %s\n',tmp);

    system(ffm_line);
    fprintf('DONE processing %s\n',tmp);
    result = imread(tmp);

end

delete(tmp)
end

