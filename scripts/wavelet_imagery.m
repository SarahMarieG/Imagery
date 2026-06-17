%% Wavelet and Plot PNU groups
cd /Volumes/ELEMENTS/imagery/eeg
baseDir = '/Volumes/ELEMENTS/imagery/eeg/';

%%
parFolders = dir(fullfile(baseDir, 'par_*'));
groupNames = {'Neutral_Merged', 'Pleasant_Merged', 'Unpleasant_Merged'};

for p = 1:length(parFolders)
    currentParDir = fullfile(parFolders(p).folder, parFolders(p).name);
    
    for g = 1:length(groupNames)
        matfile = fullfile(currentParDir, [parFolders(p).name, '_', groupNames{g}, '.mat']);
        
        if exist(matfile, 'file')
            fprintf('Analyzing %s: %s\n', parFolders(p).name, groupNames{g});
            load(matfile); % Loads 'temp3d'

            % Wavelet Analysis
            [WaPower, PLI, PLIdiff] = wavelet_app_mat(temp3d, 500, 40, 800, 20, [], []);


            fileName = strcat(parFolders(p).name, '_', groupNames{g}, '_wavelet.mat');
            fullPath = fullfile(currentParDir, fileName);
            % save(fullPath, 'WaPower', 'PLI', 'PLIdiff');

            % Separate WaPower file
            fileNamePower = strcat(parFolders(p).name, '_', groupNames{g}, '_WaPower.mat');
            fullPathPower = fullfile(currentParDir, fileNamePower);
            % save(fullPathPower, 'WaPower');

            % % Save Results
            % save(fullfile(currentParDir, [parFolders(p).name, '_', groupNames{g}, '.mat']), ...
            %     'WaPower', 'PLI', 'PLIdiff');

            % Plotting
            faxisall = 0:0.0476:100; faxis = faxisall(40:20:800);
            taxis = -1:0.002:20-0.002;
            % 
            % figure();
            % contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar, caxis([0 7]);
            % title(sprintf('%s: %s', parFolders(p).name, groupNames{g}));
            % xlabel('Time (s)'); ylabel('Frequency (Hz)');
            % pause
          
        end
    end
end




%% Single trials for parametric modulation (output: ...WaPower_singtrls.mat)
% only difference from above is that we didn't avg over trials before wavelet
% Wavelet PNU groups
cd /Volumes/ELEMENTS/imagery/eeg
baseDir = '/Volumes/ELEMENTS/imagery/eeg/';
parFolders = dir(fullfile(baseDir, 'par_*'));
groupNames = {'Neutral_Merged', 'Pleasant_Merged', 'Unpleasant_Merged'};

for p = 1:length(parFolders)
    currentParDir = fullfile(parFolders(p).folder, parFolders(p).name);
    
    for g = 1:length(groupNames)
        matfile = fullfile(currentParDir, [parFolders(p).name, '_', groupNames{g}, '.mat']);
        
        if exist(matfile, 'file')
            fprintf('Analyzing %s: %s\n', parFolders(p).name, groupNames{g});
            load(matfile); % Loads 'temp3d'

            % Wavelet Analysis on single trials
            [WaPower4d] = wavelet_app_mat_singtrials(temp3d, 500, 180, 260, 20);

            fileName = strcat(parFolders(p).name, '_', groupNames{g}, '_WaPower_singtrls.mat');
            fullPath = fullfile(currentParDir, fileName);
            % save(fullPath, 'WaPower4d');

            % Average over frequencies
            % 1. Select sensors [9, 10, 20]
            % 2. Average across dimensions 1 (Sensors), 2 (Time), and 3 (Frequency)
            % 3. 'squeeze' to remove the single dimensions, leaving only the 18 trials
            WaPower_singtrls = squeeze(mean(WaPower4d([9 10 20], 5500:6500, :, :), [1 2 3]))';
            save(fullPath, 'WaPower_singtrls');

        end
    end
end



%% identify/interpolate/plot single trial outliers for parametric modulation
clear
cd /Volumes/ELEMENTS/imagery/eeg

filePathsNTR = getfilesinfolders(pwd, 'par_', '_Neutral_Merged_WaPower_singtrls.mat');
filePathsPLE = getfilesinfolders(pwd, 'par_', '_Pleasant_Merged_WaPower_singtrls.mat');
filePathsUPL = getfilesinfolders(pwd, 'par_', 'Unpleasant_Merged_WaPower_singtrls.mat');

time_cols_dir = '/Volumes/ELEMENTS/imagery/fmri/time_cols';

