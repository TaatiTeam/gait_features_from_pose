function [failed_detections_log] = logError(failed_detections_log, err_message, err_code, err_file, AMBid, walkID)
x = char(string(err_code));
if (length(fieldnames(failed_detections_log.log)) == 0)
    failed_detections_log.log = struct('err_message', {err_message}, ...
        'error_code', x, ...
        'file', err_file, ...
        'AMB', AMBid, ...
        'walk_id', walkID);
else
    failed_detections_log.log(end+1) = struct('err_message', {err_message}, ...
        'error_code', x, ...
        'file', err_file, ...
        'AMB', AMBid, ...
        'walk_id', walkID);
end
failed_detections_log_log = failed_detections_log.log;


save(failed_detections_log.error_log_file_name, 'failed_detections_log_log');

try
    cell_dat = transpose(struct2cell(failed_detections_log_log));
catch
    cell_dat = transpose(struct2cell(failed_detections_log_log(:)));
end
% cell_dat
% xlswrite(failed_detections_log.error_log_file_name_csv, cell_dat);

 fid = fopen(failed_detections_log.error_log_file_name_csv,'wt');
 if fid>0
     for k=1:size(cell_dat,1)
         fprintf(fid,'%s,%s,%s,%s,%s\n',cell_dat{k,:});
     end
     fclose(fid);
 end

end




