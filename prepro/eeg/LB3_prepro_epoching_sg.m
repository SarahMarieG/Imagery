function nextIdx = LB3_prepro_epoching_sg(datafolder, filename, csvfile, resampleTo, segTimesMs, startIdx)

    EEG = pop_loadset('filename', filename, 'filepath', datafolder);
    EEG = pop_resample(EEG, resampleTo);

    [~, basename, ~] = fileparts(filename);

    % 1) Read CSV labels (in row order)
    stimTable = readtable(csvfile);

    if ~ismember('Valence', stimTable.Properties.VariableNames)
        error('CSV %s missing column "Valence".', csvfile);
    end

    labels = stimTable.Valence;
    if isstring(labels),      labels = cellstr(labels); end
    if iscategorical(labels), labels = cellstr(labels); end

    % 2) Find S  2 events in the continuous data (time order)
    eventTypes = {EEG.event.type};
    stimIdx = find(strcmp(eventTypes, 'S  2'));

    nThis = numel(stimIdx);
    if nThis == 0
        warning('%s: no S  2 events found. No labels consumed.', basename);
        nextIdx = startIdx;
        return;
    end

    % figure out which labels to use for THIS file
    stopIdx = startIdx + nThis - 1;

    if stopIdx > numel(labels)
        warning('%s: not enough CSV labels. Need %d labels (%d..%d) but only %d exist. Truncating.', ...
            basename, nThis, startIdx, stopIdx, numel(labels));
        stopIdx = numel(labels);
        nUse = stopIdx - startIdx + 1;
    else
        nUse = nThis;
    end

    % relabel in order using the offset
    for t = 1:nUse
        EEG.event(stimIdx(t)).type = labels{startIdx + t - 1};
    end

    % save relabeled continuous (optional but useful)
    EEG = pop_saveset(EEG, 'filename', [basename '_RELABEL.set'], 'filepath', datafolder);

    % epoch by the labels used in this file (stable keeps that segment's order)
    condStrings = unique(labels(startIdx:stopIdx), 'stable');
    EEGep = pop_epoch(EEG, condStrings, segTimesMs./1000, 'newname', 'epoched', 'epochinfo', 'yes');

    % save epoched
    EEGep = pop_saveset(EEGep, 'filename', [basename '_epoch_trls.set'], 'filepath', datafolder);

    % return the updated pointer for the next file (B continues after A)
    nextIdx = startIdx + nUse;
end