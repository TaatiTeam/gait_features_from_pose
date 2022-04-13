function [conf_thres] = getConfThres(detector)

if strcmp(detector, "openpose")
    conf_thres = 30;
elseif strcmp(detector, "detectron")  % Detectron
    conf_thres = 15;
elseif strcmp(detector, "alphapose")
    conf_thres = 50;
else
    conf_thres = 0;
end

end
