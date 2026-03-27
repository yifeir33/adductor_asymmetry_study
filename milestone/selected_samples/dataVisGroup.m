function dataVisGroup(Group)
vars = {'hip','knee'};
yLabels = {'Angle (deg)','Moment (Nm)','Angle (deg)','Moment (Nm)'};

% 线条颜色
colors = [ ...
    0.00 0.45 0.70;   % 蓝色        Same · Dominant
    0.90 0.62 0.00;   % 橙色        Same · Non-dominant
    0.00 0.62 0.45;   % 蓝绿色      Diff · Dominant
    0.80 0.20 0.55];  % 紫红色      Diff · Non-dominant

alphaVal = 0.25;   % shadow 稍微明显一点

figure('Position',[100 100 1200 900])

for v = 1:2 % hip/knee
    % ------------------ Angle ------------------
    subplot(2,2,v); hold on
    x = linspace(0,100, size(Group.same.dominant.IK{1}.(vars{v}),2));
    plotFourLinesCell(Group, vars{v}, x, 'IK', colors, alphaVal)
    xlabel('Pass cycle (%)'); ylabel('Angle (deg)')
    title([vars{v} ' flexion angle']); grid on

    % ------------------ Moment ------------------
    subplot(2,2,v+2); hold on
    x = linspace(0,100, size(Group.same.dominant.ID{1}.(vars{v}),2));
    plotFourLinesCell(Group, vars{v}, x, 'ID', colors, alphaVal)
    xlabel('Pass cycle (%)'); ylabel('Moment (Nm)')
    title([vars{v} ' flexion moment']); grid on
end

end

%% ================== plotFourLinesCell ==================
function plotFourLinesCell(Group, varName, x, typeStr, colors, alphaVal)
% 绘制四条线： same/diff × dominant/nondominant
linesNames = {'Same Dom','Same NonDom','Diff Dom','Diff NonDom'};
dataFields = {'same','diff'};
legFields  = {'dominant','nondominant'};

hPlot = gobjects(4,1); % 用于 legend

for f = 1:2
    for l = 1:2
        % 获取 cell 数组
        dataCell = Group.(dataFields{f}).(legFields{l}).(typeStr);

        allTrials = [];
        % 拼接每个 player 的数据
        for p = 1:numel(dataCell)
            d = dataCell{p};
            if isfield(d,varName)
                allTrials = [allTrials; d.(varName)];
            end
        end

        if isempty(allTrials)
            continue
        end

        % 平均 ± SD
        meanLine = mean(allTrials,1);
        sdLine   = std(allTrials,[],1);

        % 阴影
        fill([x fliplr(x)], [meanLine+sdLine fliplr(meanLine-sdLine)], ...
            colors((f-1)*2 + l,:), 'FaceAlpha',alphaVal, 'EdgeColor','none');

        % 平均线
        hPlot((f-1)*2 + l) = plot(x, meanLine,'Color',colors((f-1)*2 + l,:),'LineWidth',2);
    end
end

% 添加 legend
legend(hPlot, linesNames,'Location','best')
end
