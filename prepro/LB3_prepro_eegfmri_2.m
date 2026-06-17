function LB3_prepro_eegfmri_2(datafolder, filename, locations)
    %% Set random seed for reproducibility
    rng(1);
    [~, basename, ~] = fileparts([datafolder '/' filename]); 

    %% Initialize EEGLAB
    [ALLEEG, ~, ~, ~] = eeglab;

    %% Step 1 - Load EEG dataset
    disp('Step 1/7 - Loading EEG data...');
    EEG = pop_loadset('filename', filename, 'filepath', datafolder); 
    [ALLEEG, EEG, ~] = eeg_store(ALLEEG, EEG, 0);

    %% Step 2 - IC labeling and initial selection
    EEG = pop_iclabel(EEG, 'default');
    pop_viewprops(EEG, 0, 1:31, {'freqrange', [2 80], 'iclabel', 'on', 'plotmode', 'normal'});
    input('Highlight ICs to remove, update marks, and press enter');
    answer = inputdlg('Enter initial ICs to remove:', 'Initial IC selection', [1 50]);
    excludeICs = str2num(answer{1});

    %% Close all figures except EEGLAB
    set(0,'ShowHiddenHandles','on');                   
    h = findall(0,'Type','figure');                    
    keep = findall(0,'Type','figure','-regexp','Name','EEGLAB');
    h = setdiff(h, keep);                              
    set(h, 'CloseRequestFcn','');                      
    delete(h);                                        
    set(0,'ShowHiddenHandles','off');

    %% Step 3 - Visual inspection loop
    disp('Step 2/7 - Reviewing ICs before removal...');
    repeatFlag = true;
    while repeatFlag
        EEG_temp = eeg_checkset(EEG);
        EEG_temp = pop_subcomp(EEG_temp, excludeICs, 0);

        % Visual comparison: black = original, red = after IC removal
        eegplot(EEG.data, 'srate', EEG.srate, 'data2', EEG_temp.data);
        uiwait(msgbox('Scroll through trials. Close the window when ready to continue.'));

        % Ask whether to redefine ICs
        choice = questdlg('Do you want to redefine the ICs to remove?', ...
            'Confirm ICs', 'Yes','No','Cancel','Yes');

        switch choice
            case 'Yes'
                % Show IC properties again before redefining
                pop_viewprops(EEG, 0, 1:31, {'freqrange',[2 80],'iclabel','on','plotmode','normal'});
                input('Review ICs in the window, then press enter');
                answer2 = inputdlg('Enter new ICs to remove:', 'Redefine ICs', [1 50]);
                excludeICs = str2num(answer2{1});
            case 'No'
                repeatFlag = false;
            case 'Cancel'
                error('Process cancelled by user.');
        end
    end

    % Final IC removal
    EEG = eeg_checkset(EEG);
    EEG = pop_subcomp(EEG, excludeICs, 0);
    disp(['Final ICs removed: ' num2str(excludeICs)]);
       %% ---  Close figures
        set(0,'ShowHiddenHandles','on');                   
        h = findall(0,'Type','figure');                    
        % Keep eeg window:
        keep = findall(0,'Type','figure','-regexp','Name','EEGLAB');
        h = setdiff(h, keep);                              
        set(h, 'CloseRequestFcn','');                      
        delete(h);                                        
        set(0,'ShowHiddenHandles','off');


    %% Step 4 - Detect and interpolate bad channels
    [~, interpvec] = scadsAK_2dInterpChan(EEG.data(1:31,:), locations, 2.2);
    disp('Step 3/7 - Interpolating channels...');
    EEG = pop_interp(EEG, interpvec, 'spherical');

    %% Step 5 - Apply average reference
    disp('Step 4/7 - Applying average reference...');
    EEG = pop_reref(EEG, [], 'exclude', 32);

    %% Step 6 - CSD transformation
    disp('Step 6/7 - Performing CSD transformation...');
    EEG = pop_select(EEG, 'rmchannel',{'ECG'});
    EEG = csdFromErplabAutomated(EEG, 4, 1e-5, 10);
    [~, EEG, ~] = pop_newset(ALLEEG, EEG, 1, 'gui','off');

    %% Step 7 - Save preprocessed data
    disp('Step 7/7 - Saving preprocessed EEG data...');
    pop_saveset(EEG, 'filename',[basename '_prepro2.set'], 'filepath',datafolder);

    %% Generate preprocessing log
    logText = strcat(['Logfile for ' basename ' - preprocessing complete'], '\n', ...
       'Date/time: ', string(datetime()), '\n', ...
       'Removed ICs: ', int2str(excludeICs), '\n', ...                   
       'Interpolated channels: ', sprintf('%s ',string(interpvec)));
    fID = fopen([datafolder '2_log_' basename '.txt'], 'w');
    fprintf(fID, logText);
    fclose(fID);
end
