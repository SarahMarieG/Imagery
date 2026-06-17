clear
rootDir = '/Volumes/ELEMENTS/imagery/eeg';
cd(rootDir);

% list participant folders
pars = dir('par_*');
pars = pars([pars.isdir]);

names = fullfile(rootDir, pars(1).name);
namefiles = dir(fullfile(names, 'temp3d_*.mat'));


condnames = extractBetween({namefiles.name}, 'temp3d_', '.mat')

fs = 500;
faxisall = 0:0.0476:100;
faxis = faxisall(40:20:800);
taxis = -1:0.002:20-0.002; 

for p = 1:numel(pars)
    thispar = pars(p).name;
    thisdir = fullfile(rootDir, thispar)

    matfiles = dir(fullfile(thisdir, 'temp3d_*.mat'))

    for f = 1:numel(matfiles)
        matname = matfiles(f).name
        cond = extractBetween(matname, 'temp3d_', '.mat')
        cond = cond{1}

        s = load(fullfile(thisdir, matname))
        temp3d = s.temp3d;

        [WaPower, PLI, PLIdiff] = wavelet_app_mat(temp3d, fs, 40, 800, 20, [], []);

figure()
contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar, caxis ([0 7] )
ylim([1 30])
    end
pause
end





%% create all trials grouped together
rootDir = '/Volumes/ELEMENTS/imagery/eeg';
cd(rootDir);

% list participant folders
pars = dir('par_*');
pars = pars([pars.isdir]);

names = fullfile(rootDir, pars(1).name);
namefiles = dir(fullfile(names, 'temp3d_*.mat'));


condnames = extractBetween({namefiles.name}, 'temp3d_', '.mat')

allconds = struct()
for c = 1:numel(condnames)
    allconds.(condnames{c}) = []
end

for p = 1:numel(pars)
    thispar = pars(p).name;
    thisdir = fullfile(rootDir, thispar);

    matfiles = dir(fullfile(thisdir, 'temp3d_*.mat'))

    for f = 1:numel(matfiles)
        matname = matfiles(f).name
        cond = extractBetween(matname, 'temp3d_', '.mat')
        cond = cond{1}

        s = load(fullfile(thisdir, matname))
        temp3d = s.temp3d;

        allconds.(cond) = cat(3, allconds.(cond), temp3d)

    end
end

% save grouped condition files
save('allconds.mat',"allconds")


%% wavelet per condition

fs = 500;
faxisall = 0:0.0476:100;
faxis = faxisall(40:20:800);

taxis = -1:0.002:20-0.002; 

conds = fieldnames(allconds);   % get condition names

for i = 1:numel(conds)
    cond = conds{i};            % extract the string (e.g., 'oth', 'neu')
    thisdata = allconds.(cond); % ch × time × trials

    % run wavelet
    [WaPower, PLI, PLIdiff] = wavelet_app_mat(thisdata, fs, 40, 800, 20, [], []);

    figure()

contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar


    % store results
    WaPower_all.(cond)  = WaPower;
    PLI_all.(cond)      = PLI;
    PLIdiff_all.(cond)  = PLIdiff;
end

figure()
contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar

contam = WaPower_all.contam;

