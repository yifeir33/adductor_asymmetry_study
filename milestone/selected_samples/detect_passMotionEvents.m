function [events, F, normData, maxVals] = detect_passMotionEvents(MT5marker, angles, moments, passingLeg, videoFrq, passName, plotResults)
MT5marker = MT5marker * 1000; 
% angles
hipFlexionAngle = angles.(['hip_flexion_', lower(passingLeg)]);
kneeFlexionAngle = angles.(['knee_angle_', lower(passingLeg)]);

hipAdductionAngle = angles.(['hip_adduction_', lower(passingLeg)]);
hipRotationAngle = angles.(['hip_rotation_', lower(passingLeg)]);


% moments
leg = lower(passingLeg);
hipMomentField = sprintf('%s_%s_moment', 'hip_flexion', leg);
kneeMomentField = sprintf('%s_%s_moment', 'knee_angle', leg);
 
hipMomentFieldAdduction = sprintf('%s_%s_moment', 'hip_adduction', leg);
hipMomentFieldRotation = sprintf('%s_%s_moment', 'hip_rotation', leg);


hipFlexionMoment = moments.([hipMomentField]);
kneeFlexionMoment = moments.([kneeMomentField]);
hipAdductionMoment = moments.([hipMomentFieldAdduction]);
hipRotationMoment = moments.([hipMomentFieldRotation]);


verticalCol = 2;  % Y 轴是垂直方向
TOEOFF = 20; % 3.5cm uber baselineHoehe MT5marker waehrend stance
passEvent = videoFrq * 1.5; % 1.5s vor Pass ist Start (To do: besser detektieren)     
% max Knee Flexion (end of leg-cocking, start of leg-acceleration)
[~, kneeFlexPeakIdx] = findpeaks(kneeFlexionAngle(1:passEvent));
events.maxKneeFlex = kneeFlexPeakIdx(end);
% max Hip Extension (end of back-swing, start of leg-cocking)
for i = events.maxKneeFlex:-1:2
    if hipFlexionAngle(i) < hipFlexionAngle(i-1)
        events.maxHipExt = i;
        break
    end
end
% markeroffseif global origin not on ground
if min(MT5marker(:,verticalCol)) > 40
    MT5marker(:,verticalCol) = MT5marker(:,verticalCol) - min(MT5marker(:,verticalCol));
end
% Toe-Off als Start fuer Backswing
ff = find(MT5marker(1:events.maxHipExt, verticalCol) < 45);
if isempty(ff)
    warning('No frames below 45 mm. Using maxHipExt as fallback.');
    toeOff_temp(1,2) = events.maxHipExt;   % 用 maxHipExt 作为备选
else
    toeOff_temp(1,2) = ff(end);
end
ff = find(MT5marker(1:toeOff_temp(1,2), verticalCol) > 45);
if isempty(ff)
    warning('No frames above 45 mm. Using toeOff_temp(1,2) as fallback.');
    toeOff_temp(1,1) = toeOff_temp(1,2);   % 或者其他合理值
else
    toeOff_temp(1,1) = ff(end);
end
midStance = round((toeOff_temp(2) + toeOff_temp(1))/2);
baselineHeightMT5 = mean(MT5marker(midStance-5:midStance+5,verticalCol));
ff = find(MT5marker(1:events.maxHipExt, verticalCol) < (baselineHeightMT5+TOEOFF));
events.toeOff = ff(end);
% Ball Impact
for i = events.maxKneeFlex:length(MT5marker(:,verticalCol))-1
    if MT5marker(i,verticalCol) < MT5marker(i+1,verticalCol)
        events.ballImpact = i;
        break
    end
end
% 
% [~, highestFootIdx] = max(MT5marker(events.maxKneeFlex:end,3));
% highestFootIdx = highestFootIdx + events.maxKneeFlex;
% [~,lowestFootIdx] = min(MT5marker(events.maxKneeFlex:highestFootIdx,3));
% lowestFootIdx = lowestFootIdx + events.maxKneeFlex;
% events.ballImpact = lowestFootIdx;
events = orderfields(events,{'toeOff','maxHipExt','maxKneeFlex','ballImpact'});

% Plots 2 check
if plotResults
    F = figure("position",[200,100,1200,600]);
    tiledlayout(2,1)
    nexttile
    plot(hipFlexionAngle,'k'); hold on; plot(kneeFlexionAngle,'r'); title('joint angles');
    xline([events.toeOff events.maxHipExt events.maxKneeFlex events.ballImpact],'-',fieldnames(events))
    xlim([200 length(MT5marker(:,1))])
    ylabel('[°]')
    legend({'hip','knee'})
    nexttile    
    plot(MT5marker(:,verticalCol)); title('CALCN height');
    xline([events.toeOff events.maxHipExt events.maxKneeFlex events.ballImpact],'-',fieldnames(events))
    xlim([200 length(MT5marker(:,1))])
    xlabel('frames at 240Hz')
    ylabel('[mm]')
    sgtitle(passName,'Interpreter','none')
else
    F = "set plotResults = 1 if you want to plot the results";

end

data.hipFlexionAngle  = hipFlexionAngle;
data.kneeFlexionAngle = kneeFlexionAngle;
data.hipAdductionAngle = hipAdductionAngle;
data.hipRotationAngle = hipRotationAngle;

data.hipFlexionMoment = hipFlexionMoment;
data.kneeFlexionMoment = kneeFlexionMoment;
data.hipAdductionMoment = hipAdductionMoment;
data.hipRotationMoment = hipRotationMoment;

[normData, maxVals] = interpWithEvent(events, data);

% [hip_norm_IK, knee_norm_IK, hip_norm_ID, knee_norm_ID, maxVal] = interpWithEvent(events,hipFlexionAngle,kneeFlexionAngle,hipAdductionAngle,hipRotationAngle,hipFlexionMoment,kneeFlexionMoment, hipAdductionMoment, hipRotationMoment);


% 传球动作被划分为几个关键事件：

% 最大膝屈曲 (maxKneeFlex)
% 
% 取传球前 1.5 秒范围内的膝关节角度，找峰值。
% 
% 这个峰值对应 腿回摆结束，开始腿加速。
% 
% 最大髋伸展 (maxHipExt)
% 
% 从 maxKneeFlex 向前遍历，找到髋角度下降的拐点。
% 
% 对应 回摆阶段结束。
% 
% Toe-Off（脚尖离地）
% 
% 根据 MT5 marker 垂直方向（Y轴），找高度低于 45 mm 的最后一帧。
% 
% 如果找不到，则用 maxHipExt 作为备选。
% 
% 这个事件是 腿回摆的起点。
% 
% Ball Impact（击球时刻）
% 
% 从 maxKneeFlex 到最后一帧，找到 MT5 marker 由下降到上升的拐点。
% 
% 对应 球被脚踢出。
% 
% 处理marker偏移
% 
% 如果 MT5 marker 全部高度 > 40 mm（global origin 不在地面），对高度归零。