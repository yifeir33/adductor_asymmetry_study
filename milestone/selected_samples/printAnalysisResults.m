function printAnalysisResults(Results)
% printAnalysisResults - Print Wilcoxon results for all groups and variables
%
% INPUT:
%   Results - output from AnalysisGroup

groups = fieldnames(Results);

fprintf('\n================ Wilcoxon Analysis Summary ================\n');
fprintf('Group\tType\tVariable\tp-value\tSignificant\n');

for g = 1:numel(groups)
    Gname = groups{g};
    types = fieldnames(Results.(Gname));
    
    for t = 1:numel(types)
        TypeStr = types{t};
        vars = fieldnames(Results.(Gname).(TypeStr));
        
        for v = 1:numel(vars)
            varName = vars{v};
            res = Results.(Gname).(TypeStr).(varName);
            
            sigStr = 'No';
            if res.h == 1
                sigStr = 'Yes';
            end
            
            fprintf('%s\t%s\t%s\t%.4f\t%s\n', upper(Gname), TypeStr, varName, res.p_value, sigStr);
        end
    end
end

fprintf('==========================================================\n\n');
end
