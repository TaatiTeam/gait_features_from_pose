function [gait_params] = computeFeatsFromFootfalls(skelT, skel_struct, footfall_locs_final, start_is_left)

walk_base = string(skelT.walk_id(1));


% Copying over Becky's work
fps = skelT.fps(1);
start_frame = skelT.start_frame(1);


gait_params=NaN*zeros(1,13);
gait_params(11) = fps;
gait_params(12) = start_frame;

LH = skel_struct.LHip;
RH = skel_struct.RHip;
LF = skel_struct.LAnkle(:,1:2);
RF = skel_struct.RAnkle(:,1:2);

% if start_is_left
%     figure, hold on, plot(LF(:, 2)), plot(RF(:, 2))
%     plot(footfall_locs_final(1:2:end) , LF(footfall_locs_final(1:2:end), 2), '*k')
%     plot(footfall_locs_final(2:2:end) , RF(footfall_locs_final(2:2:end), 2), '*k')
%     
% else
%     
%     figure, hold on, plot(LF(:, 2)), plot(RF(:, 2))
%     plot(footfall_locs_final(1:2:end) , RF(footfall_locs_final(1:2:end), 2), '*k')
%     plot(footfall_locs_final(2:2:end) , LF(footfall_locs_final(2:2:end), 2), '*k')
% end


num_timesteps = size(LH,1);

gait_params(13) = num_timesteps;


LH = fillmissing(LH, 'linear', 1);
RH = fillmissing(RH, 'linear', 1);
LF = fillmissing(LF, 'linear', 1);
RF = fillmissing(RF, 'linear', 1);


try
    norm_factor(:,1)= 1:length(LH);
    norm_factor(:,2)=smooth(sqrt((LH(:,1)-RH(:,1)).^2 + (LH(:,2)-RH(:,2)).^2 )); %This is the hip width
catch
    norm_factor;
end

hip_dist = movmean(norm_factor(:, 2), 20);


locs = footfall_locs_final;


    %calc aCOM
    aCOM(:,1)=1:length(LH);
    aCOM(:,2)=(abs(LH(:,1)-RH(:,1))./2)+RH(:,1);
    
    
    %calculate leg length for MOS calc
    RL = smooth(vecnorm(RH(:, 1:2) - RF(:, 1:2), 2,2) ./norm_factor(:,2));
    LL = smooth(vecnorm(LH(:, 1:2) - LF(:, 1:2), 2,2) ./norm_factor(:,2));
    
    % RL=mean(abs((RH(:,2)-RF(:,2))./norm(:,2)));
    % LL=mean(abs((LH(:,2)-LF(:,2))./norm(:,2)));
    legl=(RL+LL)/2;
    
    omega=sqrt(9.81./legl);
    
    vCOMx(:,1)=1:num_timesteps;
    vCOMx(2:end,2)=diff(aCOM(:,2));
    vCOMx(1,2)=vCOMx(2,2);  % copy value from t=2 to t = 1
    %divide by omega term
    vCOMx(:,2)=vCOMx(:,2)./omega;
    
    XCOM(:,1)=1:num_timesteps;
    XCOM(:,2)=aCOM(:,2)+vCOMx(:,2);
    
