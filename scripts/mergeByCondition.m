%% merge multiple runs by condition label
% parts: should be a cell array where each cell is one part (e.g, run1,
% run2)
% assumes channel x timepoints x trials dimensionality

function merged = mergeByCondition(runs)
    % collect all condition names across parts
    conds = strings(0);
    for k = 1:numel(runs)
        conds = [conds; string(runs{k}(:,1))]; 
    end

    conds = unique(conds,'stable'); %keeps only unique condition names

    merged = cell(numel(conds),3); %creates cell array, 1 row/cond, 3 columns
    merged(:,1) = cellstr(conds); %input cond names in column 1

    for ci = 1:numel(conds)
        cname = conds(ci);
        Xlist = {}; %stores eeg data for each run
        t_ref = []; %stores timecourse for each run
        
        for k = 1:numel(runs)
            dk = runs{k};
            idx = find(string(dk(:,1))==cname, 1);
            if isempty(idx)
                continue; 
            end

            X = dk{idx,2}; t = dk{idx,3};

            if isempty(t_ref), t_ref = t; end

            % require same samples/chans to safely concatenate
            if ~isempty(Xlist)
                if size(X,1)~=size(Xlist{1},1) || size(X,2)~=size(Xlist{1},2)
                    continue; % skip mismatched part for this condition
                end
            end
            Xlist{end+1} = X;
        end

        if isempty(Xlist)
            merged{ci,2} = []; merged{ci,3} = [];
        else
            merged{ci,2} = cat(3, Xlist{:}); % stack trials
            merged{ci,3} = t_ref;
        end
    end
end
