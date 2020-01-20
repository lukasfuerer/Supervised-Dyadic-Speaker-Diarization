% Dyadic Speaker Diarization using Random Forests

function Diarize(audiodir, learndir, vadP1, vadP2, sdWin)

%% Check Vars
if ~exist('audiodir','var')
  error('Please specify an audio directory.')
end
if ~exist(audiodir, 'dir')
    error('Audio Directory could not be found in Matlab path')
end
if ~exist('learndir','var')
  error('Please specify an audio directory.')
end
if ~exist(learndir, 'dir')
    error('Audio Directory could not be found in Matlab path')
end

if ~exist('vadP1','var')
  vadP1=0.1;
end
if ~exist('vadP2','var')
  vadP2=20;
end
if ~exist('sdWin','var')
  sdWin=0.01;
end

%% Folder Structure
    
if ismac
    separator = '/';
end
if ispc
    separator = '\';
end

fullpath = what(audiodir); 
if size(fullpath,1) >1
    error('Audio Directory Name is not unique in the Matlab Path. Please specify a unique folder name.')
end
fullpath = fullpath.path;
fullpath = strrep(fullpath, [separator audiodir], '');
learndirpath = what(learndir); 
if size(learndirpath,1) >1
    error('Learning Set Directory Name is not unique in the Matlab Path. Please specify a unique folder name.')
end

fullpath = [fullpath separator];
audiodir = [fullpath audiodir separator];
learndir = [fullpath learndir separator];
featuresdir = [fullpath 'diarizefeatures' separator];
if ~exist(featuresdir, 'dir')
       mkdir(featuresdir)
end
diarizationmodelsdir = [fullpath 'diarizemodels' separator];
if ~exist(diarizationmodelsdir, 'dir')
       mkdir(diarizationmodelsdir)
end
predictiondir = [fullpath 'diarizeprediction' separator];
if ~exist(predictiondir, 'dir')
       mkdir(predictiondir)
end
intermediatedir = [fullpath 'intermediate' separator];
if ~exist(intermediatedir, 'dir')
       mkdir(intermediatedir)
end
delete([intermediatedir '*'])

%% Filename Structure
list = dir(audiodir);
filenames = {list.name}; 
filenames(cellfun(@isempty,regexp(filenames, '_', 'match'))) = [];
filenames(~cellfun(@isempty,regexp(filenames, 'DS_Store', 'match'))) = [];
if isempty(filenames)
    error('No Filenames in the Audio Directory were found with _ in their filenames.')
end
OverArchingFileNames = filenames;
for f = 1:1:length(OverArchingFileNames)
    fname = OverArchingFileNames{f};
    
    % Amount of _ in filename:
    [~, idxunderline] = regexp(fname, '_', 'match');
    if length(idxunderline) > 1
        disp([fname ': Could not be used, because there are too many _ in the filename.']);
        continue;
    end
    
    [audio, fs] = audioread([audiodir fname]);
    if size(audio,2)>1
    audio = sum(audio,2)/2;
    end

    DyadID = fname(1:idxunderline-1); SessionID = fname(idxunderline+1:end); SessionID = strrep(SessionID, '.wav', '');
    
    disp(['Working on ' DyadID '_' SessionID]);
    
%% 1. Check if Features of the Session to diarize exist
if exist([featuresdir  DyadID '_' SessionID '_features.txt']) == 0
    features = DiarizeFeatureExtraction(audio, fs, 0.1, 0.1, DyadID, SessionID, vadP1, vadP2, sdWin, intermediatedir);
    writetable(features, [featuresdir DyadID '_' SessionID '_features.txt'], 'Delimiter', ';');
    disp([DyadID '_' SessionID ': Features saved.'])
else
    disp([DyadID '_' SessionID ': Features already saved.'])
end

%% Are there Learning Set files to build a Learning Set and Diarization Model?
list = dir(learndir);
filenames = {list.name}; 
filenames(cellfun(@isempty,regexp(filenames, DyadID, 'match'))) = [];
filenamesLearning = filenames;
if isempty(filenamesLearning)
        % No Learning Set Files were found, a learning set has to be
        % created for this dyad
        error([DyadID ': No Files were found for this dyad in the Learning Set Folder.'])
