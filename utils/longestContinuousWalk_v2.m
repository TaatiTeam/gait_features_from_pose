function [footfall_locs_final,footfall_locs, start_is_left] = longestContinuousWalk_v2(locsl,locsr, num_timesteps)
% Look for the longest stretch of data with correctly alternating
% left/right footfalls


try
    correct_pattern_locs = struct();
    i = 1;
    start_is_left = 1;
    if locsl(1) == locsr(1)
        locsr(1) = [];
    end
    
    if locsl(1) > locsr(1)
        start_is_left = 0;
    end
    
    footfall_locs = NaN*ones(max(length(locsl), length(locsr)), 2);
    
    footfall_locs(1:length(locsl), 1) = locsl;
    footfall_locs(1:length(locsr), 2) = locsr;
    
    
    all_ffs = zeros(1, 2*max(length(locsl),length(locsr)));
    
    all_ffs(2 - start_is_left:2:end) = footfall_locs(:, 1);
    all_ffs(2 - ~start_is_left:2:end) = footfall_locs(:, 2);
    
    for start_loc = 1:length(all_ffs)
        
        for cur_loc = 2:length(all_ffs)
            % No longer increasing
            if all_ffs(cur_loc) <= all_ffs(cur_loc -1) || (cur_loc == length(all_ffs) && isnan(all_ffs(end)))
                current_locs = all_ffs(start_loc:cur_loc - 1);
                current_locs(isnan(current_locs)) = [];
                string_name = "a_" + string(i);
                correct_pattern_locs.(string_name).locs = current_locs;
                correct_pattern_locs.(string_name).start_is_left = mod(start_loc - start_is_left + 1, 2) ;
                i = i + 1;
            elseif cur_loc == length(all_ffs) && ~isnan(all_ffs(end))
                current_locs = all_ffs(start_loc:cur_loc);
                current_locs(isnan(current_locs)) = [];
                
                string_name = "a_" + string(i);
                correct_pattern_locs.(string_name).locs = current_locs;
                correct_pattern_locs.(string_name).start_is_left = mod(start_loc - start_is_left + 1, 2) ;
                i = i + 1;
                
            end
            
        end
    end
    
catch
    %     fprintf("something is wrong");
    footfall_locs = NaN*ones(max(length(locsl), length(locsr)), 2);
    footfall_locs_final = [];
    start_is_left = -1;
    return;
end
% Extract the section that is the longest and analyze it.
fields = fieldnames(correct_pattern_locs);
longest = 0;
locs = [];
for f = 1:length(fields)
    if length(correct_pattern_locs.(fields{f}).locs) > longest
        longest = length(correct_pattern_locs.(fields{f}).locs);
        locs = correct_pattern_locs.(fields{f}).locs;
        start_is_left = correct_pattern_locs.(fields{f}).start_is_left;
    end
end

if start_is_left
    left_ff = locs(1:2:end);
    right_ff = locs(2:2:end);
    
else
    left_ff = locs(2:2:end);
    right_ff = locs(1:2:end);
end

footfall_locs_final = locs;

% Remove any that are outside of the length of the data
footfall_locs_final(footfall_locs_final < 1) = [];
footfall_locs_final(footfall_locs_final > num_timesteps) = [];

left_ff(left_ff < 1) = [];
left_ff(left_ff > num_timesteps) = [];

right_ff(right_ff < 1) = [];
right_ff(right_ff > num_timesteps) = [];

try
    if left_ff(1) < right_ff(1)
        start_is_left = 1;
    else
        start_is_left = 0;
    end
catch
end


end % end function