clc; clear;close all;

% 获取当前路径
rootPath = pwd;

% 获取当前路径下所有内容
dirInfo = dir(rootPath);

disp("injury map")
injury_map = containers.Map({'P02_202311','P32_202403','P34_202311', ...
    'P53_202308','P64_202311','P74_202403','P88_202411'}, {'R','R','L','L','R','L','L'} );

disp("weight map")
weight_map = containers.Map({'P02_202311','P32_202403','P34_202311', ...
    'P53_202308','P64_202311','P74_202403','P88_202411'}, {35.9,42.5,50.8,63.2,68.2,62.4,68.9} );

cellfun(@(k,v) fprintf('%s -> %s\n',k,v), injury_map.keys, injury_map.values);
disp("dominant map");
% the foot with more touches is defaulted preferred foot
dominant_map = containers.Map({'P02_202311','P32_202403','P34_202311', ...
    'P53_202308','P64_202311','P74_202403','P88_202411'}, {'R','R','R','R','R','L','L'} );
cellfun(@(k,v) fprintf('%s -> %s\n',k,v), dominant_map.keys, dominant_map.values);

disp("Compare injury map and dominant map")

% 取两个 map 的公共 keys
keys_injury   = injury_map.keys;
keys_dominant = dominant_map.keys;
common_keys = intersect(keys_injury, keys_dominant);

same_group = {};      % dominant == injury
different_group = {}; % dominant ~= injury

for i = 1:numel(common_keys)
    key = common_keys{i};

    injury_side   = injury_map(key);
    dominant_side = dominant_map(key);

    if strcmp(injury_side, dominant_side)
        same_group{end+1} = key; %#ok<SAGROW>
    else
        different_group{end+1} = key; %#ok<SAGROW>
    end
end

disp("Dominant == Injury side:")
disp(same_group')

disp("Dominant ~= Injury side:")
disp(different_group')


% ==============================
% Group containers after normed to 101 length
% ==============================
Group.same.dominant.ID = {}; 
Group.same.dominant.IK = {}; 
Group.same.nondominant.ID = {}; 
Group.same.nondominant.IK = {};

Group.diff.dominant.ID = {}; 
Group.diff.dominant.IK = {}; 
Group.diff.nondominant.ID = {}; 
Group.diff.nondominant.IK = {};


for i = 1:length(dirInfo)
    % 只处理文件夹，且排除 . 和 ..
    if dirInfo(i).isdir && ~strcmp(dirInfo(i).name, '.') && ~strcmp(dirInfo(i).name, '..')

        folderPath = fullfile(rootPath, dirInfo(i).name);

        % 构造 mat 文件路径
        ID_path = fullfile(folderPath, 'ID_new.mat');
        IK_path = fullfile(folderPath, 'IK_new.mat');

        % 判断文件是否存在  for one person
        if exist(ID_path, 'file') && exist(IK_path, 'file')
            fprintf('正在加载：%s\n', folderPath);
            playerId = folderPath(end-9:end);
            injury_side   = injury_map(playerId);
            dominant_side = dominant_map(playerId);

            ID = load(ID_path);
            ID = ID.ID;
            IK = load(IK_path);
            IK = IK.IK;
           % 对数据进行裁剪 -1.5s before 0.5s after the pass
            weight = weight_map(playerId);
            videoFreq = 240;
           
            [ID, IK, ID_norm, IK_norm] = passMotionFilter(ID, IK, dominant_side, weight, videoFreq);

            % ==============================
            % spliting the data to the group with same, diff IK ID
            % ==============================
            % Determine group name
            if dominant_side == injury_side
                groupName = 'same';
            else
                groupName = 'diff';
            end
            
            % dominant leg
            Group.(groupName).dominant.ID{end+1} = ID_norm.same;
            Group.(groupName).dominant.IK{end+1} = IK_norm.same;
            
            % non-dominant leg
            Group.(groupName).nondominant.ID{end+1} = ID_norm.diff;
            Group.(groupName).nondominant.IK{end+1} = IK_norm.diff;

            

            % previous ID IK without formating
            % [IDL, IKL, IDR, IKR] = dataVis(ID, IK, dirInfo(i).name);
            
            % if injury_side == dominant_side
            %     dataAnalysisIndividual(IDL, IKL, IDR, IKR, injury_side, true);
            % else
            %     dataAnalysisIndividual(IDL, IKL, IDR, IKR, injury_side, false);
            % end

            
        else
            fprintf('跳过（缺少文件）：%s\n', folderPath);
        end
    end
end

disp('处理完成！');
disp('start analyzing ！');

% four graphs visualization
dataVisGroupSixteen(Group);

alpha = 0.05;
Stats = dataAnalysisGroup(Group, alpha);
% printAnalysisResults(Results);


