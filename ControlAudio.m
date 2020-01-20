function ControlAudio(id, audiodir)


fullpath = what(audiodir); 
if size(fullpath,1) >1
    error('Audio Directory Name is not unique in the Matlab Path. Please specify a unique folder name.')
end

if ismac
    separator = '/';
end
if ispc
    separator = '\';
end
% When using Octave, please uncomment this line
% separator = '//';

fullpath = fullpath.path;
fullpath = strrep(fullpath, [separator audiodir], '');
audiodir = [fullpath separator audiodir separator];
predictiondir = [fullpath separator 'diarizeprediction' separator];

if ~exist([audiodir id '.wav'], 'file')
    error([id '.wav could not be found in the specified audiodirectory.'])
end
if ~exist([predictiondir id '_prediction.txt'], 'file')
    error([id '_prediction.txt could not be found in the diarizeprediction folder on the level of the specified audiodirectory.'])
end

[audio, fs] = audioread([audiodir id '.wav']);
audiotime = 0:1/fs:(length(audio)-1)/fs;
prediction = readtable([predictiondir id '_prediction.txt']);
audiotable = table(audiotime', audio);
pred = outerjoin(prediction, audiotable, 'LeftKeys', 1, 'RightKeys', 1);
pred = table(pred.Var1, pred.AggregatedDiarization, pred.audio, pred.audio);
pred.Properties.VariableNames = {'time', 'prediction', 'audiol', 'audior'};
pred.prediction = fillmissing(pred.prediction, 'previous');
pred.audiol(pred.prediction == 1) = 0;
pred.audior(pred.prediction == 2) = 0;
pred.audiol(pred.prediction == 0) = 0;
pred.audior(pred.prediction == 0) = 0;
audio = [pred.audiol, pred.audior];

if ~exist([fullpath separator 'controlaudio' separator], 'dir')
    mkdir([fullpath separator 'controlaudio' separator])
end
audiowrite([fullpath separator 'controlaudio' separator id '_control.wav'], audio, fs); 

end