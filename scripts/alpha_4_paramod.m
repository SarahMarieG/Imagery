%% Single trials for parametric modulation (output: ...WaPower_singtrls.mat)
% only difference from below is that we didn't avg over trials before wavelet
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
            % save(fullPath, 'WaPower_singtrls');

        end
    end
end



%% identify/interpolate/plot single trial outliers for parametric modulation
clear
cd /Volumes/ELEMENTS/imagery/participants/

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

    %note: afni amplitude modulation does this automatically so no need to
    %do this, but also doesn't hurt anything
    PLE_centered = PLE_corr - mean(PLE_corr);
    NTR_centered = NTR_corr - mean(NTR_corr);
    UPL_centered = UPL_corr - mean(UPL_corr);


    % % Save individual participant files folder
    %writematrix(PLE_centered, fullfile(sub_folder, 'parmod_pleasant.txt'));
   % writematrix(NTR_centered, fullfile(sub_folder, 'parmod_neutral.txt'));
   % writematrix(UPL_centered, fullfile(sub_folder, 'parmod_unpleasant.txt'));

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