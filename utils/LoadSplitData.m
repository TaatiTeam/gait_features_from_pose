function [output_struct] = LoadSplitData(csv_path, depth)
if nargin < 2
    depth = 1;
end

data = readtable(csv_path, 'PreserveVariableNames', 1);

output_struct = struct();

for i = 1:height(data)
    raw_video_name = string(data.vid_name{i});
    split_name = strsplit(raw_video_name, '/');
    patient_name = split_name(depth);
    video_name = "vid_" + split_name(end);
    
    % Clean up the suffix from video name if it exists
    res = strsplit(video_name, '.');
    video_name = res(1);
    suffix = "";
    if length(res) > 1
        suffix = res(2);
    end
    
    
    start = data.start(i);
    try
        stop = data.stop(i);
    catch
        stop = data.end(i);
    end
    if (isfield(output_struct, patient_name) && isfield(output_struct.(patient_name), video_name) )
        output_struct.(patient_name).(video_name) = [output_struct.(patient_name).(video_name); {start, stop, data.output_vid_name{i}, suffix}];
    else
        output_struct.(patient_name).(video_name) = {start, stop, data.output_vid_name{i}, suffix};
        
    end
end


end