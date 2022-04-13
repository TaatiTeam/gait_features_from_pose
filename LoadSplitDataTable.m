function [output_table] = LoadSplitDataTable(csv_path, depth)
if nargin < 2
    depth = 2;
end

base_dir = fileparts(csv_path);

data = readtable(csv_path, 'PreserveVariableNames', 1);

output_struct = struct();
output_table = table('Size', [height(data), 6], 'VariableTypes', {'string', 'string', 'string', 'duration', 'duration', 'string'},...
    'VariableNames', {'vid_path', 'patient', 'video_name', 'start_time', 'end_time', 'suffix'} );


for i = 1:height(data)
    raw_video_name = string(data.vid_name{i});
    split_name = strsplit(raw_video_name, filesep);
    patient_name = split_name(depth);
    video_name = split_name(end);
    
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
    
    output_table.vid_path(i) = fullfile(base_dir, raw_video_name);
    output_table.patient(i) = patient_name;
    output_table.video_name(i) = video_name;
    output_table.start_time(i) = start;
    output_table.end_time(i) = stop;
    output_table.suffix(i) = string(data.output_vid_name{i});
end
end