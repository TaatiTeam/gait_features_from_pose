function [] = plotXPositions(skel, outputfile)

joints = {"Shoulder", "Elbow", "Wrist", "Eye", "Hip", "Knee", "Ankle", "Ear"};

fig = figure('visible','off', 'units','normalized','outerposition',[0 0 1 1]); hold on
set(0, 'CurrentFigure', fig)

if (mod(length(joints), 2) == 0)
    plot_width = length(joints) / 2;
    
else
    plot_width = cast(length(joints) / 2, 'uint8');
    plot_width = cast(plot_width, 'double');
end

for j = 1:length(joints)
    subplot(2,plot_width,j), hold on,
    joint = joints{j};
    plot(skel.("L" + joint)(:, 1)), plot(skel.("R" + joint)(:, 1))
    title(joint + " Horizontal Position")
    
end
legend("Left" , "Right");

saveas(gcf,outputfile)
close all
end

