%% Diarize Example

% Add the Repository to your Matlab Path

Diarize('exampleaudio', 'examplelearningset');

% Create an audio file to listen to the Prediction
% Speaker 1 on right ear, Speaker 2 on left ear, Silence -> audio left and
% right == 0

ControlAudio('1624-168623.8838-298545_1', 'exampleaudio');


