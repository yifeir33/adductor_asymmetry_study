function [normData, maxVals] = interpWithEvent(events, data)

    N = 51;
    idx = events.toeOff : events.ballImpact;

    t_original = linspace(0, 1, numel(idx));
    t_norm     = linspace(0, 1, N);

    fields = fieldnames(data);

    for i = 1:numel(fields)
        name = fields{i};

        seg = data.(name)(idx);

        % max BEFORE interpolation
        maxVals.(name) = max(seg);

        % interpolation
        normData.(name) = interp1(t_original, seg, t_norm, 'pchip');
    end
end
