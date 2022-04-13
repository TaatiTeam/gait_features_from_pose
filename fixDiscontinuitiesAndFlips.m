function configs= fixDiscontinuitiesAndFlips(configs)

tic
configs = fixDiscontinuities(configs);
toc
configs = fixFlips(configs);




end

