function [IDL, IKL, IDR, IKR] = dataVis(ID, IK, dirInfo)

L_list = {};
R_list = {};
L_mean_list = {};
R_mean_list = {};
L_max_list = {};
R_max_list = {};
% ID left pass sturct
ID_struct_L = struct();
% ID right pass struct
ID_struct_R = struct();
% IK left pass struct
IK_struct_L = struct();
% IK right pass sturct
IK_struct_R = struct();
% 获取所有字段名  all features
id_fields = fieldnames(ID.id);
ik_fields = fieldnames(IK.IK);

% dealing id
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
        ID_struct_L = updateStruct(colStore,ID_struct_L);
        

    elseif contains(fname, '_R')  % 名字里含 "_Rxx"
        % dealing ID
        R_list{end+1} = fname;
        [maxResult,avgResult,colStore] = analyzeAndDrawTrail(idTrail.jointmoments);
        R_max_list{end+1} = maxResult;
        R_mean_list{end+1} = avgResult;
        ID_struct_R = updateStruct(colStore,ID_struct_R);
    end
    
end


% dealing ik

for i = 1:length(ik_fields)
    fname = ik_fields{i};
    ikTrail = IK.IK.(fname);
    if contains(fname, '_L')   % 名字里含 "_Lxx"
        [maxResult1,avgResult1,colStore1] = analyzeAndDrawTrail(ikTrail.jointangles); 
        IK_struct_L = updateStruct(colStore1,IK_struct_L);
    elseif contains(fname, '_R')  % 名字里含 "_Rxx"
        % dealing IK
        [maxResult1,avgResult1,colStore1] = analyzeAndDrawTrail(ikTrail.jointangles); 
        IK_struct_R = updateStruct(colStore1,IK_struct_R);
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
            % warning(['字段 ', cname, ' 不是数值数据，已跳过']);
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


