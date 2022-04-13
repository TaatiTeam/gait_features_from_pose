function [ mean_skel ] = ComputeMeanSkel(skel, frames_to_average )
mean_skel = struct;
fn = fieldnames(skel);

for i = 1:length(fn)
    cur_joint = fn{i};
    
    try
       mean_skel.(cur_joint) = mean(skel.(cur_joint)(frames_to_average, 1:3), 1, 'omitnan');
    catch
        mean_skel.(cur_joint) = [0, 0, 0];
    end
end
end

