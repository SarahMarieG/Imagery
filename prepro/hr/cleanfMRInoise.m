function cleanfMRInoise(partID,newSamplingRate,parentFolder)
    
    [ALLEEG, ~, ~, ~] = eeglab;
    %% load dataset
    disp('Step 1/8 - import BVA data');
    dataFolder = [parentFolder '/sub-' num2str(partID) '/'];

    try
        EEG = pop_loadbv(dataFolder, ['gaborgen24_MRI_' int2str(partID) '.vhdr']);
    catch
        EEG = pop_loadbv(dataFolder, ['gaborgen24_Day1_' int2str(partID) '.vhdr']);
    end
    
    [ALLEEG, EEG, ~] = pop_newset(ALLEEG, EEG, 0,'setname',['gaborgen24_MRI_' int2str(partID)],'gui','off'); 
    
    %% add channel locations
    disp('Step 2/8 - add channel coordinates');
    EEG = eeg_checkset(EEG);
    EEG=pop_chanedit(EEG, 'lookup', '/Users/jourdan.pouliot/Documents/GaborGen/EEGchanCoordinates/standard_1005.elc');
    %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    %% save raw data in eeglab format
    disp('Step 3/8 - save raw data in eeglab format');
    EEG = eeg_checkset(EEG);
    EEG = pop_saveset(EEG, 'filename',['gaborgen24_MRI_' int2str(partID) '_raw.set'], ...
                           'filepath',dataFolder);

    %% rename TR markers
    disp('Step 4/8 - rename TR markers');
    for i = 1:length(EEG.event)
        if strcmp(EEG.event(i).type(1:4), 'T  1')
            EEG.event(i).type = 'T1';
        end
    end
    
    %% remove MRI gradient artifacts
    disp('Step 5/8 = remove gradient artifacts (this may take a while...)');
    EEG = eeg_checkset(EEG);
    [EEG, ~] = pop_fmrib_fastr(EEG, 70, 4, 31, 'T1', 0, 0, 0, [], [], [], [],'auto');
    
    %% downsample
    %disp('Step 6/8 - downsample data');
    %EEG = eeg_checkset(EEG);
    %EEG = pop_resample(EEG, newSamplingRate);
    
    %% detect QRS
    %disp('Step 7/8 - detect QRS events');
    %EEG = eeg_checkset(EEG);
    %EEG = pop_fmrib_qrsdetect(EEG, 32, 'qrs', 'no');
    
    %% remove cardioballistic artifacts
    %disp('Step 8/8 - remove cardioballistic artifacts');
    %EEG = eeg_checkset(EEG);
    %EEG = pop_fmrib_pas(EEG,'qrs','obs',3);

    %% save cleaned data

    ECG = pop_select(EEG, 'channel',{'ECG'});
    pop_saveset(ECG, 'filename',['gaborgen24_MRI_' int2str(partID) '_noGradient.set'],'filepath',dataFolder);
    
    %pop_saveset(EEG, 'filename',['gaborgen24_MRI_' int2str(partID) '_nofMRI.set'],'filepath',dataFolder);
end