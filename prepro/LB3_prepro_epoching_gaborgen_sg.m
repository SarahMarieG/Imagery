function LB3_prepro_epoching_gaborgen_sg(folder, setfile, newMarkers, markerToReplace, condStrings, resampleTo, segTimesMs)

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


%% Epoch by condition
eventTypes = {EEG.event.type};

for c = 1:numel(condStrings)
    cond = condStrings{c};

    % find events of this condition
    cond_idx = find(strcmp(eventTypes, cond));

    if isempty(cond_idx)
        warning('No events for condition %s in %s', cond, setfile.name)
        continue
    end

    % epoch around each event
    EEGc = pop_epoch(EEG, {cond}, segTimesMs/1000);

    % convert to 3D matrix
    temp3d = EEGc.data;


    newTemp3d = EEGc.data;  % chans x time x trials
    outname = sprintf('temp3d_%s.mat', cond);
    outpath = fullfile(folder, outname);

    if exist(outpath, 'file')
        S = load(outpath, 'temp3d');
        oldTemp3d = S.temp3d;

        % Safety: dimensions must match on chans and time
        if size(oldTemp3d,1) ~= size(newTemp3d,1) || size(oldTemp3d,2) ~= size(newTemp3d,2)
            error('Size mismatch for %s: old [%s], new [%s].', outname, ...
                num2str(size(oldTemp3d)), num2str(size(newTemp3d)));
        end

        temp3d = cat(3, oldTemp3d, newTemp3d);   % append trials
    else
        temp3d = newTemp3d;
    end

    save(outpath, 'temp3d', '-v7.3');
    fprintf('Saved/updated %s (nTrials=%d)\n', outname, size(temp3d,3));
end


        % matout = fullfile(datafolder, [basename, 'epoch_trls.mat']);

        % Save the entire EEG structure into the .mat file

%         data   = EEG.data;      % chan × time × trials
% 
%         save(matout, 'data', '-mat');
%         % Step 3 - find event codes/Replace event 'S  2' with conditions in order
%         disp('Step 3/5 - Replacing event codes...');
%         markerallevents = {EEG.event.type};
%         csplus_paired = find(ismember(markerallevents, 'S  2'));
%         for idx = csplus_paired
%             EEG.event(idx).type = '';
%         end   
%
% 
%     %% Step 4 - Epoch each condition separately
%     dataOut = cell(numel(condStrings), 3);  % now 3 columns: label, data, time
% 
%     for i = 1:numel(condStrings)
%         EEG_conds = pop_epoch(EEG, condStrings{i}, segTimesMs ./ 1000, ...
%             'newname', 'segmented', 'epochinfo', 'yes');
% 
%         dataOut{i,1} = condStrings{i}        % condition label
%         dataOut{i,2} = EEG_conds.data;          % EEG data: chan × time × trials
%         dataOut{i,3} = EEG_conds.times;         % time vector in ms
%     end
% 
%     %% Step 5 - Save condition–data–time matrix
%     disp('Step 5/5 - Saving condition–data–time matrix...');
%     outFile = fullfile(datafolder, sprintf('%s_ALLCONDITIONS_EPOCHS.mat', basename));
%     save(outFile, 'dataOut', '-v7.3');
%     disp('--- Done! Saved dataOut with condition labels, data, and time vectors ---');
% 
% end
