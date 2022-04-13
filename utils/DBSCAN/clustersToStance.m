function [stances, footfalls] = clustersToStance(signal, times, labels, foot, strel_size, start_ind, end_ind)
if ~exist('strel_size', 'var')
    strel_size = 2;
end

if ~exist('start_ind', 'var')
    start_ind = 1;
end

if ~exist('end_ind', 'var')
    end_ind = size(signal, 1);
end

labels = labels';
footfalls = [];
stances = [];
labels_q = unique(labels);
for i = 1:length(labels_q)
    cur_label = labels_q(i);
    if cur_label < 0
        continue;
    end
    cur_stance = signal(labels == cur_label, :);
    stance_inds = find(labels == cur_label);
    
    % Create binary mask for if each timestep belongs to this cluster
    mask = zeros(1, length(labels));
    mask(labels == cur_label) = 1;
    
    mask_clean = imopen(mask, strel('line', strel_size, 0));
    
    cur_stance = signal(mask_clean == 1, :);
    stance_inds = find(mask_clean == 1);
    
    cur_stance_struct = struct();
    cur_stance_struct.first = min(stance_inds);
    cur_stance_struct.last = max(stance_inds);
    cur_stance_struct.mean_position = mean(cur_stance);
    cur_stance_struct.side = foot;
    cur_stance_struct.length = cur_stance_struct.last - cur_stance_struct.first;
    
    % If this stance is in the region of the walk we're interested in,
    % append to stances
    try
        if (cur_stance_struct.first >= start_ind && cur_stance_struct.first <= end_ind)
            stances = [stances, cur_stance_struct];
            footfalls = [footfalls, cur_stance_struct.first];
            
        end
    catch
    end
end


end