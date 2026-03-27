clear all;
clc;
close all;

% 读取 .mat 文件  % 你的 .mat 文件路径
ID = load('ID.mat');
IK = load('IK.mat');  

L_list = {};
R_list = {};
L_mean_list = {};
R_mean_list = {};
L_max_list = {};
R_max_list = {};
res_struct_L = struct();
res_struct_R = struct();
% 获取所有字段名
id_fields = fieldnames(ID.id);

for i = 1:length(id_fields)
    fname = id_fields{i};
    idTrail = ID.id.(fname);
    ikTrail = IK.IK.(fname);
    if contains(fname, '_L')   % 名字里含 "_Lxx"
        % dealing ID
        L_list{end+1} = fname;
        [maxResult,avgResult,colStore] = analyzeAndDrawTrail(idTrail.jointmoments);
        L_max_list{end+1} = maxResult;
        L_mean_list{end+1} = avgResult;
        res_struct_L = updateStructID(colStore,res_struct_L);
        % dealing IK
        [maxResult1,avgResult1,colStore1] = analyzeAndDrawTrail(ikTrail.jointangles);  

    elseif contains(fname, '_R')  % 名字里含 "_Rxx"
        R_list{end+1} = fname;
        [maxResult,avgResult,colStore] = analyzeAndDrawTrail(idTrail.jointmoments);
        R_max_list{end+1} = maxResult;
        R_mean_list{end+1} = avgResult;
        res_struct_R = updateStructID(colStore,res_struct_R);
        [maxResult1,avgResult1,colStore1] = analyzeAndDrawTrail(ikTrail.jointangles); 
    end
    
end

disp("L_list length is " + length(L_list))
disp("R_list length is " + length(R_list))
% disp("left res: " + string(L_list))
% disp("right res: " + string(R_list))


function [maxResult,avgResult,colStore] = analyzeAndDrawTrail(trialData)
    % trialData 是一个 struct
    % 每个字段是一列数据
    % 返回 avgResult，其中包含每列的平均值
    colStore = struct();
    col_fields = fieldnames(trialData);
    avgResult = struct();
    maxResult = struct();

    for i = 1:length(col_fields)
        cname = col_fields{i};
        colData = trialData.(cname);
        colStore.(cname) = colData;

        % 跳过非数值字段
        if ~isnumeric(colData)
            warning(['字段 ', cname, ' 不是数值数据，已跳过']);
            continue;
        end

        % 求平均值
        avgValue = mean(colData);
        maxValue = max(colData);

        % 加入输出结构体
        avgResult.(cname) = avgValue;
        maxResult.(cname) = maxValue;

        % 输出到控制台
        % fprintf('%s 的平均值 = %.4f\n', cname, avgValue);
    end
end


function prevCS = updateStructID(newCS, prevCS)
    fields = fieldnames(newCS);
    for i = 1:length(fields)
        key = fields{i};
        value = newCS.(key);
    
        % 如果目标 struct 没有这个 key，则新建
        if ~isfield(prevCS, key)
            prevCS.(key) = {value};  % 用 cell 保存列表
        else
            prevCS.(key){end+1} = value;  % 追加到已有列表
        end
    end
end


function plotStructCurves(dataStruct, titlePrefix, legendList)
    % dataStruct: 结构体，每个字段下是 cell 数组，每个 cell 是一条曲线
    % titlePrefix: 图标题前缀，例如 'Left' 或 'Right'
    
    if nargin < 2
        titlePrefix = '';
    end
    
    keys = fieldnames(dataStruct);
    
    for k = 1:length(keys)
        key = keys{k};
        % if ~ismember(string(key), ["time", "Row", "Variables","Properties"])
        if ismember(string(key), ["hip_flexion_l_moment", "hip_flexion_r_moment" ])
            curveList = dataStruct.(key);  % cell array，每个 cell 是一条曲线
            figure; hold on;
            for t = 1:length(curveList)
                y = curveList{t};          % 当前 trial 的数据
                % x = dataStruct.("time");           % 横坐标
                x = 1:length(y);  
                plot(x, y, 'LineWidth', 1.5);  % 可以修改颜色或样式
            end
            hold off;
            xlabel('Time in index');
            ylabel('Value');
            title([titlePrefix, ' - ', key]);
            legendStrings = strcat('Trial ', string(1:length(curveList)));
            legend(legendStrings, 'Location', 'best');
            grid on;
        end
    end
end

% 左腿数据
plotStructCurves(res_struct_L, 'Left', L_list);

% 右腿数据
plotStructCurves(res_struct_R, 'Right', R_list);



% From Alex: ROM scalars(overall ROM, timing of max/min angles in all
% planes,)  and the wave form of hip kinematic