function [labels] = dbscan_st(points, times, eps_spatial, eps_temporal, min_pts)
%     MATLAB implementation of dbscan_st from https://github.com/ajhynes7/side-view-depth-gait/
%     Cluster points with spatiotemporal DBSCAN algorithm.
%
%     Parameters
%     ----------
%     points : (N, D) array_like
%         Array of N points with dimension D.
%     times : (N,) array_like, optional
%         Array of N times corresponding to the points.
%     eps_spatial : float, optional
%         Maximum distance between two points for one to be
%         considered in the neighbourhood of the other.
%     eps_temporal : float, optional
%         Maximum distance between two times for one to be
%         considered in the neighbourhood of the other.
%     min_pts : int, optional
%         Number of points in a neighbourhood for a point to be considered
%         a core point.
%
%     Returns
%     -------
%     labels : (N,) ndarray
%         Array of cluster labels.
%
%     Examples
%     --------
%     >>> points = [[0, 0], [1, 0], [2, 0], [0, 5], [1, 5], [2, 5]]
%
%     >>> dbscan_st(points, eps_spatial=1, min_pts=2)
%     array([0, 0, 0, 1, 1, 1])

arguments
    points (1,:) double
    times (1,:) double
    eps_spatial (1,1) double = 5
    eps_temporal (1,1) double = 0.3
    min_pts (1,1) double = 5
end

% Pairwise distance between points
D_spatial = pdist2(points', points');
D_temporal = pdist2(times', times');

n_points = length(points);


labels = zeros(1, n_points);
label_cluster = 0;

for idx_pt = 1:n_points
    if labels(idx_pt) ~= 0
        % Only unlabelled points can be considered as seed points.
        continue
    end
    
    set_neighbours = region_query_st(D_spatial, D_temporal, eps_spatial, eps_temporal, idx_pt);
    
    if length(set_neighbours) < min_pts
        % The neighbourhood of the point is smaller than the minimum.
        % The point is marked as noise.
        
        labels(idx_pt) = -1;
        
    else
        label_cluster = label_cluster + 1;
        % Assign the point to the current cluster
        labels(idx_pt) = label_cluster;
        
        labels = grow_cluster_st(D_spatial, D_temporal, labels, set_neighbours, label_cluster, eps_spatial, eps_temporal, min_pts);
        
    end
    
    
    
end



end

function [neighbours] = region_query(dist_matrix, eps, idx_pt)
% Find all points in the dist_matrix that are less than eps from idx_pt
cur_ind_dists = dist_matrix(:, idx_pt);
neighbours = find(cur_ind_dists <= eps);

end

function [neighbours] =  region_query_st(D_spatial, D_temporal, eps_spatial, eps_temporal, idx_pt)
set_neighbours_spatial = region_query(D_spatial, eps_spatial, idx_pt);
set_neighbours_temporal = region_query(D_temporal, eps_temporal, idx_pt);

neighbours = intersect(set_neighbours_spatial, set_neighbours_temporal);
end

function [labels] = grow_cluster_st(D_spatial, D_temporal, labels, set_neighbours, label_cluster, eps_spatial, eps_temporal, min_pts)
% Initialize queue with the current neighbourhood
queue_search = set_neighbours;

while ~isempty(queue_search)
    % Get the first element from the queue
    idx_next = queue_search(1);
    try
        queue_search = queue_search(2:end);
    catch
        queue_search = [];
    end
    
    
    label_next = labels(idx_next);
    
    if label_next == -1
        % This neighbour was labelled as noise.
        % It is now a border point of the cluster.
        labels(idx_next) = label_cluster;
    elseif label_next == 0
        % The neighbour was unclaimed.
        % Add the next point to the cluster.
        
        labels(idx_next) = label_cluster;
        set_neighbours_next = region_query_st(D_spatial, D_temporal, eps_spatial, eps_temporal, idx_next);
        
        if length(set_neighbours_next) >= min_pts
            % The next point is a core point.
            % Add its neighbourhood to the queue to be searched.
            for i=1:length(set_neighbours_next)
                queue_search = [queue_search; set_neighbours_next(i)];
            end
            
        end
    end
    
    
    
    
end

end



