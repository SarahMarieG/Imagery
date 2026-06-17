%% MASTER EEG-fMRI prepro for Imagery

clc
clear all
%%
% addpath('/Users/sgardy/Documents/GitHub/Imagery')
% cd('/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG')
% datafolder = '/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG'

% addpath('/Volumes/ELEMENTS/imagery/eeg')
cd ('/Volumes/ELEMENTS/imagery/eeg')
datafolder = '/Volumes/ELEMENTS/imagery/eeg'
files = dir('par_*');           
dirFlags = [files.isdir];
folderNames = {files(dirFlags).name};
folderNames = folderNames(~ismember(folderNames, {'.', '..'}));

disp('Folders in the current working directory:')
disp(folderNames)

%% First script using LB3_prepro_eegfmri_1
for i = 1:numel(folderNames)
    thisFolder = fullfile(datafolder, folderNames{i});
    vhdr = dir(fullfile(thisFolder, '*.vhdr'));
    names = {vhdr.name};
    vhdr = vhdr(~startsWith(names, '._') & ~startsWith(names, '.')); %ignores . Apple files
    for n = 1:numel(vhdr)
        fprintf('Processing %s %s\n', folderNames{i}, vhdr(n).name)
        LB3_prepro_eegfmri_1(thisFolder, vhdr(n).name, 500, [1 40]);
    end
end

%% Second script using LB3_prepro_eegfmri_2
% % cd '/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG'
% S = load('/Users/sgardy/Documents/Github/Imagery/chanlocs_ssv4att_MRI.mat');   % path
% chanlocs = S.chanlocs;                 % name chanlocs
% 
% for i = 1:numel(folderNames)
%     thisFolder = fullfile(datafolder, folderNames{i});
%     setfile = dir(fullfile(thisFolder, '*afterICA2.set'));
%     setfile = setfile(~startsWith({setfile.name}, '._'))
%  for j = 1:numel(setfile)
%         fprintf('Running prepro2 %s  run %d  %s\n', folderNames{i}, j, setfile(j).name);
% 
%     LB3_prepro_eegfmri_2(thisFolder, setfile(j).name, chanlocs);
%  end
% end 
% 
% 
% 
% %% Third script using LB3_prepro_epoching_gaborgen_sg
% 
% % initialize eeglab
% [ALLEEG, ~, ~, ~] = eeglab;
% 
% % 1. Define which participants belong to which order
% parorder1 = {'par_01', 'par_04', 'par_05', 'par_06', 'par_09', 'par_10', 'par_15', 'par_16', 'par_18', 'par_20'};
% parorder2 = {'par_02', 'par_03', 'par_07', 'par_08', 'par_11', 'par_12', 'par_13', 'par_14', 'par_17', 'par_19', 'par_21'};
% 
% % cd('/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG')
% % cd('/Volumes/ELEMENTS/imagery/eeg/')
% 
% filenamePattern = '*afterICA2_prepro2.set';
% markerToReplace = 'S  2';
% condStrings   = {'oth','neu','contam','surv','rew','ero','PerNeu','PerPl','PerUn'};
% resampleTo = 500;
% segTimesMs = [-1000 20000];
% 
% for i = 1:numel(folderNames)
%     currentPar = folderNames{i};
%     thisFolder = fullfile(datafolder, currentPar);
% 
%     % assign correct order: 1 or 2
%     if ismember(currentPar, parorder1)
%         csvfile = fullfile(datafolder, 'order1.csv');
%     elseif ismember(currentPar, parorder2)
%         csvfile = fullfile(datafolder, 'order2.csv');
% 
%     end
% 
%     % Find .set files
%     setfile = dir(fullfile(thisFolder, filenamePattern));
%     setfile = setfile(~startsWith({setfile.name}, '._')); % remove hidden files
% 
%     if isempty(setfile)
%         warning('No .set files found for %s', currentPar);
%         continue;
%     end
% 
%     % Load CSV markers
%     stimTable = readtable(csvfile);
%     remainingMarkers = stimTable{:,1};   % raw values
% 
%     % Process each .set file separately
%     for f = 1:numel(setfile)
% 
%         % Load file temporarily to count S2 events
%         EEGtmp = pop_loadset('filename', setfile(f).name, 'filepath', thisFolder);
%         eventTypes = {EEGtmp.event.type};
%         s2_idx = find(strcmp(eventTypes, markerToReplace));
%         nEvents = numel(s2_idx);
% 
%         % Extract exactly the number of markers needed
%         markersForThisFile = remainingMarkers(1:nEvents);
% 
%         % Remove them from the list
%         remainingMarkers(1:nEvents) = [];
% 
%         % Run preprocessing
%         LB3_prepro_epoching_gaborgen_sg( ...
%             thisFolder, setfile(f), markersForThisFile, ...
%             markerToReplace, condStrings, resampleTo, segTimesMs);
% 
%     end
% 
% end