function prevCS = updateStruct(newCS, prevCS)
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


    function plotStructCurves(ID_Struct, IK_Struct, titlePrefix, legendList, injury_side)
    % dataStruct: 结构体，每个字段下是 cell 数组，每个 cell 是一条曲线
    % titlePrefix: 图标题前缀，例如 'Left' 或 'Right'
   
    if nargin < 2
        titlePrefix = '';
    end
    
    
    id_keys_l = ["hip_flexion_l_moment", "hip_adduction_l_moment", "hip_rotation_l_moment"];
    ik_keys_l = ["hip_flexion_l", "hip_adduction_l", "hip_rotation_l"];
    id_keys_r = ["hip_flexion_r_moment", "hip_adduction_r_moment","hip_rotation_r_moment"];
    ik_keys_r = ["hip_flexion_r", "hip_adduction_r", "hip_rotation_r"];

    force_features = ["flexion_force", "adduction_force", "rotation_force"];
    % first left then right
    
    % draw left
    % index_l = 1:2:6; % index left
    % index_r = 2:2:6; % index right
    figure;
    for i = 0:2
        if injury_side == "L"
            ik_f = ik_keys_l(i+1);
            id_f = id_keys_l(i+1);
        else
            ik_f = ik_keys_r(i+1);
            id_f = id_keys_r(i+1);
        end

        force_f = force_features(i+1);
        subplot(3,3,i*3+1);
        angle_curve = IK_Struct.(ik_f);
        drawAngle(angle_curve, ik_f);

        subplot(3,3,i*3 +2);
        moment_curve = ID_Struct.(id_f);
        drawMoment(moment_curve, id_f);

        subplot(3,3,i*3+3);
        % force_curve = cellfun(@(a,m) a .* m, angle_curve, moment_curve, ...
        %       'UniformOutput', false);
        % drawForce(force_curve,force_f);

    end
    % figure;
    % % draw right 
    % for i = 0:2
    %     ik_f = ik_features(index_r(i+1));
    %     id_f = id_features(index_r(i+1));
    %     force_f = force_features(i+1);
    % 
    %     subplot(3,3,i*3+1);
    %     angle_curve = IK_Struct.(ik_f);
    %     drawAngle(angle_curve, ik_f);
    % 
    %     subplot(3,3,i*3 +2);
    %     moment_curve = ID_Struct.(id_f);
    %     drawMoment(moment_curve, id_f);
    % 
    %     subplot(3,3,i*3 +3);
    %     % force_curve = cellfun(@(a,m) a .* m, angle_curve, moment_curve, ...
    %     %               'UniformOutput', false);
    %     % drawForce(force_curve,force_f);
    % 
    % end


    function drawAngle(curveList, title_pre)
        cla; hold on; box on;
        x = linspace(0, 100, length(curveList{1}));   % swing phase percentage
        for t = 1:length(curveList)
            y = curveList{t};          % 当前 trial 的数据
            % x = dataStruct.("time");           % 横坐标
            plot(x, y, 'LineWidth', 1.5);% 可以修改颜色或样式
            hold on;
        end
        
        % ===== Angle plot =====
        dataMat = cell2mat(curveList); 
        meanAngle = mean(dataMat, 2);
        stdAngle = std(dataMat, 0, 2);
        
        % std 阴影
        fill([x fliplr(x)], ...
             [meanAngle+stdAngle; flipud(meanAngle-stdAngle)], ...
             [0.8 0.8 1], ...
             'EdgeColor','none', 'FaceAlpha',0.4);
        
        % 平均曲线
        plot(x, meanAngle, 'b', 'LineWidth', 2);
        title(title_pre);
        xlabel('Swing Phase Percentage (%)');
        ylabel('Angle (degree)');
        grid on;
        end

    function drawMoment(curveList, title_pre)
        x = linspace(0, 100, length(curveList{1}));
        cla; hold on; box on;
        % for t = 1:length(curveList)
        %     y = curveList{t};          % 当前 trial 的数据
        %     % x = dataStruct.("time");           % 横坐标
        %     x = 1:length(y);  
        %     plot(x, y, 'LineWidth', 1.5);% 可以修改颜色或样式
        %     hold on;
        % end
        
    % ===== Moment plot =====
    
    dataMat = cell2mat(curveList); 
    meanMoment = mean(dataMat, 2);
    stdMoment = std(dataMat, 0, 2);
    
    
    % std 阴影
    fill([x fliplr(x)], ...
         [meanMoment+stdMoment; flipud(meanMoment-stdMoment)], ...
         [1 0.8 0.8], ...
         'EdgeColor','none', 'FaceAlpha',0.4);
    hold on;
    
    % 平均曲线
    plot(x, meanMoment, 'r', 'LineWidth', 2);
    
    xlabel('Swing Phase Percentage (%)');
    ylabel('Moment (Nm)');
    title( title_pre);
    grid on;
    end

    function drawForce(curveList, title_pre)
        cla; hold on; box on;
    dataMat = cell2mat(curveList); 
    % ===== Force plot =====
    x = linspace(0, 100, length(curveList{1}));
    
    meanForce = mean(dataMat, 2);
    stdForce  = std(dataMat, 0, 2);
    
    % std 阴影
    fill([x fliplr(x)], ...
         [meanForce+stdForce; flipud(meanForce-stdForce)], ...
         [0.8 1 0.8], ...
         'EdgeColor','none', 'FaceAlpha',0.4);
    
    % 平均曲线
    plot(x, meanForce, 'g', 'LineWidth', 2);
    
    xlabel('Swing Phase Percentage (%)');
    ylabel('Force (N)');
    title(title_pre);
    grid on

    end
end


% 左腿数据 看左脚触球
plotStructCurves(ID_struct_L, IK_struct_L, 'Left', L_list, "L");

% 右腿数据 看右脚触球
plotStructCurves(ID_struct_R, IK_struct_R, 'Right', R_list, "R");

IDL = ID_struct_L;
IKL = IK_struct_L;
IDR = ID_struct_R;
IKR = IK_struct_R;


% From Alex: ROM scalars(overall ROM, timing of max/min angles in all
% planes,)  and the wave form of hip kinematic

end