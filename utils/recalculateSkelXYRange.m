function [skel] = recalculateSkelXYRange(skel, is_kinect, is_3d, detector)
% This function recomputes the x and y extrema of the skeleton. This is
% needed if we directly changed some data in the skel struct but didn't
% recompute the xy ranges. 

fields = getSkelFields(is_kinect, detector);


x_block = [];
y_block = [];
z_block = [];


for f = 1:length(fields)
    field = fields{f};
  
    x_block = [x_block, skel.(field)(:, 1)];
    y_block = [y_block, skel.(field)(:, 2)];
    
    if is_3d
        z_block = [z_block, skel.(field)(:, 3)];   
    end
end

skel.x_range = [min(x_block,[],2), max(x_block,[],2)];
skel.y_range = [min(y_block,[],2), max(y_block,[],2)];

if is_3d
    skel.z_range = [min(z_block,[],2), max(z_block,[],2)];
end


end

