%% MASTER EEG-fMRI prepro for Imagery

clc
clear all
%%
% addpath('/Users/sgardy/Documents/GitHub/Imagery')
% cd('/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG')
% datafolder = '/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG'

addpath('/Volumes/ELEMENTS/imagery/eeg')
cd ('/Volumes/ELEMENTS/imagery/eeg')
datafolder = '/Volumes/ELEMENTS/imagery'
files = dir('par_*');           
dirFlags = [files.isdir];
folderNames = {files(dirFlags).name};
folderNames = folderNames(~ismember(folderNames, {'.', '..'}));

disp('Folders in the current working directory:')
disp(folderNames)

%% First script using LB3_prepro_eegfmri_1
for subindex = 1:numel(folderNames)
    thisFolder = fullfile(datafolder, folderNames{subindex});
    vhdr = dir(fullfile(thisFolder, '*.vhdr'));
    % for n = 1:numel(vhdr)
    %     fprintf('Processing %s %s\n', folderNames{subindex}, vhdr(n).name)
    %     LB3_prepro_eegfmri_1(thisFolder, vhdr(n).name, 500, [1 40]);
    % end
end
%% Second script using LB3_prepro_eegfmri_2
% cd '/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG'
S = load('/Users/sgardy/Documents/Github/Imagery/chanlocs_ssv4att_MRI.mat');   % path
chanlocs = S.chanlocs;                 % name chanlocs

for subindex = 1:numel(folderNames)
    thisFolder = fullfile(datafolder, folderNames{subindex});
    setfile = dir(fullfile(thisFolder, '*afterICA2.set'));

%  for j = 1:numel(setfile)
%         fprintf('Running prepro2 %s  run %d  %s\n', folderNames{subindex}, j, setfile(j).name);
% 
%     LB3_prepro_eegfmri_2(thisFolder, setfile(j).name, chanlocs);
%  end
end 


%% Third script using LB3_prepro_epoching_gaborgen_sg
% 
% 1. Define which participants belong to which order
order1 = {'par_01', 'par_04', 'par_05', 'par_06', 'par_09', 'par_10', 'par_15', 'par_16', 'par_18', 'par_20'}; 
order2 = {'par_02', 'par_03', 'par_07', 'par_08', 'par_11', 'par_12', 'par_13', 'par_14', 'par_17', 'par_19', 'par_21'};

% cd('/Users/sgardy/Documents/SarahData/Imagery/Data/rawEEG')
cd('/Volumes/ELEMENTS/imagery/eeg/')

markerStrings = {{'S  2'}};
condStrings   = {'oth','neu','contam','surv','rew','ero','PerNeu','PerPl','PerUn'};
filename = "*_afterICA2_prepro2.set"
resampleTo = 500;
segTimesMs = [-1000 20000];

  for subindex = 1:numel(folderNames)
    currentPar = folderNames{subindex};
    thisFolder = fullfile(datafolder, currentPar);
    setfile = dir(fullfile(thisFolder, filename));
    setfile = setfile(~startsWith({setfile.name}, '._')); %external drive creates invisible files

% assign correct order: 1 or 2
    if ismember(currentPar, order1)
        csvfile = fullfile(datafolder, 'order1.csv');
    elseif ismember(currentPar, order2)
        csvfile = fullfile(datafolder, 'order2.csv');
    else
        warning('Participant %s not found in either group list. Skipping.', currentPar);
        continue;
    end

for k = 1:numel(setfile)

        fprintf('Epoching %s  run %d  %s\n', ...
                currentPar, k, setfile(k).name);


    LB3_prepro_epoching_gaborgen_sg(thisFolder, setfile(k).name, ...
        csvfile, markerStrings, condStrings, resampleTo, segTimesMs)
end

  end