for sub = 1:20

    sub_folder = fullfile(time_cols_dir, sprintf('par_%02d', sub));


    PLE = load(filePathsPLE(sub,:));
    NTR = load(filePathsNTR(sub,:));
    UPL = load(filePathsUPL(sub,:));

    [PLE_corr, TF_ple] = filloutliers(PLE.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);
    [NTR_corr, TF_ntr] = filloutliers(NTR.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);
    [UPL_corr, TF_upl] = filloutliers(UPL.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);

    PLE_centered = PLE_corr - mean(PLE_corr);
    NTR_centered = NTR_corr - mean(NTR_corr);
    UPL_centered = UPL_corr - mean(UPL_corr);


    % % Save individual participant files folder
    writematrix(PLE_centered, fullfile(sub_folder, 'parmod_pleasant.txt'));
    writematrix(NTR_centered, fullfile(sub_folder, 'parmod_neutral.txt'));
    writematrix(UPL_centered, fullfile(sub_folder, 'parmod_unpleasant.txt'));

    % figure;
    % % Plot PLE
    % subplot(3,1,1);
    % plot(PLE.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'g'); hold on;
    % plot(PLE_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    % title(['Sub ' num2str(sub) ' PLE']);
    % 
    % % Plot NTR
    % subplot(3,1,2);
    % plot(NTR.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'g'); hold on;
    % plot(NTR_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    % title('NTR');
    % 
    % % Plot UPL
    % subplot(3,1,3);
    % plot(UPL.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'g'); hold on;
    % plot(UPL_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    % title('UPL');
    % xlabel('Trial Number');
    % 

end





%% FFT - redo with this timecourse (55-6500 not done yet)
% just to see if its similar to wavelets
cd /Volumes/ELEMENTS/imagery/eeg

    filePathsPfft = getfilesinfolders(pwd, 'par_', '_Pleasant_Merged.mat');
    filePathsNfft = getfilesinfolders(pwd, 'par_', '_Neutral_Merged.mat');
    filePathsUfft = getfilesinfolders(pwd, 'par_', 'Unpleasant_Merged.mat');
    %only want original trls files
    get_FFT_mat3d(filePathsPfft, 5500:6500, 500); %good timecourse? ASK ANDREAS
    get_FFT_mat3d(filePathsNfft, 5500:6500, 500);
    get_FFT_mat3d(filePathsUfft, 5500:6500, 500);

%move generated files to spectra folder

%% merge spectra by condition
cd /Volumes/ELEMENTS/imagery/eeg/spectra
filePaths = getfilesindir(pwd, '*.spec');
mergemulticons(filePaths, 3, 'GM20.singletrialspec');










%% 9 conds old wavelet analysis
baseDir = '/Volumes/ELEMENTS/imagery/eeg/';
% List of condition suffixes
conditions = {'oth', 'neu', 'contam', 'surv', 'rew', 'ero', 'PerNeu', 'PerUn', 'PerPl'};

% Get list of participant folders
parFolders = dir(fullfile(baseDir, 'par_*'));

for p = 1:length(parFolders)
    currentParDir = fullfile(parFolders(p).folder, parFolders(p).name);
    
    for c = 1:length(conditions)
        condSuffix = conditions{c};
        
        % Find all files matching this specific condition in the participant's folder
        % This handles multiple parts (PartA, PartB) automatically via the wildcard '*'
        matFiles = dir(fullfile(currentParDir, ['*event_' condSuffix '.mat']));
        
        if isempty(matFiles)
            continue; % Skip if participant doesn't have this condition (only for "oth"
        end
        
        fprintf('Processing %s | Condition: %s\n', parFolders(p).name, condSuffix);
        
        % Initialize/reset for current condition
        temp3d_combined = [];
        
        for f = 1:length(matFiles)
            fullPath = fullfile(matFiles(f).folder, matFiles(f).name);
            dat = load(fullPath);
            
            % Concatenate trials along the 3rd dimension
            if isempty(temp3d_combined)
                temp3d_combined = dat.temp3d;
            else
                temp3d_combined = cat(3, temp3d_combined, dat.temp3d);
            end
        end

        %Run Wavelet Analysis
        [WaPower, PLI, PLIdiff] = wavelet_app_mat(temp3d_combined, 500, 40, 800, 20, [], []);

        saveName = [parFolders(p).name, condSuffix, 'wavelet']; 
        savePath = fullfile(currentParDir, saveName);

        % Save variables to the participant's folder
        save(savePath, 'WaPower', 'PLI', 'PLIdiff');
        fprintf('Saved: %s\n', savePath);

        % % plotting
        % figure('Name', [parFolders(p).name ' - ' condSuffix]);
        % faxisall = 0:0.0476:100;
        % faxis = faxisall(40:20:800);
        % taxis = -1:0.002:20-0.002;
        % 
        % contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar
        % title(['Wavelet: ' parFolders(p).name ' (' condSuffix ')']);
        % xlabel('Time (s)'); ylabel('Frequency (Hz)');
        % 
    end
end
