function dataAnalysisIndividual(IDL, IKL, IDR, IKR, injury_side, sameSide)
% sameSide : if the injury and dominant on one side
  
alpha = 0.05;
results = struct();

%% ========= Decide dominant / nondominant =========

if sameSide
    dominant_side = injury_side;
    disp("injuryside is dominant side");
else
    dominant_side = char(setdiff(['L','R'], injury_side));
    disp("injuryside is not dominant side");
    
end

disp("injuryside is: "+ injury_side);

results.meta.injury_side   = injury_side;
results.meta.dominant_side = dominant_side;
results.meta.sameSide      = sameSide;

id_keys_l = ["hip_flexion_l_moment", "hip_adduction_l_moment", "hip_rotation_l_moment"];
ik_keys_l = ["hip_flexion_l", "hip_adduction_l", "hip_rotation_l"];
id_keys_r = ["hip_flexion_r_moment", "hip_adduction_r_moment","hip_rotation_r_moment"];
ik_keys_r = ["hip_flexion_r", "hip_adduction_r", "hip_rotation_r"];

%% ========= loop through features =========
for i = 1:length(id_keys_l)

    % ---- choose left / right by dominance ----
    if dominant_side == 'L'
        id_dom_key    = id_keys_l(i);
        id_nondom_key = id_keys_r(i);
        ik_dom_key    = ik_keys_l(i);
        ik_nondom_key = ik_keys_r(i);

        ID_dom = IDL;   ID_nondom = IDR;
        IK_dom = IKL;   IK_nondom = IKR;
    else
        id_dom_key    = id_keys_r(i);
        id_nondom_key = id_keys_l(i);
        ik_dom_key    = ik_keys_r(i);
        ik_nondom_key = ik_keys_l(i);

        ID_dom = IDR;   ID_nondom = IDL;
        IK_dom = IKR;   IK_nondom = IKL;
    end

    %% ========= ID comparison =========
    if isfield(ID_dom, id_dom_key) && isfield(ID_nondom, id_nondom_key)
        [dom_val, nondom_val] = extractTrialScalar( ...
            ID_dom.(id_dom_key), ID_nondom.(id_nondom_key));
        disp("ID Comparision: ID Dominant side feature is " + id_dom_key);
        results.ID.(id_dom_key) = wilcoxon_paired(dom_val, nondom_val, alpha);
    end

    %% ========= IK comparison =========
    if isfield(IK_dom, ik_dom_key) && isfield(IK_nondom, ik_nondom_key)
        [dom_val, nondom_val] = extractTrialScalar( ...
            IK_dom.(ik_dom_key), IK_nondom.(ik_nondom_key));
        disp("IK Comparision: IK Dominant side feature is " + ik_dom_key);
        results.IK.(ik_dom_key) = wilcoxon_paired(dom_val, nondom_val, alpha);
    end
end
end

function [dom_val, nondom_val] = extractTrialScalar(dom_list, nondom_list)
nTrial = min(length(dom_list), length(nondom_list));

% 假设所有 trial 时间长度一致
nTime = length(dom_list{1});

% trial × time
dom_mat    = zeros(nTrial, nTime);
nondom_mat = zeros(nTrial, nTime);

for t = 1:nTrial
    dom_mat(t,:)    = dom_list{t}(:)';
    nondom_mat(t,:) = nondom_list{t}(:)';
end

% 👇 核心修复：在 trial 维度取平均
dom_val    = mean(dom_mat, 1);   % 1 × nTime
nondom_val = mean(nondom_mat, 1);

end
