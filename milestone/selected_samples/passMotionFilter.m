function [ID, IK, ID_norm, IK_norm] = passMotionFilter(ID, IK, dominant_side, weight, videoFreq)
% filtering 
passLabels = fieldnames(IK.IK);

% same: passing side = dominant side
% diff: passing side != dominant side
motions = {'hipFlexion','hipAdduction','hipRotation','kneeFlexion'};
groups  = {'same','diff'};

ikMotions = {'hipFlexionAngle','hipAdductionAngle','hipRotationAngle','kneeFlexionAngle'};
idMotions = {'hipFlexionMoment','hipAdductionMoment','hipRotationMoment','kneeFlexionMoment'};

groups = {'same','diff'};

% -----------------------------
% initialize outputs
% -----------------------------
for g = 1:numel(groups)
    for k = 1:numel(ikMotions)
        IK_norm.(groups{g}).(ikMotions{k}) = [];
        maxVal_map.(groups{g}).(ikMotions{k}) = -inf;
    end
    for j = 1:numel(idMotions)
        ID_norm.(groups{g}).(idMotions{j}) = [];
        maxVal_map.(groups{g}).(idMotions{j}) = -inf;
    end
end


for i = 1:numel(passLabels)
    labelName = passLabels{i};
    pass = IK.IK.(labelName);
    passID = ID.id.(labelName);
    
    % use calcn instead
    left_calc = {'calcn_l_X','calcn_l_Y','calcn_l_Z'};
    right_calc = {'calcn_r_X','calcn_r_Y','calcn_r_Z'};

    % 1️⃣ 判断最后一位是 L 还是 R
    if contains(labelName, '_L')
        passing_side = 'L';
        calcVars = left_calc;
    elseif contains(labelName, '_R')
        passing_side = 'R';
        calcVars = right_calc;
    else
        error('labelName %s does not end with L or R', labelName);
    end

     % 2️⃣ 从 pass.COM.pos 中取对应三列
    % 假设 pass.COM.pos 是 table
    calcnPos = pass.COM.pos(:, calcVars);
    calcnPosMat = table2array(calcnPos);
    
    % detect one passing 
    [events, F, normData, maxVals] = detect_passMotionEvents(calcnPosMat, pass.jointangles, passID.jointmoments, passing_side, videoFreq,labelName,0);
     
    
            % 4️⃣ same / diff
    if passing_side == dominant_side
        groupName = 'same';
    else
        groupName = 'diff';
    end
    

    % -----------------------------
    % append IK angles
    % -----------------------------
    for k = 1:numel(ikMotions)
        motion = ikMotions{k};
        IK_norm.(groupName).(motion) = [IK_norm.(groupName).(motion); normData.(motion)];
        % if motion == "hipFlexionAngle" && maxVals.(motion) > 100
        %     % disp("current motion is:" + motion)
        %     disp("max value from map:" + maxVal_map.(groupName).(motion));
        %     disp("this time max value:" + maxVals.(motion));
        %     % if maxVals.(motion) > maxVal_map.(groupName).(motion)
        %         disp(labelName);
        %         disp(events);
        %     % end
        % end
        maxVal_map.(groupName).(motion) = max(maxVals.(motion), maxVal_map.(groupName).(motion));
    end

    % -----------------------------
    % append ID moments
    % -----------------------------
    for j = 1:numel(idMotions)
        motion = idMotions{j};
        ID_norm.(groupName).(motion) = [ID_norm.(groupName).(motion); normData.(motion)/weight];
        maxVal_map.(groupName).(motion) = max(maxVals.(motion)/ weight, maxVal_map.(groupName).(motion));
    end



% -----------------------------
% print max values
% -----------------------------
fprintf('\n================ MAX VALUES ================\n');
for g = 1:numel(groups)
    fprintf('%s side:\n', upper(groups{g}));
    for k = 1:numel(ikMotions)
        motion = ikMotions{k};
        fprintf('  %s : %.3f\n', motion, maxVal_map.(groups{g}).(motion));
    end
    for j = 1:numel(idMotions)
        motion = idMotions{j};
        fprintf('  %s : %.3f\n', motion, maxVal_map.(groups{g}).(motion));
    end
    fprintf('\n');
end

end

