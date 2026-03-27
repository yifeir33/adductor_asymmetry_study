function results = wilcoxon_curve(dominant, nondominant, alpha)
% WILCOXON_CURVE
% Performs a single-sample Wilcoxon signed-rank test on the differences
% between dominant and non-dominant curves.
%
% INPUTS:
%   dominant    - matrix [time x subjects], e.g., 101x5
%   nondominant - matrix [time x subjects], same size as dominant
%   alpha       - significance level (default 0.05)
%
% OUTPUT:
%   results - structure with test results
%
% Example:
%   results = wilcoxon_curve(domMatrix, nonDomMatrix, 0.05);

    if nargin < 3
        alpha = 0.05;
    end

    % -------------------------
    % Input check
    % -------------------------
    if ~isequal(size(dominant), size(nondominant))
        error('Dominant and nondominant must have the same size.');
    end

    % -------------------------
    % Compute difference
    % -------------------------
    diffMatrix = dominant - nondominant;   % size: time x subjects
    diffVector = diffMatrix(:);            % flatten all points

    % -------------------------
    % Single-sample Wilcoxon signed-rank test against 0
    % -------------------------
    [p,h,stats] = signrank(diffVector, 0, 'alpha', alpha);

    % -------------------------
    % Store results
    % -------------------------
    results.alpha = alpha;
    results.p_value = p;
    results.h = h;
    results.signedrank = stats.signedrank;
    results.n = numel(diffVector);
    results.median_diff = median(diffVector);

    % -------------------------
    % Display summary
    % -------------------------
    fprintf('\n================ Single-Sample Wilcoxon (Signed-Rank) ================\n');
    fprintf('Sample size (total points): %d\n', results.n);
    fprintf('Median difference (dominant - nondominant): %.3f\n', results.median_diff);
    fprintf('Signed-rank statistic W: %d\n', results.signedrank);
    fprintf('p-value: %.4f\n', results.p_value);

    if h == 1
        fprintf('Result: Significant difference from 0 (p < %.2f)\n', alpha);
    else
        fprintf('Result: No significant difference from 0 (p >= %.2f)\n', alpha);
    end
    fprintf('=====================================================================\n');

end
