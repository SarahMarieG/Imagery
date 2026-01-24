function LB3_prepro_epoching_gaborgen_sg(datafolder, filename, csvfile, markerStrings, condStrings, ...
    resampleTo, segTimesMs)
        %% set random number generator (just in case)
        rng(1);

         [~, basename, ~] = fileparts([datafolder '/' filename]); 
        
        %% initialize eeglab
        [ALLEEG, ~, ~, ~] = eeglab;
        %% load dataset
        disp('Step 1/7 - load EEG data');
        EEG = pop_loadset('filename', filename, 'filepath', datafolder); 
        [ALLEEG, EEG, ~] = eeg_store(ALLEEG, EEG, 0);
        

        %% Step 2 - resample
        disp('Step 2/5 - Resampling data...');
        EEG = pop_resample(EEG, resampleTo);
    
        %% Step 3 - Replace event 'S121' with 'S 21'
        % disp('Step 3/5 - Replacing event codes...');
        % markerallevents = {EEG.event.type};
        % csplus_paired = find(ismember(markerallevents, 'S121'));
        % for idx = csplus_paired
        %     EEG.event(idx).type = 'S 21';
        % end   
stimTable = readtable(csvfile);
eventTypes = {EEG.event.type};
stimIdx = find(strcmp(eventTypes, 'S  2'));

for t = 1:numel(stimIdx)
    EEG.event(stimIdx(t)).type = stimTable.Valence{t};
end

    %% Step 4 - Epoch each condition separately
    disp('Step 4/5 - Epoching data by condition...');
    dataOut = cell(numel(condStrings), 3);  % now 3 columns: label, data, time
    
    for i = 1:numel(condStrings)
        EEG_tmp = pop_epoch(EEG, condStrings{i}, segTimesMs ./ 1000, ...
            'newname', 'segmented', 'epochinfo', 'yes');
        
        dataOut{i,1} = condStrings{i}        % condition label
        dataOut{i,2} = EEG_tmp.data;          % EEG data: chan × time × trials
        dataOut{i,3} = EEG_tmp.times;         % time vector in ms
    end
    
    %% Step 5 - Save condition–data–time matrix
    disp('Step 5/5 - Saving condition–data–time matrix...');
    outFile = fullfile(datafolder, sprintf('%s_ALLCONDITIONS_EPOCHS.mat', basename));
    save(outFile, 'dataOut', '-v7.3');
    disp('--- Done! Saved dataOut with condition labels, data, and time vectors ---');

end
