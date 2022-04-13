function [failed_detections_log] = setUpErrorLog(output_csv_path, file_prefix)
if (nargin < 2)
    file_prefix = "error";
end
if (nargin < 1)
    output_csv_path = 'N:\AMBIENT\Andrea S\Matlab_for_2D_Feature_Extraction\output';

end
cur_time = now; 
error_log_mat = strcat(file_prefix,num2str(cur_time),'.mat');
error_log_csv = strcat(file_prefix,num2str(cur_time),'.csv');
error_log_file_name = strcat(output_csv_path, filesep, error_log_mat);
error_log_file_name_csv = strcat(output_csv_path, filesep, error_log_csv);


failed_detections_log = struct;
failed_detections_log.error_log_file_name = error_log_file_name;
failed_detections_log.error_log_file_name_csv = error_log_file_name_csv;
failed_detections_log.log = struct;

if ~exist(output_csv_path, 'dir')
    mkdir(output_csv_path);
end

end