%     %normalised precursory eMOS values
%     ll = zeros(num_timesteps, 2);
%     rr = zeros(num_timesteps, 2);
%     for i=1:num_timesteps-1
%         ll(i,1)= i;
%         rr(i,1)= i;
%         ll(i,2)=(LF(i,1)-XCOM(i,2))/norm(i,2);
%         rr(i,2)=(XCOM(i,2)-RF(i,1))/norm(i,2);
%     end
%     
    ll(:, 1) = 1:num_timesteps;
    rr(:, 1) = 1:num_timesteps;

    ll(:,2)=(LF(:,1)-XCOM(:,2))./norm_factor(:,2);
    rr(:,2)=(XCOM(:,2)-RF(:,1))./norm_factor(:,2);
    
    
    
    %filling MOS1 with normalized values for ll and rr, based on step and
    %separating time on each foot
    time1=0;
    time2=0;
    MOS(:,1)=1:length(LH);
    % Right foot takes the first step
    if ~start_is_left
        d=1;
        while d<=length(locs)-1
            if mod(d, 2) == 0 % This assumes that left/right feet alternate
                MOS(locs(d):locs(d+1),2)=ll(locs(d):locs(d+1),2);
                time1=time1+length(locs(d):locs(d+1));
                d=d+1;
            else
                MOS(locs(d):locs(d+1),2)=rr(locs(d):locs(d+1),2);
                time2=time2+length(locs(d):locs(d+1));
                d=d+1;
            end
        end
    end
    if start_is_left
        d=1;
        while d<=length(locs)-1
            if mod(d, 2) == 0
                try
                MOS(locs(d):locs(d+1),2)=rr(locs(d):locs(d+1),2);
                catch
                   fprintf("stop");
                end
                time1=time1+length(locs(d):locs(d+1));
                d=d+1;
            else
                MOS(locs(d):locs(d+1),2)=ll(locs(d):locs(d+1),2);
                time2=time2+length(locs(d):locs(d+1));
                d=d+1;
            end
        end
    end
    
    
    aMOS=MOS(min(locs):max(locs),:);
    
    
    %calc variables for skel 1
    framesofwalk=max(locs)-min(locs);
    stepsofwalk=length(locs)-1;

    
if stepsofwalk > 2
    
    % Cadence
    try
        % If we have the timesteps, just use those
        duration_of_walk = skel_struct.time(max(locs)) - skel_struct.time(min(locs));
        gait_params(1) = stepsofwalk / duration_of_walk * 60;
    catch
        gait_params(1) = (stepsofwalk/framesofwalk)*(fps*60);
    end
    %avg over all MOS
    bMOS=aMOS;
    bMOS(any(bMOS<=0,2),:) = [];
    gait_params(2)=mean(bMOS(:,2));
    
    %min MOS per step
    minMOS=zeros(length(locs)-1,2);
    for i=1:length(locs)-1
        minMOS(i,1)=i;
        mMOS=MOS(locs(i):locs(i+1),2);
        if (length(mMOS(mMOS>0)) > 0)
            minMOS(i,2)=min(mMOS(mMOS>0));
        else
            minMOS(i,2) = 0.001;
        end
    end
    
    gait_params(3)=mean(minMOS(:,2));
    
    
    %find % time out of MOS
    nout = sum(aMOS(:,2)<=0);
    nin = sum(aMOS(:,2)>0);
    gait_params(4)=nout/(nout+nin);
    
    %calc step widths at each stance phase (at locs)
    nw=zeros(length(locs),1);
    for i=1:length(locs)
        nw(i,1)=abs(LF(locs(i),1)-RF(locs(i),1))/norm_factor(locs(i),2);
        % As a sanity check, this shouldn't be more than 3x the hip width
        if (nw(i,1) > 3)
            nw(i,1) =NaN;
        end
        
    end
    
    SWav=mean(nw(:), 'omitnan');
    gait_params(5)=SWav;
    
    %Step Width CV
    SWsd=std(nw(:), 'omitnan');
    gait_params(6)=SWsd/SWav;
    
    
    %Step time CV
    Gs=diff(locs);
    Gssd=std(Gs);
    Gsav=mean(Gs);
    CVst=Gssd/Gsav;
    gait_params(7)=CVst;
    
    %Index of Symmetry for L vs R step time
    SI=abs(((time1-time2)/(0.5*(time1+time2)))*100);
    gait_params(8)=SI;
    gait_params(9)=stepsofwalk;
    
    if (sum(isnan(gait_params)) > 7)
        fprintf('Could not compute any features: %s\n', walk_base);
    end
    

else % two or less steps
    fprintf('Walk too short (two or less steps detected) %s\n', walk_base);
    % Save the skel_id in case we need to reference it in the future
    
    gait_params(9)=stepsofwalk;    
end
    
    
    
    

end

