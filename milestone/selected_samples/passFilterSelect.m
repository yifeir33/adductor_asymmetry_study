clc; clear; close all;

%% 获取当前路径
rootPath = pwd;

% 获取当前路径下所有内容
dirInfo = dir(rootPath);

%% dominant map
disp("dominant map");
dominant_map = containers.Map({'P02_202311','P32_202403','P34_202311', ...
    'P53_202308','P64_202311','P74_202403','P88_202411'}, ...
    {'R','R','R','R','R','L','L'} );

cellfun(@(k,v) fprintf('%s -> %s\n',k,v), dominant_map.keys, dominant_map.values);

%% 打开 log 文件
logFile = fullfile(rootPath, 'delete_log.txt');
fid = fopen(logFile, 'w');
fprintf(fid, 'Pass 删除记录\n');
fprintf(fid, '====================\n\n');

%% 遍历每个文件夹
for i = 1:length(dirInfo)
    % 只处理文件夹，且排除 . 和 ..
    if dirInfo(i).isdir && ~strcmp(dirInfo(i).name, '.') && ~strcmp(dirInfo(i).name, '..')

        folderPath = fullfile(rootPath, dirInfo(i).name);

        % 构造 mat 文件路径
        ID_path = fullfile(folderPath, 'ID.mat');
        IK_path = fullfile(folderPath, 'IK.mat');

        % 判断文件是否存在
        if exist(ID_path, 'file') && exist(IK_path, 'file')
            fprintf('正在加载：%s\n', folderPath);

            playerId = folderPath(end-9:end);
            ID = load(ID_path);
            IK = load(IK_path);

            % 对数据进行裁剪 -1.5s before 0.5s after the pass
            videoFreq = 240;
            dominant_side = dominant_map(playerId);

            % 调用 selectPass，同时传入 log 文件和 playerId
            [newID, newIK] = selectPass(ID, IK, dominant_side, videoFreq, fid, playerId);

            % 构造保存路径
            newID_path = fullfile(folderPath, 'ID_new.mat');
            newIK_path = fullfile(folderPath, 'IK_new.mat');

            % 保存修改后的数据
            ID = newID;
            IK = newIK;
            save(newID_path, 'ID');
            save(newIK_path, 'IK');

            fprintf('已保存：%s 和 %s\n', 'ID_new.mat', 'IK_new.mat');
        else
            fprintf('缺少文件：%s\n', folderPath);
        end
    end
end

%% 关闭 log 文件
fclose(fid);
disp('删除记录已保存到 delete_log.txt');

%% ========================== selectPass 函数 ==========================
function [newID, newIK] = selectPass(ID, IK, dominant_side, videoFreq, fid, playerId)

newID = ID;
newIK = IK;

fprintf(fid, 'Player: %s\n', playerId);

% 获取所有 pass label
passLabels = fieldnames(IK.IK);

for i = 1:numel(passLabels)

    labelName = passLabels{i};

    fprintf('\n============================\n');
    fprintf('正在检查 pass: %s\n', labelName);

    pass = IK.IK.(labelName);
    passID = ID.id.(labelName);

    % calcn marker
    left_calc = {'calcn_l_X','calcn_l_Y','calcn_l_Z'};
    right_calc = {'calcn_r_X','calcn_r_Y','calcn_r_Z'};

    % 判断左右脚
    if contains(labelName, '_L')
        passing_side = 'L';
        calcVars = left_calc;
    elseif contains(labelName, '_R')
        passing_side = 'R';
        calcVars = right_calc;
    else
        error('labelName %s does not end with L or R', labelName);
    end

    % 获取 calcn 数据
    try
        calcnPos = pass.COM.pos(:, calcVars);
        calcnPosMat = table2array(calcnPos);
    catch
        warning('找不到 calcn marker: %s', labelName);
        fprintf(fid, '   删除: %s (找不到 marker)\n', labelName);
        continue;
    end

    % ===== 调用检测函数（会画图）=====
    try
        [events, F, normData, maxVals] = detect_passMotionEvents( ...
            calcnPosMat, ...
            pass.jointangles, ...
            passID.jointmoments, ...
            passing_side, ...
            videoFreq, ...
            labelName, ...
            1);
    catch ME
        warning('detect_passMotionEvents 出错: %s', ME.message);
        fprintf(fid, '   删除: %s (detect 出错)\n', labelName);
        continue;
    end

    % ===== 人工选择 =====
    keepFlag = input('保留这个 pass? (y=保留, n=删除): ','s');
    
    if ~strcmpi(keepFlag,'y')
        
        % IK 删除
        if isfield(newIK.IK, labelName)
            newIK.IK = rmfield(newIK.IK, labelName);
        end
        
        % ID 删除
        if isfield(newID.id, labelName)
            newID.id = rmfield(newID.id, labelName);
        end
    
        fprintf('已删除 %s\n', labelName);
        fprintf(fid, '   删除: %s\n', labelName);
    
    else
        fprintf('已保留 %s\n', labelName);
    end
   
    % 关闭所有图像防止内存爆炸
    close all force;
    drawnow;

end

fprintf(fid, '\n'); % 每个 player 后加空行

end