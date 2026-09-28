%% 0. Set paths and important variables
rawDir = ''; %raw data directory 
annDir = ''; %where processed HP data are saved
subjs = []; %subject numbers (e.g. 101, 102, 103...)
fs = 5000; %sample rate (in Hz), will later downsample to 500Hz
rrSampRate = 10; %this is just for the manual labeling
qrs_x_path = ''; %where labeled qrs complex (including R peak) indices are saved
reuse_old = false; %tells manual correction program we don't have any presaved qrs indices
bslLength = 3;
qrsPad = round(5833 / 2); %used when splitting training data and testing data 70BPM  / 60s * 5000(sp/s)

%pick train test sets
allSubjects = [113 114 115 116 117 118 120 121 122 123 125 126 127 128 129 130 131 132 133 134 135 140 141 142 143 147 148 149 150 152 153 154 155 158 159 160 161];

rng(1234)
trainIdx = randperm(length(allSubjects),23);
trainSubs = sort(allSubjects(trainIdx));

cvSubs = setxor(trainSubs,allSubjects);

%% 1. Filter and Segment ECG by Phase, Prepare Training Data for CNN via Manual Labeling


%very very lenient finite impulse response (FIR) filters (they don't filter the data much):
%used FIR rather than Butterworth (IIR) filters because they have linear
%phase, so they preserve waveform shape of signal (important when the
%details of waveform shape matter)
fir_lpf = fir1(500,0.04,hann(501)); %100Hz FIR, order = 501
fir_hpf = fir1(10102,0.0002, hann(10103),'high'); %0.5Hz FIR, order = 10102

%Gets rid of gradient artifact in ECG data
for s = 1:length(subjs)
    cleanfMRInoise(subjs(s),5000,rawDir);
end

%this next part is annoying but I think this works best if, rather than use
%a for loop, you update the value of subj (line 24), run the block of code,
%and then update it again. You can try a for loop but I remember that
%causing some problems
subj = [];

%%
subChar = num2str(subj);
subRawFolder = fullfile(rawDir,['sub-' subChar]);

%extract entire ECG time series from EEGLab file, then save as .csv
ECG = pop_loadset('filename',['gaborgen24_MRI_' subChar '_noGradient.set'], 'filepath',subRawFolder);
data = ECG.data;
writematrix(data,['gg24_' subChar '_ecg.csv'])

%filter ECG time series
data_lpf = filtfilt(fir_lpf, 1, data);
data_filt = filtfilt(fir_hpf, 1, data_lpf);

%extract trial onset triggers from EEGLab file
ev = squeeze(struct2cell(ECG.event))';
evTrigs = string(ev(:,7)); %trigger labels
evTimes = cell2mat(ev(:,1)); %trigger times in sample points

%The code below splits data based on conditioning phase (habituation,
%acquisition 1, acquisition 2, extinction) to provide the CNN with training
%data from different points in the experiment. You will want your training
%data to reflect the entirety of the dataset. This means training data must
%come from most or all conditions. If your experiment is long, this may
%also require splitting your time series into sections (early, middle,
%late) as I did based on conditioning phase. Since my trials were fairly
%short (2s), I made the training data the first 40 R peaks from each phase
%(160 R peaks total). Depending on the length and structure of your
%experiment, you may want to use more or less R peaks from each ppt. 

%extract tp of first trial onset trigger (for me, was start of habituation)
habEv_Idx = find(contains(evTrigs,'S 1')); %all hab triggers start with 1
habStart_Idx = habEv_Idx(1);
habStart_Tp = evTimes(habStart_Idx);
habEnd_Idx = habEv_Idx(end);
habEnd_Tp = evTimes(habEnd_Idx);

%extract tps when acquisition 1 starts and acquisition 2 starts  
acqEv_Idx = find(contains(evTrigs,'S 2') | contains(evTrigs,'S121')); %all acq triggers start with 2 or contain 121 (CS+ w/ shock)
acqStart_Idx = acqEv_Idx(1); %trial 1
acqStart_Tp = evTimes(acqStart_Idx);
acqMid_Idx = acqEv_Idx(49); %trial 49
acqMid_Tp = evTimes(acqMid_Idx);

%extracts tp when extinction starts
extEv_Idx = find(contains(evTrigs,'S 3'));
extStart_Idx = extEv_Idx(1);
extStart_Tp = evTimes(extStart_Idx);
extEnd_Idx = extEv_Idx(48);
extEnd_Tp = evTimes(extEnd_Idx);

%extracted trigger tps used to split data by phase
%since the baseline of the first trial of each phase is needed for baseline
%correction, I also took the last 3 seconds before the start of each phase
habData = data_filt(habStart_Tp - bslLength*fs:acqStart_Tp - bslLength*fs);

acqData1 = data_filt(acqStart_Tp - bslLength*fs:acqMid_Tp - bslLength*fs);

acqData2 = data_filt(acqMid_Tp - bslLength*fs:extStart_Tp - bslLength*fs);

extData = data_filt(extStart_Tp - bslLength*fs:extEnd_Tp + 10*fs); 

%MANUAL CORRECTION TIME!
%preproc() opens the GUI for manual correction and outputs a vector of R
%peak indices. I only manually labeled and extracted the first 40 R peaks
%from each conditioning phase. 

%Habituation
qrs_hab = preproc(habData',origSampRate,rrSampRate,qrs_x_path,reuse_old);

qrs_habTrain = qrs_hab(1:40);
habTrainDat = habData(1:qrs_habTrain(40)+qrsPad); %train data R peaks
habTestDat = habData(qrs_habTrain(40)+qrsPad:end); %test data R peaks

%% 
%Acquisition1
qrs_acq1 = preproc(acqData1',fs,rrSampRate,qrs_x_path,reuse_old);

qrs_acq1Train = qrs_acq1(1:40);
acq1TrainDat = acqData1(1:qrs_acq1Train(40)+qrsPad);
acq1TestDat = acqData1(qrs_acq1Train(40)+qrsPad:end);

%%
%Acquisition2
qrs_acq2 = preproc(acqData2',fs,rrSampRate,qrs_x_path,reuse_old);

qrs_acq2Train = qrs_acq2(1:40);
acq2TrainDat = acqData2(1:qrs_acq2Train(40)+qrsPad);
acq2TestDat = acqData2(qrs_acq2Train(40)+qrsPad:end);

%%
%Extinction
qrs_ext = preproc(extData',fs,rrSampRate,qrs_x_path,reuse_old);

qrs_extTrain = qrs_ext(1:40);
extTrainDat = extData(1:qrs_extTrain(40)+qrsPad);
extTestDat = extData(qrs_extTrain(40)+qrsPad:end);

%%
%save ECG data to .csv
writematrix(habTrainDat,fullfile(annDir,['gg24_' subChar '_habTrainfilt.csv']))
writematrix(habTestDat,fullfile(annDir,['gg24_' subChar '_habTestfilt.csv']))

%save R peak indices to .mat as vector
qrs = qrs_habTrain;
save(['gg24_' subChar '_qrs_habTrainfilt.mat'],'qrs')

writematrix(acq1TrainDat,fullfile(annDir,['gg24_' subChar '_acq1Trainfilt.csv']))
writematrix(acq1TestDat,fullfile(annDir,['gg24_' subChar '_acq1Testfilt.csv']))

qrs = qrs_acq1Train;
save(['gg24_' subChar '_qrs_acq1Trainfilt.mat'],'qrs')

writematrix(acq2TrainDat,fullfile(annDir,['gg24_' subChar '_acq2Trainfilt.csv']))
writematrix(acq2TestDat,fullfile(annDir,['gg24_' subChar '_acq2Testfilt.csv']))

qrs = qrs_acq2Train;
save(['gg24_' subChar '_qrs_acq2Trainfilt.mat'],'qrs')

writematrix(extTrainDat,fullfile(annDir,['gg24_' subChar '_extTrainfilt.csv']))
writematrix(extTestDat,fullfile(annDir,['gg24_' subChar '_extTestfilt.csv']))

qrs = qrs_extTrain;
save(['gg24_' subChar '_qrs_extTrainfilt.mat'],'qrs')

%I renamed the files here but I don't remember why or if it matters...
%ecgFiles = getfilesindir(annDir,'*Trainfilt.csv');
%qrsFiles = getfilesindir(annDir,'*Trainfilt.mat');
%for f = 1:size(ecgFiles,1)
%    fname_in = deblank(ecgFiles(f,:));
%    fname_qrs = pwd;
%
%    ecg = readmatrix(fname_in);
%    qrs = preproc(ecg',origSampleRate,rrSampRate,fname_qrs,false);
%    
%    fname_out = [fname_in(1:9) 'qrs_' fname_in(10:end-4) '.mat'];
%    fprintf([num2str(f) '\n'])
%    save(fname_out,'qrs')
%end

%% 2. CNN Parameters & Data Loading
win_s = 0.40; %400ms window containing QRS complex - maybe make this shorter to only contain the R peak?
win = round(win_s * fs); %converts window size from secs to sample points
tol_s = 0.02; %jitter used so the center of the window isn't always the R peak
neg_margin_s = 0.30; %distance of negative window from R peak
if mod(win, 2) == 0, win = win + 1; end %makes sure window length is odd number
h = floor(win / 2); %half of window


%load subjects
subjects = cellstr(string(trainSubs)); 
phases = {'hab','acq1','acq2','ext'};
all_X = []; % To store windows
all_Y = []; % To store labels

for i = 1:length(subjects)
    for i2 = 1:length(phases)
        s = subjects{i};
        p = phases{i2};

        filt_ecg = readmatrix(sprintf('gg24_%s_%sTrainfilt.csv', s, p));

        tmp = load(sprintf('gg24_%s_qrs_%sTrainfilt.mat', s, p));
        r_manual = tmp.qrs;
        
        % Normalization (robust z-score)
        robust_z = @(a) (a - median(a)) / (1.4826 * mad(a, 1) + 1e-8);
        x0 = robust_z(filt_ecg(:));
        N = length(x0);
        
        % Window extraction
        % Filters peaks too close to edges
        r_idx = r_manual(r_manual > h & r_manual < N - h);
        
        % Positive window centers (include R peaks, with slight jitter)
        tol = round(tol_s * fs);
        pos_centers = r_idx + randsample(-tol:tol, length(r_idx), true)';
        pos_centers = pos_centers(pos_centers > h & pos_centers < N - h);
        
        % Negative window centers (far from R peaks)
        neg_margin = round(neg_margin_s * fs);
        forbidden = false(N, 1);
        for r = r_idx'
            idx = max(1, r-neg_margin):min(N, r+neg_margin);
            forbidden(idx) = true;
        end
        valid_neg = find(~forbidden & (1:N)' > h & (1:N)' < N-h);
        neg_centers = randsample(valid_neg, length(pos_centers), false); % 1:1 ratio
        neg_centers = neg_centers(neg_centers > h & neg_centers < N - h);

        %Extract windows into [Win x 1 x 1 x NumSamples]
        centers = [pos_centers; neg_centers];
        labels = [ones(length(pos_centers), 1); zeros(length(neg_centers), 1)];
        
        for j = 1:length(centers)
            c = centers(j);
            window = [x0(c-h:c+h)]; % Shape [win x 3]
            all_X = cat(4, all_X, window);
            all_Y = [all_Y; labels(j)];
        end
    end
end

% Convert labels to categorical for MATLAB classification
all_Y = categorical(all_Y);

%% Convolutional Neural Network

%% 3. Define CNN Architecture

%Regularized CNN
layers = [
    imageInputLayer([win 1 1], 'Normalization', 'none') % Input layer for data entry
    
    convolution2dLayer([7 1], 8, 'Padding', 'same') % Wide convolution filters, looks at overall waveform shapes
    leakyReluLayer(0.01) % if neuron's value is negative, isn't killed (set to 0), so model can learn from signal dips
    maxPooling2dLayer([2 1], 'Stride', [2 1]) % reduces resolution of signal by half, keeps only strongest features
    
    convolution2dLayer([5 1], 16, 'Padding', 'same') % Medium conv filter, identifies patterns between peaks
    leakyReluLayer(0.01) % if neuron's value is negative, isn't killed (set to 0), so model can learn from signal dips
    dropoutLayer(0.2) % 20% Dropout of features to prevent overfitting, over-reliance on single data points
    maxPooling2dLayer([2 1], 'Stride', [2 1]) % reduces resolution of signal by half, keeps only strongest features
    
    convolution2dLayer([3 1], 32, 'Padding', 'same') % Refinement conv filter, used to confirm precise center of peak 
    leakyReluLayer(0.01) % if neuron's value is negative, isn't killed (set to 0), so model can learn from signal dips
    dropoutLayer(0.3) % Higher dropout in deeper layers
    
    globalAveragePooling2dLayer() % takes average of each filter's entire output to drastically reduce number of parameters, prevents model from memorizing peak timings
    fullyConnectedLayer(2) % takes compressed features from GAP layer, maps them to 2 numbers representing Class 0 (no peak) and Class 1 (Peak)
    softmaxLayer()]; % turns 2 numbers into probabilities that sum to 100%


%% 4. Setup CV Data 

% Example: Load your subjects (Update filenames as needed)
subjects_cv = cellstr(string(cvSubs)); 
phases = {'hab','acq1','acq2','ext'};
cv_X = []; % To store windows
cv_Y = []; % To store labels

for i = 1:length(subjects_cv)
    for i2 = 1:length(phases)
        s = subjects_cv{i};
        p = phases{i2};

        filt_ecg = readmatrix(sprintf('gg24_%s_%sTrainfilt.csv', s, p));

        tmp = load(sprintf('gg24_%s_qrs_%sTrainfilt.mat', s, p));
        r_manual = tmp.qrs;
        
        % Normalization (robust z-score)
        robust_z = @(a) (a - median(a)) / (1.4826 * mad(a, 1) + 1e-8);
        x0 = robust_z(filt_ecg(:));
        N = length(x0);
        
        % Window extraction
        % Filters peaks too close to edges
        r_idx = r_manual(r_manual > h & r_manual < N - h);
        
        % Positive window centers (include R peaks)
        % tol = round(tol_s * fs);
        pos_centers = r_idx; %randsample(-tol:tol, length(r_idx), true)';
        
        % Negative window centers (far R from peaks)
        neg_margin = round(neg_margin_s * fs);
        forbidden = false(N, 1);
        for r = r_idx'
            idx = max(1, r-neg_margin):min(N, r+neg_margin);
            forbidden(idx) = true;
        end
        valid_neg = find(~forbidden & (1:N)' > h & (1:N)' < N-h);
        neg_centers = randsample(valid_neg, length(pos_centers), false); % 1:1 ratio
        
        % Extract Windows into vector [Win x 2 x 1 x NumSamples]
        centers_cv = [pos_centers; neg_centers];
        labels = [ones(length(pos_centers), 1); zeros(length(neg_centers), 1)];
        
        for j = 1:length(centers_cv)
            c = centers_cv(j);
            window = [x0(c-h:c+h)]; % Shape [win x 2]
            cv_X = cat(4, cv_X, window);
            cv_Y = [cv_Y; labels(j)];
        end
    end
end
cv_Y = categorical(cv_Y);

%% 4. Training Options
% You may need to adjust these, especially the LearnRateDropFactor,
% LearnRateDropPeriod, MiniBatchSize, and ValidationPatience
% More details here: https://www.mathworks.com/help/deeplearning/ref/trainingoptions.html

options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.2, ...
    'LearnRateDropPeriod', 15, ...
    'MaxEpochs', 200, ...
    'MiniBatchSize', 4, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {cv_X, cv_Y}, ...
    'ValidationFrequency', 100, ...
    'ValidationPatience', 50, ...
    'Metrics', "accuracy", ...
    'OutputNetwork', 'best-validation-loss', ...
    'Plots', 'training-progress', ...
    'Verbose', false);

% Train the model
[net, info] = trainnet(all_X, all_Y, layers, "crossentropy", options);

% Save the trained model
save('gg24_trainedCNN_Apr15_filtOnly_win0.4s.mat','net','info','options','layers');
%% Evaluate Model 

% Track training performance metrics
numIterationsPerEpoch = floor(length(all_Y) / options.MiniBatchSize); 
trainingLossByIteration = info.TrainingHistory.Loss; %Loss function
trainingAccuracyByIteration = info.TrainingHistory.Accuracy; %Accuracy

% Calculate loss per epoch
epochLoss = [];
for e = 1:options.MaxEpochs
    idx = (e-1)*numIterationsPerEpoch + 1 : e*numIterationsPerEpoch;
    epochLoss(e) = mean(trainingLossByIteration(idx));
end

% Calculate accuracy per epoch
epochAcc = [];
for e = 1:options.MaxEpochs
    idx = (e-1)*numIterationsPerEpoch + 1 : e*numIterationsPerEpoch;
    epochAcc(e) = mean(trainingAccuracyByIteration(idx));
end

% Track CV Performance metrics during training
numCvsPerEpoch = 19;
cvEpochLoss = [];
for e = 1:height(info.ValidationHistory)
    idx = (e-1)*numCvsPerEpoch + 1 : e*numCvsPerEpoch;
    cvEpochLoss(e) = mean(trainingLossByIteration(idx));
end

cvEpochAcc = [];
for e = 1:height(info.ValidationHistory)
    idx = (e-1)*numCvsPerEpoch + 1 : e*numCvsPerEpoch;
    cvEpochAcc(e) = mean(trainingAccuracyByIteration(idx));
end

%Cross validation performance metrics using best model
%CV Loss
scores = predict(net,cv_X);
p = scores(:,2);
y = double(cv_Y == "1");
epsilon = 1e-7;
p_clipped = min(max(p, epsilon), 1 - epsilon);
individual_losses = -(y .* log(p_clipped) + (1 - y) .* log(1-p_clipped));
cv_loss = mean(individual_losses); % should ideally be 0.1 or less

% CV Confusion matrix
cv_cats = categories(cv_Y);
[label,score] = scores2label(scores,cv_cats);
confmat = confusionmat(label, cv_Y);
cm = confusionchart(cv_Y,label);


%% 4. Prediction / Inference Function
% Automatically labels test data by calculating probability of an R peak
% for every 5th sample point

allSubjects = cellstr(string(allSubjects));

for i = 1:length(allSubjects)
    tic
    for i2 = 1:length(phases)

        s = allSubjects{i};
        ph = phases{i2};

        test_ecg = readmatrix(sprintf('gg24_%s_%sTestfilt.csv', s, ph));
        x0_test = robust_z(test_ecg(:));

        probs = zeros(size(x0_test));
        for c = (h+1):5:(length(x0_test)-h) % Step by 5 for speed
            win_data = [x0_test(c-h:c+h)];
            score = predict(net, win_data);
            probs(c) = score(2); % Probability of "Peak"
        end

        
        % Post-processing: Find peaks in probability trace
        [~, cand_locs] = findpeaks(probs, 'MinPeakHeight', 0.9, 'MinPeakDistance', round(0.5*fs));
        
        % Refinement: Snap to local max in original signal
        r_pred = zeros(size(cand_locs));
        sw = round(0.08 * fs);
        for k = 1:length(cand_locs)
            c = cand_locs(k);
            range = max(1, c-sw):min(length(test_ecg), c+sw);
            [~, local_idx] = max(test_ecg(range));
            r_pred(k) = range(1) + local_idx - 1;
        end
        
        save(sprintf('gg24_%s_qrs_%sTestfilt.mat', s, ph), 'probs', 'r_pred')

        fprintf('Subject: %s, %s \n', s, ph)
    end
    toc
end

% Plot results
t = (0:length(test_ecg)-1)/fs;
figure;
ecgRplt = subplot(2,1,1); plot(t, test_ecg); hold on; plot(t(r_pred), test_ecg(r_pred), 'ro'); axis tight; title('Detected R-peaks');
probplt = subplot(2,1,2); plot(t, probs); title('CNN Probability Trace'); axis tight, linkaxes([ecgRplt, probplt], 'x')

save('results/gg24_121_qrs_extTestfilt.mat','r_pred','probs')

%% 5. Reconstruct ECG data with CNN Results, Manual Correction, Heart Period Calculation

%If you're doing manual correction, you can't use the for loop, instead
%specify index of the subject you're processing
s = [];

for s = 1:length(subjects)
    subInt = subjects(s);
    subChar = num2str(subjects(s));
    subRawFolder = fullfile(rawDir,['sub-' subChar]);

%% Reconstruct ECG Data
    
    % load ECG and QRS data for training and testing data, then concatenate
    % Habituation
    trainHab_ecg = readmatrix(['gg24_' subChar '_habTrainfilt.csv']);
    tmp = load(['gg24_' subChar '_qrs_habTrainfilt.mat']);
    trainHab_r = tmp.qrs;
    testHab_ecg = readmatrix(['gg24_' subChar '_habTestfilt.csv']);
    tmp2 = load(['gg24_' subChar '_qrs_habTestfilt.mat']);
    testHab_r = tmp2.r_pred;
    
    hab_ecg = [trainHab_ecg testHab_ecg(2:end)];
    qrs_cnnHab = [trainHab_r; (testHab_r - 1 + trainHab_r(end) + qrsPad)];
    
    % Acquisition 1
    trainAcq1_ecg = readmatrix(['gg24_' subChar '_acq1Trainfilt.csv']);
    tmp = load(['gg24_' subChar '_qrs_acq1Trainfilt.mat']);
    trainAcq1_r = tmp.qrs;
    testAcq1_ecg = readmatrix(['gg24_' subChar '_acq1Testfilt.csv']);
    tmp2 = load(['gg24_' subChar '_qrs_acq1Testfilt.mat']);
    testAcq1_r = tmp2.r_pred;
    
    acq1_ecg = [trainAcq1_ecg testAcq1_ecg(2:end)];
    qrs_cnnAcq1 = [trainAcq1_r; (testAcq1_r - 1 + trainAcq1_r(end) + qrsPad)];
    
    % Acquisition 2
    trainAcq2_ecg = readmatrix(['gg24_' subChar '_acq2Trainfilt.csv']);
    tmp = load(['gg24_' subChar '_qrs_acq2Trainfilt.mat']);
    trainAcq2_r = tmp.qrs;
    testAcq2_ecg = readmatrix(['gg24_' subChar '_acq2Testfilt.csv']);
    tmp2 = load(['gg24_' subChar '_qrs_acq2Testfilt.mat']);
    testAcq2_r = tmp2.r_pred;
    
    acq2_ecg = [trainAcq2_ecg testAcq2_ecg(2:end)];
    qrs_cnnAcq2 = [trainAcq2_r; (testAcq2_r - 1 + trainAcq2_r(end) + qrsPad)];
    
    % Extinction
    trainExt_ecg = readmatrix(['gg24_' subChar '_extTrainfilt.csv']);
    tmp = load(['gg24_' subChar '_qrs_extTrainfilt.mat']);
    trainExt_r = tmp.qrs;
    testExt_ecg = readmatrix(['gg24_' subChar '_extTestfilt.csv']);
    tmp2 = load(['gg24_' subChar '_qrs_extTestfilt.mat']);
    testExt_r = tmp2.r_pred;
    
    ext_ecg = [trainExt_ecg testExt_ecg(2:end)];
    qrs_cnnExt = [trainExt_r; (testExt_r - 1 + trainExt_r(end) + qrsPad)];

%% MANUAL CORRECTION (again!)
%Habituation
qrs_cnnHab = preproc_jp(hab_ecg,5000,10,qrs_cnnHab);

%Acquisition 1
qrs_cnnAcq1 = preproc_jp(acq1_ecg,5000,10,qrs_cnnAcq1);

%Acquisition 2
qrs_cnnAcq2 = preproc_jp(acq2_ecg,5000,10,qrs_cnnAcq2);

%Extinction
qrs_cnnExt = preproc_jp(ext_ecg,5000,10,qrs_cnnExt);

%% Recombine experimental phases into one time series
    habLen = length(hab_ecg);
    acq1Len = length(acq1_ecg);
    acq2Len = length(acq2_ecg);
    extLen = length(ext_ecg);
    %ECG data
    ecg_long = [hab_ecg acq1_ecg(2:end) acq2_ecg(2:end) ext_ecg(2:end)];
    %QRS data (R peak indices)
    qrs_x = [qrs_cnnHab; (qrs_cnnAcq1 + habLen); (qrs_cnnAcq2 + acq1Len + habLen); (qrs_cnnExt + habLen + acq1Len + acq2Len)];
    
    %qrs_x = preproc_jp(ecg_long, 5000, 10, qrs_x);
    
    %load(['gg24_' subChar '_qrs_x.mat'])
    save(['gg24_' subChar '_qrs_x.mat'],'qrs_x')
    
    fs = 5000;
    fs_new = 500;
    ecg_len_t = length(ecg_long)./fs; %convert to time in secs
    qrs_t = qrs_x./fs; %convert to time in secs
    [Rstamps_insecs, IBIvec, time_insecs_resampled, hp] = calculate_RR_jp2(qrs_t, ecg_len_t, fs_new, 'linear');

%% Segment HP by condition

    % Extract trial onset triggers from EEGLab file
    ECG = pop_loadset('filename',['gaborgen24_MRI_' subChar '_noGradient.set'], 'filepath',subRawFolder);

    % Resample trigger times so they match sampling rate of HP data
    ECG_ds = pop_resample(ECG, 500);
    event_times = [ECG.event.latency]; 
    event_times_ds = [ECG_ds.event.latency];
    event_names = strings(size(event_times));

    % Save trigger names to string vector
    for ev = 1:length(event_times)
        ev_str = convertCharsToStrings(ECG_ds.event(ev).type);
        event_names(ev) = ev_str;
    end
    
    % Extract first trigger
    habEv_Idx = find(contains(event_names,'S 1'));
    habStart_Idx = habEv_Idx(1);
    habStart_Tp_ds = event_times_ds(habStart_Idx);
    habStart_Tp = event_times(habStart_Idx);
    
    exp_length_insecs = (length(ecg_long)./fs);
    trig_offset_ds = habStart_Tp_ds - (3*fs_new + 1);
    event_times_exp_ds = event_times_ds - trig_offset_ds;
    trig_offset = habStart_Tp - (3*fs + 1);
    event_times_exp = event_times - trig_offset;
    
    bslLength = 3;
    trialLength = 8;
    all_time_insecs_resampled = 0:1/fs_new:exp_length_insecs;
    
    % Habituation CS+
    % Segment HP time series into trials based on triggers
    [hp_11] = hp_rs_segment(hr,all_time_insecs_resampled,"S 11",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    % Segment ECG time series and QRS data into trials based on triggers
    [ecg_11,qrs_11] = ecg_qrs_segment(ecg_long,qrs_x,"S 11", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Habituation GS1
    [hp_12] = hr_rs_segment(hr,all_time_insecs_resampled,"S 12",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_12,qrs_12] = ecg_qrs_segment(ecg_long,qrs_x,"S 12", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Habituation GS2
    [hp_13] = hr_rs_segment(hr,all_time_insecs_resampled,"S 13",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_13,qrs_13] = ecg_qrs_segment(ecg_long,qrs_x,"S 13", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Habituation GS3
    [hp_14] = hr_rs_segment(hr,all_time_insecs_resampled,"S 14",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_14,qrs_14] = ecg_qrs_segment(ecg_long,qrs_x,"S 14", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Acquisition CS+ (w/ and w/o shock)
    [hp_20] = hr_rs_segment(hr,all_time_insecs_resampled,["S 21", "S121"],event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_20,qrs_20] = ecg_qrs_segment(ecg_long,qrs_x,["S 21", "S121"], event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Acquisition CS+ (w/o shock)
    [hp_21] = hr_rs_segment(hr,all_time_insecs_resampled,"S 21",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_21,qrs_21] = ecg_qrs_segment(ecg_long,qrs_x,"S 21", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Acquisition GS1 
    [hp_22] = hr_rs_segment(hr,time_insecs_resampled,"S 22",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_22,qrs_22] = ecg_qrs_segment(ecg_long,qrs_x,"S 22", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Acquisition GS2
    [hp_23] = hr_rs_segment(hr,time_insecs_resampled,"S 23",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_23,qrs_23] = ecg_qrs_segment(ecg_long,qrs_x,"S 23", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Acquisition GS3
    [hp_24] = hr_rs_segment(hr,time_insecs_resampled,"S 24",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_24,qrs_24] = ecg_qrs_segment(ecg_long,qrs_x,"S 24", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Extinction CS+
    [hp_31] = hr_rs_segment(hr,time_insecs_resampled,"S 31",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_31,qrs_31] = ecg_qrs_segment(ecg_long,qrs_x,"S 31", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Extinction GS1
    [hp_32] = hr_rs_segment(hr,time_insecs_resampled,"S 32",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_32,qrs_32] = ecg_qrs_segment(ecg_long,qrs_x,"S 32", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Extinction GS2
    [hp_33] = hr_rs_segment(hr,time_insecs_resampled,"S 33",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_33,qrs_33] = ecg_qrs_segment(ecg_long,qrs_x,"S 33", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Extinction GS3
    [hp_34] = hr_rs_segment(hr,time_insecs_resampled,"S 34",event_names,event_times_exp_ds,fs_new,bslLength,trialLength);
    [ecg_34,qrs_34] = ecg_qrs_segment(ecg_long,qrs_x,"S 34", event_names, event_times_exp, bslLength, trialLength, 5000);
    
    % Save segmented ECG (for data inspection)
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S11_ecg_cnn.mat']),'ecg_11');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S12_ecg_cnn.mat']),'ecg_12');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S13_ecg_cnn.mat']),'ecg_13');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S14_ecg_cnn.mat']),'ecg_14');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S21_ecg_cnn.mat']),'ecg_21');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S22_ecg_cnn.mat']),'ecg_22');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S23_ecg_cnn.mat']),'ecg_23');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S24_ecg_cnn.mat']),'ecg_24');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S31_ecg_cnn.mat']),'ecg_31');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S32_ecg_cnn.mat']),'ecg_32');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S33_ecg_cnn.mat']),'ecg_33');
    save(fullfile(ecgDir,['gaborgen24_MRI_' subChar '_S34_ecg_cnn.mat']),'ecg_34');

    % Save segmented HP and QRS
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S11_hp_cnn.mat']),'hp_11');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S11_qrs_cnn.mat']),'qrs_11');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S12_hp_cnn.mat']),'hp_12');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S12_qrs_cnn.mat']),'qrs_12');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S13_hp_cnn.mat']),'hp_13');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S13_qrs_cnn.mat']),'qrs_13');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S14_hp_cnn.mat']),'hp_14');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S14_qrs_cnn.mat']),'qrs_14');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S20_hp_cnn.mat']),'hp_20');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S20_qrs_cnn.mat']),'qrs_20');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S21_hp_cnn.mat']),'hp_21');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S21_qrs_cnn.mat']),'qrs_21');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S22_hp_cnn.mat']),'hp_22');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S22_qrs_cnn.mat']),'qrs_22');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S23_hp_cnn.mat']),'hp_23');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S23_qrs_cnn.mat']),'qrs_23');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S24_hp_cnn.mat']),'hp_24');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S24_qrs_cnn.mat']),'qrs_24');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S31_hp_cnn.mat']),'hp_31');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S31_qrs_cnn.mat']),'qrs_31');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S32_hp_cnn.mat']),'hp_32');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S32_qrs_cnn.mat']),'qrs_32');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S33_hp_cnn.mat']),'hp_33');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S33_qrs_cnn.mat']),'qrs_33');
    save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S34_hp_cnn.mat']),'hp_34');
    save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S34_qrs_cnn.mat']),'qrs_34');       


