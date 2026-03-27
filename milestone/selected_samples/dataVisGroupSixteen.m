function dataVisGroupSixteen(Group)
% dataVisGroupCombined - Combine 8 variables per group into one figure
% Group: struct containing same/diff, dominant/nondominant, IK/ID data

varsAngle  = {'hipFlexionAngle','hipAdductionAngle','hipRotationAngle','kneeFlexionAngle'};
varsMoment = {'hipFlexionMoment','hipAdductionMoment','hipRotationMoment','kneeFlexionMoment'};
time = linspace(0,100,51);

groups = {'same','diff'};
types  = {'IK','ID'};

for g = 1:numel(groups)
    Gname = groups{g};
    figure('Name',sprintf('%s group',upper(Gname)),'Color','w','Position',[100 100 1200 800]);
    
    for t = 1:numel(types)
        TypeStr = types{t};
        if strcmp(TypeStr,'IK')
            varList = varsAngle;
            yLabel = 'Angle [deg]';
        else
            varList = varsMoment;
            yLabel = 'Normlized Moment [Nm/kg]';
        end
        
        for v = 1:numel(varList)
            varName = varList{v};
            subplot(4,2,(t-1)*4 + v); hold on;
            
            % -------- dominant --------
            domCell = Group.(Gname).dominant.(TypeStr);
            domStructAvg = [];
            for s = 1:numel(domCell)
                dDom = domCell{s};
                tmp = [];
                for k = 1:numel(dDom)
                    if isfield(dDom(k),varName)
                        tmp = [tmp; mean(dDom(k).(varName),1)];
                    end
                end
                if ~isempty(tmp)
                    domStructAvg = [domStructAvg; mean(tmp,1)];
                end
            end
            if ~isempty(domStructAvg)
                domMean = mean(domStructAvg,1);
                domStd  = std(domStructAvg,0,1);
            else
                domMean = NaN(1,51);
                domStd  = zeros(1,51);
            end
            
            % -------- non-dominant --------
            nonCell = Group.(Gname).nondominant.(TypeStr);
            nonStructAvg = [];
            for s = 1:numel(nonCell)
                dNon = nonCell{s};
                tmp = [];
                for k = 1:numel(dNon)
                    if isfield(dNon(k),varName)
                        tmp = [tmp; mean(dNon(k).(varName),1)];
                    end
                end
                if ~isempty(tmp)
                    nonStructAvg = [nonStructAvg; mean(tmp,1)];
                end
            end
            if ~isempty(nonStructAvg)
                nonMean = mean(nonStructAvg,1);
                nonStd  = std(nonStructAvg,0,1);
            else
                nonMean = NaN(1,51);
                nonStd  = zeros(1,51);
            end
            
            % -------- plot --------
            if varName == "hipFlexionMoment"
                disp(domMean);
            end

            fill([time fliplr(time)], [domMean+domStd fliplr(domMean-domStd)], ...
                [0.7 0.7 1],'FaceAlpha',0.3,'EdgeColor','none'); 
            plot(time, domMean,'b','LineWidth',2);

            fill([time fliplr(time)], [nonMean+nonStd fliplr(nonMean-nonStd)], ...
                [1 0.7 0.7],'FaceAlpha',0.3,'EdgeColor','none'); 
            plot(time, nonMean,'r','LineWidth',2);

            xlabel('Normalized Pass [%]');
            ylabel(yLabel);
            title(sprintf('%s | %s',TypeStr,varName));
            grid on;
            
            if (t==1 && v==1)
                legend('Dominant ±std','Dominant mean','Non-dominant ±std','Non-dominant mean','Location','best');
            end
        end
    end
end

end
