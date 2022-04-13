function [ sorted_skel ] = AddToSkel(sorted_skel, cur_skel, frame)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
fn = fieldnames(sorted_skel);

for i = 1:length(fn)
    cur_joint = fn{i};
    if ~isstruct(cur_skel)
        if strcmp(cur_joint, 'op2d')
            subfields = fieldnames(sorted_skel);
            for s = 1:length(subfields)
                
                cur_subjoint = subfields{s};
                if strcmp(cur_subjoint, 'op2d')
                    continue
                end
                sorted_skel.(cur_joint).(cur_subjoint)(end+1, :) = [nan, nan, nan];
                
            end
        else
            sorted_skel.(cur_joint)(end+1, :) = [nan, nan, nan];
        end
    else
        if strcmp(cur_joint, 'op2d')
            subfields = fieldnames(sorted_skel);
            for s = 1:length(subfields)
                cur_subjoint = subfields{s};
                if strcmp(cur_subjoint, 'op2d')
                    continue
                end
                sorted_skel.(cur_joint).(cur_subjoint)(end+1, :) = cur_skel.(cur_joint).(cur_subjoint)(frame, :);
%                 fprintf("Joint: %s, subjoint: %s\n", cur_joint, cur_subjoint);
                
            end
        else
            
            sorted_skel.(cur_joint)(end+1, :) = cur_skel.(cur_joint)(frame, :);
        end
    end
    
end


end