end



%% 6. Plot each trial for data inspection, to determine bad trials
taxis = -3:1/fs_new:8;
taxis2 = -3:1/fs:8;

for tr = 1:size(hp_11,1)
    qrs_tr = round(qrs_11{tr});
    figure, subplot(2,1,1), plot(taxis, hp_11(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Hab CS+ trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_11(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_11(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_12,1)
    qrs_tr = round(qrs_12{tr});
    figure, subplot(2,1,1), plot(taxis, hp_12(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Hab GS1 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_12(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_12(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_13,1)
    qrs_tr = round(qrs_13{tr});
    figure, subplot(2,1,1), plot(taxis, hp_13(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Hab GS2 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_13(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_13(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_14,1)
    qrs_tr = round(qrs_14{tr});
    figure, subplot(2,1,1), plot(taxis, hp_14(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Hab GS3 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_14(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_14(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

hp_21 = hr_bslcorr(hp_21,qrs_21,stim_on,fs);
for tr = flip(1:size(hp_21,1))
    qrs_tr = round(qrs_21{tr});

    figure, subplot(2,1,1), plot(taxis, hp_21(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Acq CS+ trial ' num2str(tr)])
    hold on, rectangle('Position', [1.5 min(hp_21(tr,:)) 2 max(hp_21(tr,:))-min(hp_21(tr,:))], 'FaceColor', "none", 'EdgeColor', 'r','lineWidth', 3)
    subplot(2,1,2), plot(ecg_21(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_21(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    %pause, close all
end

hp_22 = hr_bslcorr(hp_22,qrs_22,stim_on,fs);
for tr = flip(1:size(hp_22,1))

    qrs_tr = round(qrs_22{tr});
    figure, subplot(2,1,1), plot(taxis, hp_22(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Acq GS1 trial ' num2str(tr)])
    hold on, rectangle('Position', [1.5 min(hp_22(tr,:)) 2 max(hp_22(tr,:))-min(hp_22(tr,:))], 'FaceColor', "none", 'EdgeColor', 'r','lineWidth', 3)
    subplot(2,1,2), plot(ecg_22(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_22(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    %pause, close all
end

hp_23 = hr_bslcorr(hp_23,qrs_23,stim_on,fs);
for tr = flip(1:size(hp_23,1))
    qrs_tr = round(qrs_23{tr});
    figure, subplot(2,1,1), plot(taxis, hp_23(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Acq GS2 trial ' num2str(tr)])
    hold on, rectangle('Position', [1.5 min(hp_23(tr,:)) 2 max(hp_23(tr,:))-min(hp_23(tr,:))], 'FaceColor', "none", 'EdgeColor', 'r','lineWidth', 3)
    subplot(2,1,2), plot(ecg_23(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_23(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    %pause, close all
end

hp_24 = hr_bslcorr(hp_24,qrs_24,stim_on,fs);
for tr = flip(1:size(hp_24,1))
    qrs_tr = round(qrs_24{tr});
    figure, subplot(2,1,1), plot(taxis, hp_24(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Acq GS3 trial ' num2str(tr)])
    hold on, rectangle('Position', [1.5 min(hp_24(tr,:)) 2 max(hp_24(tr,:))-min(hp_24(tr,:))], 'FaceColor', "none", 'EdgeColor', 'r','lineWidth', 3)
    subplot(2,1,2), plot(ecg_24(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_24(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    %pause, close all
end

for tr = 1:size(hp_31,1)
    qrs_tr = round(qrs_31{tr});
    figure, subplot(2,1,1), plot(taxis, hp_31(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Ext CS+ trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_31(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_31(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_32,1)
    qrs_tr = round(qrs_32{tr});
    figure, subplot(2,1,1), plot(taxis, hp_32(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Ext GS1 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_32(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_32(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_33,1)
    qrs_tr = round(qrs_33{tr});
    figure, subplot(2,1,1), plot(taxis, hp_33(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Ext GS2 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_33(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_33(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

for tr = 1:size(hp_34,1)
    qrs_tr = round(qrs_34{tr});
    figure, subplot(2,1,1), plot(taxis, hp_34(tr,:),'k','lineWidth',3), xline(0, 'lineWidth', 1), xlabel('Time (ms)'), ylabel('HR'), axis tight,
    title(['Ext GS3 trial ' num2str(tr)])
    subplot(2,1,2), plot(ecg_34(tr,:),'k'), xlabel('Time (ms)'), hold on, scatter(qrs_tr, ecg_34(tr,qrs_tr), 50, 'filled', 'Color', [1 0 0]), ylabel('Amplitude (μV)'), axis tight,
    set(gcf,'Position',[12,325,1201,828])
    pause, close all
end

%% 7. Remove bad trials
%Requires .csv file which lists bad trials for each condition, for each
%subject

for s = 1:length(subjects)

    subChar = num2str(subjects(s));

    badTrials = readcell('gg24_badTrials.csv'); %.csv must be filled in manually
    conds = ['11';'12';'13';'14';'21';'22';'23';'24';'31';'32';'33';'34'];
    subConds = badTrials(s,2:end);
    if any(~ismissing(subConds))
        for c = 1:size(conds,1)
            if ischar(subConds{c})
                badCond = str2num(subConds{c});
                load(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S' conds(c,:) '_hp_cnn.mat']));
            elseif isnumeric(subConds{c})
                badCond = subConds{c};
                load(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S' conds(c,:) '_hp_cnn.mat']));
            elseif ismissing(subConds{c})   
                continue
            end
            
            eval(['hp_' num2str(conds(c,:)) '(badCond,:) = NaN;']);
            %eval(['qrs_' num2str(conds(c,:)) '(badCond) = {NaN};']);
            save(fullfile(hpDir,['gaborgen24_MRI_' subChar '_S' num2str(conds(c,:)) '_hp_cnn.mat']),['hp_' num2str(conds(c,:))]);
            %save(fullfile(qrsDir,['gaborgen24_MRI_' subChar '_S' num2str(conds(c,:)) '_qrs_cnn.mat']),['qrs_' num2str(conds(c,:))]);
    
        end
    end 
end