else
%% Learning Set Files were found to create a Learning Set, are there also ALL corresponding audio files? If not, no learning will be done for this dyad.
        for i = 1:1:length(filenamesLearning)
            fname = strrep(filenamesLearning{i}, '.txt', '.wav');
            if ~exist([audiodir fname])
                error([fname ' was not found in the Audio Directory but it is needed to create a complete LearningSet. Please add it to the Audio Directory.'])
            end
        end
        
%% Learning Set Files were found and all corresponding Audio Files were found. Do also the Features Exist? If not create Features for all Learning Set relevant Audio Files.
        for i = 1:1:length(filenamesLearning)
            if ~exist([featuresdir strrep(filenamesLearning{i}, '.txt', '') '_features.txt'])
                DyadIDLearning = DyadID;
                SessionIDLearning = strrep(filenamesLearning{i}, '.txt', '');
                [~, idx] = regexp(SessionIDLearning, '_', 'match'); 
                SessionIDLearning = SessionIDLearning(idx+1:end);
                
                [audioLearning, fsLearning] = audioread([audiodir DyadIDLearning '_' SessionIDLearning '.wav']);
                features = DiarizeFeatureExtraction(audioLearning, fsLearning, 0.1, 0.1, DyadIDLearning, SessionIDLearning, vadP1, vadP2, sdWin, intermediatedir);
                writetable(features, [featuresdir DyadIDLearning '_' SessionIDLearning '_features.txt'], 'Delimiter', ';');
                disp([DyadIDLearning '_' SessionIDLearning ': Features saved. It is needed for creating the Learning Set.'])
            end
        end
        
%% Check whether a Diarization Model exists for this dyad, if not, Train a Model
    if ~exist([diarizationmodelsdir DyadID '_DiarizationModel.mat'])
        % Learning Set Files were found and all corresponding Audio Files
        % were found. Also, all Features were created for the Learning Set
        % Files, Conditions are met to train a Diarization Model
        Mdl = DiarizeLearning(DyadID, learndir, featuresdir);
        save([diarizationmodelsdir DyadID '_DiarizationModel.mat'], 'Mdl');
        disp([DyadID ': Diarization Model was trained']);   
    end

%% All Conditions are met to Predict the Speakers
    if ~exist([predictiondir DyadID '_' SessionID '_prediction.txt'])
    model = load([diarizationmodelsdir DyadID '_DiarizationModel.mat']);
    model = model.Mdl;
    features = readtable([featuresdir DyadID '_' SessionID '_features.txt']);
    time = features.time; 
    silence = features.silence;
    vad = features.vad;
    
    features.time = [];
    features.silence = []; features.silence_Minus1 = []; features.silence_Minus2 = [];
    features.vad = []; features.vad_Minus1 = []; features.vad_Minus2 = [];
    prediction = predict(model, features);
    prediction = table(time, silence, vad, prediction);
    prediction.Properties.VariableNames = {'time', 'silence', 'vad', 'prediction'};
    prediction.prediction = cell2mat(prediction.prediction); prediction.prediction = str2num(prediction.prediction);
    prediction.AggregatedDiarization = nan(height(prediction),1);
    prediction.AggregatedDiarization(prediction.silence == 1) = 0;
    prediction.AggregatedDiarization(prediction.silence == 0) = prediction.vad(prediction.silence == 0);
    prediction.AggregatedDiarization(prediction.AggregatedDiarization == 1) = prediction.prediction(prediction.AggregatedDiarization == 1);
    writetable(prediction, [predictiondir DyadID '_' SessionID '_prediction.txt'], 'Delimiter', ';');
    disp([DyadID '_' SessionID ': Prediction saved!'])
    else
        disp([DyadID '_' SessionID ': Prediction was already saved!'])
    end

if f == length(OverArchingFileNames)
    rmdir(intermediatedir);
end
end

end