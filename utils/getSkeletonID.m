function [skel_id, is_valid] = getSkeletonID(walk_id, raw, walk_base, search_Eparticipant_files)
skel_id = NaN;
is_valid = 1; % is the value we loaded valid?
if (isnan(raw))
    is_valid = 0; % is the value we loaded valid?
    return;
end
if (isempty(raw))
    is_valid = 0; % is the value we loaded valid?
    return;
end

walk_ids = raw(:, 2);
skel_ids = raw(:, 13);

% When read from the csv, all walk ids have double quotations before and
% after so rather than removing them, it's faster to just add these to the
% search string. 
walk_id = strcat('''', walk_id, '''');


index = find(strcmp(walk_ids, walk_id));

if(length(index) > 0)
    skel_id = skel_ids(index);
    skel_id = skel_id{1};
    
    if(skel_id < 0 || skel_id > 3)
        is_valid = 0;
    end
    return
end

if (search_Eparticipant_files)
    % After everything is reprocessed, this should be used
    Epart_file = strcat(walk_base, filesep, 'Eparticipant.csv');
    try
        data = csvread(Epart_file);
        if (length(data) > 10)
            skel_id = data(end, end);
            if(skel_id < 0 || skel_id > 3)
                is_valid = 0;
            end
            
            
        end
        catch
    end
end



end

