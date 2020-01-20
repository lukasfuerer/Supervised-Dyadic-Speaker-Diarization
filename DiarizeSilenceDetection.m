function silence = DiarizeSilenceDetection(audio, fs, winMinMax, winOutput)

wav = audio;
wavlengthSamples = length(wav);
windowlengthParameter = winMinMax * fs; 
stepParameter = winMinMax * fs; 
windowlength = winOutput *fs; 
step = winOutput * fs; 

% get most common min max
minmax = {};
numwindowsParameter = floor(wavlengthSamples/windowlengthParameter);
curPos = 1;

for i = 1:1:numwindowsParameter
    frame = wav(curPos:curPos+windowlengthParameter-1);
    maximum = max(frame);
    minimum = min(frame);
    minmax{i} = maximum-minimum;
    curPos = curPos+stepParameter;
end

minmax = cell2mat(minmax);
nbins = calcnbins(minmax, 'scott');
binedge = linspace(min(minmax),max(minmax),nbins);
bincountscott = zeros(length(binedge),1);
for i = 1:1:length(bincountscott)-1
    bincountscott(i) = sum(minmax>= binedge(i) & minmax < binedge(i+1));
end

[~, idxmaxscott] = max(bincountscott);
maxvalscott = binedge(idxmaxscott + 4);

% Create Text
curPos = 1;
numwindows = floor((wavlengthSamples-windowlength)/windowlength);
silence = zeros(numwindows,1);

for i = 1:1:numwindows
    frame = wav(curPos:curPos+windowlength-1);
    maximum = max(frame);
    minimum = min(frame);
    minmax = maximum-minimum;
    if minmax <= maxvalscott
        silence(i) = 1;
    end
    curPos = curPos+step;
end

time = 0:windowlength/fs:(numwindows-1) * (windowlength/fs);
silence = table(time', silence);
silence.Properties.VariableNames = {'time', 'silence'};







