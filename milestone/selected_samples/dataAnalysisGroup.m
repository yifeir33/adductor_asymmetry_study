function Stats = dataAnalysisGroup(Group, alpha)
% AnalysisGroup - single-sample Wilcoxon signed-rank test for dom vs nondom
%
% For each variable, for same/diff groups:
%   1. 每个人对每个变量求平均曲线（51点）
%   2. 每个人得到一条平均曲线
%   3. 对 dominant - nondominant 差值，做 single-sample Wilcoxon signed-rank test
%
% Usage:
%   Stats = AnalysisGroup(Group, 0.05);

if nargin < 2
    alpha = 0.05;
end

varsAngle  = {'hipFlexionAngle','hipAdductionAngle','hipRotationAngle','kneeFlexionAngle'};
varsMoment = {'hipFlexionMoment','hipAdductionMoment','hipRotationMoment','kneeFlexionMoment'};

groups = {'same','diff'};
types  = {'IK','ID'};

Stats = struct();

fprintf('\n================= ANALYSIS GROUP =================\n');
fprintf('Single-sample Wilcoxon test (dominant - non-dominant), alpha = %.2f\n', alpha);

for g = 1:numel(groups)
    Gname = groups{g};
    fprintf('\n===== GROUP: %s =====\n', upper(Gname));

    for t = 1:numel(types)
        TypeStr = types{t};
        if strcmp(TypeStr,'IK')
            varList = varsAngle;
        else
            varList = varsMoment;
        end

        for v = 1:numel(varList)
            varName = varList{v};

            % -----------------------------
            % Collect per-subject averages
            % -----------------------------
            domCell = Group.(Gname).dominant.(TypeStr);
            nonCell = Group.(Gname).nondominant.(TypeStr);

            nDom = numel(domCell);
            nNon = numel(nonCell);

            domAvg = NaN(nDom,51);
            for s = 1:nDom
                dStruct = domCell{s};
                if isfield(dStruct,varName)
                    domAvg(s,:) = mean(dStruct.(varName),1); % 每个 subject 的平均曲线
                end
            end

            nonAvg = NaN(nNon,51);
            for s = 1:nNon
                nStruct = nonCell{s};
                if isfield(nStruct,varName)
                    nonAvg(s,:) = mean(nStruct.(varName),1); % 每个 subject 的平均曲线
                end
            end

            % -----------------------------
            % Compute difference per subject
            % -----------------------------
            % 注意：如果 nDom != nNon，需要保证按 subject 匹配
            % 假设 dominant/non-dominant 对应同一个人

            nSubj = min(nDom,nNon);
            diffMat = domAvg(1:nSubj,:) - nonAvg(1:nSubj,:); % nSubj x 51

            % Flatten所有51个点的每个人均值 -> 对每个 subject 做平均
            % 得到 nSubj x 1 向量
            diffPerSubj = median(diffMat,2);

            % -----------------------------
            % Wilcoxon single-sample signed-rank test
            % -----------------------------
            % [p,h,stats] = signrank(diffPerSubj, 0, 'alpha', alpha);
            [p,h,stats] = signrank(diffMat(:), 0, 'alpha', alpha);

            % -----------------------------
            % Store results
            % -----------------------------
            results.alpha = alpha;
            results.p_value = p;
            results.h = h;
            results.signedrank = stats.signedrank;
            results.n = nSubj;
            results.median_diff = median(diffPerSubj);
            results.mean_diff = mean(diffPerSubj);
            results.std_diff = std(diffPerSubj);

            Stats.(Gname).(TypeStr).(varName) = results;

            % -----------------------------
            % Print summary
            % -----------------------------
            fprintf('\n%s | %s | %s\n', upper(Gname), TypeStr, varName);
            fprintf('Subjects: %d\n', nSubj);
            fprintf('Median difference: %.3f\n', results.median_diff);
            fprintf('Mean ± SD difference: %.3f ± %.3f\n', results.mean_diff, results.std_diff);
            fprintf('p-value: %.4f -> %s\n', results.p_value, ternary(h==1,'Significant','Not Significant'));
        end
    end
end

fprintf('\n================= DONE =================\n');

end

% -----------------------------
function out = ternary(cond,valTrue,valFalse)
% 简单三元选择
if cond
    out = valTrue;
else
    out = valFalse;
end
end