contourf(taxis, faxis, squeeze(contam(20, :, :))'), colorbar

%%
temp3d = [];
for p = 1:numel(folder)
    file = fullfile(rootdir, folder(p).name)

    matfiles = dir(fullfile(file, '*2epoch_trls.mat'))
    % matfiles = dir(fullfile(file, '*trls.mat')) %these are trls not
    % conds; will not work correctly for this code

    for k = 1:numel(matfiles)
        filePath = fullfile(file, matfiles(k).name);

        % Load the .mat file
        data = load(filePath);
        data = data.data; % for trls data
        % fprintf('Loaded: %s\n', filePath);

        % for cond = 1:9;
        %     temp = data{cond,2};
        % 
            for x = 1:size(data, 3 )

                % figure(101), plot(squeeze(temp(1:31,:, x))'), title([num2str(cond) '  ' num2str(x)]), pause

                temp3d = cat(3, temp3d, squeeze(data(1:31,:, x)));

            end
        end
end

save("temp3d_alltrials.mat", "temp3d",'-v7.3')



%% wavlet over every trial and all pars; only for sanity check; alpha seen
rootdir = '/Volumes/ELEMENTS/imagery/eeg/'
folder = dir(fullfile(rootdir, 'par_*'))

for p = 1:numel(folder)

    subjDir = fullfile(rootdir, folder(p).name);
    % matfiles = dir(fullfile(subjDir, '*epoched_trls.mat'));
      matfiles = dir(fullfile(subjDir, 'temp3d*'))

    for k = 1:numel(matfiles)

        filePath = fullfile(subjDir, matfiles(k).name);
        S = load(filePath);
        data = S.data;

        fprintf('Loaded: %s\n', filePath);


            [WaPower, PLI, PLIdiff] = wavelet_app_mat( ...
                temp3d, 500, 40, 800, 20, [], []);

            % axes
            faxisall = 0:0.0476:100;
            faxis = faxisall(40:20:800);
            taxis = -1:0.002:20-0.002;

            % % save per participant & condition
            % outname = sprintf('%s_wavelet.mat', ...
            %     pars(p).name, cond);

            save(fullfile(subjDir, outname), ...
                'WaPower', 'PLI', 'PLIdiff', 'faxis', 'taxis', '-v7.3');

            % ---- optional plotting ----
            figure;
            contourf(taxis, faxis, squeeze(WaPower(20,:,:))', 'linecolor','none');
            colorbar;
            title(sprintf('%s – Condition %d', folder(p).name, cond));

        end
end

%% over conditions within pars
clear
rootdir = '/Volumes/ELEMENTS/imagery/eeg/'
folder = dir(fullfile(rootdir, 'par_*'))
temp3d = [];

for p = 1:numel(folder)
    file = fullfile(rootdir, folder(p).name)

    matfiles = dir(fullfile(file, 'temp3d_*.mat'))
    % matfiles = matfiles(~ismember(matfiles.name, '.', '..'));

    % matfiles = dir(fullfile(file, '*trls.mat')) %these are trls not
    % conds; will not work correctly for this code

    for k = 1:numel(matfiles)
        filePath = fullfile(file, matfiles(k).name);

        % Load the .mat file
        load(filePath);
        
        % fprintf('Loaded: %s\n', filePath);

        for cond = 1:9;
            temp = dataOut{cond,2};

            for x = 1:size(temp, 3)

                % figure(101), plot(squeeze(temp(1:31,:, x))'), title([num2str(cond) '  ' num2str(x)]), pause

                temp3d = cat(3, temp3d, squeeze(temp(1:31,:, x)));

            end
        end
    end
end




%% Reduced conditions to P N U
clear
rootDir = '/Volumes/ELEMENTS/imagery/eeg';
cd(rootDir);

pars = dir('par_*');
pars = pars([pars.isdir]);

pleasant_group = {'PerPl', 'ero', 'rew'}
neutral_group = {'PerNeu', 'neu'}
unpleasant_group = {'PerUn', 'contam', 'surv'}


for p = 1:numel(pars)
    thispar = fullfile(rootDir, pars(p).name)
    files = dir(fullfile(thispar, 'temp3d_*.mat'));

    pleasant = [];
    neutral = [];
    unpleasant = [];

    for f = 1:numel(files)

        fname = files(f).name;

        cond = extractBetween(fname, 'temp3d_', '.mat');
        cond = cond{1};

        s = load(fullfile(thispar, fname));
        temp3d = s.temp3d;

        if ismember(cond, pleasant_group)
            pleasant = cat(3, pleasant, temp3d);

        elseif ismember(cond, neutral_group)
            neutral = cat(3, neutral, temp3d);

        elseif ismember(cond, unpleasant_group)
            unpleasant = cat(3, unpleasant, temp3d);
        end
    end

    save(fullfile(thispar, 'pleasant_par.mat'), "pleasant");
    save(fullfile(thispar, 'neutral_par.mat'), 'neutral');
    save(fullfile(thispar, 'unpleasant_par.mat'), "unpleasant");
end


%% wavelet by conds within participant

clear
rootDir = '/Volumes/ELEMENTS/imagery/eeg';
cd(rootDir);

pars = dir('par_*');
pars = pars([pars.isdir]);

for p = 1:numel(pars)
    file = fullfile(rootDir, pars(p).name)

    matfiles = dir(fullfile(file, '*_par.mat'))
    for f = 1:numel(matfiles)
        matpath = fullfile(file, matfiles(f).name)
        condname = extractBetween(matpath, '/', '_par.mat')

        data = load(matpath)
        if isfield(data, 'neutral')
            temp3d = data.neutral;
        elseif isfield(data, 'pleasant')
            temp3d = data.pleasant
        elseif isfield(data, 'unpleasant')
            temp3d = data.unpleasant
        else
            warning('Condition not found in %s', matFiles(f).name);
            continue;
        end
        [WaPower, PLI, PLIdiff] = wavelet_app_mat(temp3d, fs, 40, 800, 20, [], []);

        figure()
        contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar, caxis ([0 7] )
        ylim([1 30])
    end
    pause
end






%% original (with andreas)
[WaPower, PLI, PLIdiff] = wavelet_app_mat(temp3d, 500, 40, 800, 20, [], []);

faxisall = 0:0.0476:100;
faxis = faxisall(40:20:800);

taxis = -1:0.002:20-0.002; 

contourf(taxis, faxis, squeeze(WaPower(20, :, :))'), colorbar
    

