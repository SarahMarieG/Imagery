function LB3_prepro_epoching_gaborgen_sg_new(folder, setfile, newMarkers, markerToReplace, condStrings, resampleTo, segTimesMs, EcfgFilePath)

thresholdChan       = 2.5;   % globally bad channels
thresholdChanTrials = 2.5;   % bad channel x epoch cells
thresholdTrials     = 1.25;  % bad trials

%% set random number generator
rng(1);
% [ALLEEG, ~, ~, ~] = eeglab;
%% load dataset
disp('Step 1/7 - load EEG data');
EEG = pop_loadset('filename', setfile.name, 'filepath', folder);
% [ALLEEG, EEG, ~] = eeg_store(ALLEEG, EEG, 0);

%% Step 2 - resample
EEG = pop_resample(EEG, resampleTo);

%% Step 3 — Replace event markers
disp('Step 3/7 — Replacing markers')
eventTypes = {EEG.event.type};
s2_idx = find(strcmp(eventTypes, markerToReplace));

if numel(s2_idx) ~= numel(newMarkers)
    error('Mismatch: %d S  2 events but %d CSV markers', numel(s2_idx), numel(newMarkers));
end

for k = 1:numel(s2_idx)
    EEG.event(s2_idx(k)).type = newMarkers{k};
end

EEG = eeg_checkset(EEG);
disp(['Done with: ' setfile.name])

%% Save new event markers
% [~, base, ~] = fileparts(setfile.name);
% newname = [base '_event.set'];
% 
% disp(['Saving: ' newname])
% EEG = pop_saveset(EEG, 'filename', newname, 'filepath', folder);


%% Step 4: epoch ALL conditions together
%%% We want to epoch by condition actually...
% Joint epoching matters: SCADS derives its thresholds from the distribution
% across all trials in the array. Epoching per condition would give each
% condition its own threshold and bias rejection rates by condition.
disp('Step 4/6 - epoching (all conditions jointly)');
 
presentConds = condStrings(ismember(condStrings, {EEG.event.type}));
missingConds = setdiff(condStrings, presentConds);
if ~isempty(missingConds)
    warning('No events for condition(s) %s in %s', ...
            strjoin(missingConds, ', '), setfile.name);
end
if isempty(presentConds)
    warning('No usable conditions in %s -- skipping.', setfile.name);
    return
end
 
EEG_allcond = pop_epoch(EEG, presentConds, segTimesMs/1000, ...
                        'newname', 'allcond', 'epochinfo', 'yes');
EEG_allcond = eeg_checkset(EEG_allcond);
 
nEpochsRequested = sum(ismember({EEG.event.type}, presentConds));
nEpochsCut       = EEG_allcond.trials;
if nEpochsCut < nEpochsRequested
    warning(['%d of %d epochs dropped by pop_epoch (window ran past the ' ...
             'edge of the recording).'], nEpochsRequested - nEpochsCut, nEpochsRequested);
end


%% Step 5: SCADS artifact rejection
disp('Step 5/6 - SCADS artifact detection');
inmat3d = double(EEG_allcond.data);
 
% 5a. globally bad channels -> interpolated
%[outmat3d, BadChanVec] = scadsAK_3dchan(inmat3d, EcfgFilePath, thresholdChan);
 
% 5b. bad channel x epoch cells -> interpolated within epoch
[outmat3d, badindexmat] = scadsAK_3dtrialsbychans(outmat3d, thresholdChanTrials, EcfgFilePath);
 
% 5c. bad trials -> REJECTED
[outmat3d, badindexvec, NGoodtrials] = scadsAK_3dtrials(outmat3d, thresholdTrials);
 
EEG_allcond.data = single(outmat3d);
EEG_allcond = eeg_checkset(EEG_allcond);
EEG_allcond = pop_select(EEG_allcond, 'notrial', badindexvec);
EEG_allcond = eeg_checkset(EEG_allcond);
 
fprintf('SCADS: %d global bad chans | %d bad trials rejected | %d retained\n', ...
        numel(BadChanVec), numel(badindexvec), EEG_allcond.trials);
 
%% Step 6: split by condition and save
disp('Step 6/6 - splitting by condition and saving');
 
artifactlog = struct();
artifactlog.setfile           = setfile.name;
artifactlog.datetime          = string(datetime());
artifactlog.thresholds        = [thresholdChan thresholdChanTrials thresholdTrials];
artifactlog.globalbadchans    = BadChanVec;
artifactlog.epochbadchans     = badindexmat;
artifactlog.badtrialstotal    = badindexvec;
artifactlog.nEpochsRequested  = nEpochsRequested;
artifactlog.nEpochsCut        = nEpochsCut;
artifactlog.nTrialsRetained   = EEG_allcond.trials;
artifactlog.conditions        = {};
artifactlog.nTrialsByCondition = [];
 
for c = 1:numel(presentConds)
    cond = presentConds{c};
 
    if ~any(strcmp({EEG_allcond.event.type}, cond))
        warning('Condition %s lost entirely to artifact rejection in %s', cond, setfile.name);
        continue
    end
 
    EEG_temp = pop_selectevent(EEG_allcond, 'type', cond);
    EEG_temp = eeg_checkset(EEG_temp);
 
    newTemp3d = EEG_temp.data;          % chans x time x trials
    outname   = sprintf('temp3d_%s.mat', cond);
    outpath   = fullfile(folder, outname);
 
    if exist(outpath, 'file')
        S = load(outpath, 'temp3d', 'sourcefiles');
        oldTemp3d = S.temp3d;
 
        % Guard against appending the same run twice on a re-run.
        if isfield(S, 'sourcefiles') && any(strcmp(S.sourcefiles, setfile.name))
            error(['%s already contains trials from %s. Delete the temp3d_*.mat ' ...
                   'files for this participant before re-running.'], outname, setfile.name);
        end
 
        if size(oldTemp3d,1) ~= size(newTemp3d,1) || size(oldTemp3d,2) ~= size(newTemp3d,2)
            error('Size mismatch for %s: old [%s], new [%s].', outname, ...
                  num2str(size(oldTemp3d)), num2str(size(newTemp3d)));
        end
 
        temp3d = cat(3, oldTemp3d, newTemp3d);
        sourcefiles = [S.sourcefiles, {setfile.name}];
        trialsource = [repmat({'prior'}, 1, size(oldTemp3d,3)), ...
                       repmat({setfile.name}, 1, size(newTemp3d,3))];
    else
        temp3d      = newTemp3d;
        sourcefiles = {setfile.name};
        trialsource = repmat({setfile.name}, 1, size(newTemp3d,3));
    end
 
    save(outpath, 'temp3d', 'sourcefiles', 'trialsource', '-v7.3');
    fprintf('  Saved/updated %s (nTrials=%d)\n', outname, size(temp3d,3));
 
    artifactlog.conditions{end+1}        = cond;
    artifactlog.nTrialsByCondition(end+1) = size(newTemp3d, 3);
end
 
%% save artifact log 
[~, base, ~] = fileparts(setfile.name);
save(fullfile(folder, [base '.artiflog.mat']), 'artifactlog', '-mat');
 
disp(['Done with: ' setfile.name]);