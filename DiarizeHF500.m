function hf500 = DiarizeHF500(audio, fs)

window = 0.1; % in Sekunden

nwindows = floor((length(audio) / fs) / window);
windowfs = window * fs;
        
time = [];
hf500 = [];
        
        for j = 1:1:nwindows
            
            if j == 1
                x = audio(1:windowfs);
                psdestx = psd(spectrum.periodogram,x,'Fs',fs,'NFFT',length(x));
                pwrlow = avgpower(psdestx,[50 500]);
                pwrhigh = avgpower(psdestx,[500 3500]);
                hf500 = [hf500 pwrhigh/pwrlow];
                time = [time 0];
            else
                x = audio((j-1)*windowfs: j*windowfs);
                psdestx = psd(spectrum.periodogram,x,'Fs',fs,'NFFT',length(x));
                pwrlow = avgpower(psdestx,[50 500]);
                pwrhigh = avgpower(psdestx,[500 3500]);
                hf500 = [hf500 pwrhigh/pwrlow];
                time = [time (j-1)*window];
            end
            
        end
        
        hf500 = table(time', hf500');
        hf500.Properties.VariableNames = {'time', 'hf500'};
end

