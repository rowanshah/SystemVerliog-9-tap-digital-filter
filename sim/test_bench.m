 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %% test_bench.m
 %% Philip Watts, 26th July 2011
 %% Department of Electronic and Electrical Engineering, UCL
 %% 
 %% MATLAB verification script for the FIR filter
 %% Generates a test signal, calls modelsim to simulate the verilog
 %% code with the test signal as stimulus.  Displays the input and 
 %% ouput waveforms from the FIR filter along with the expected 
 %% waveforms.  Provides hints for debugging in common problem cases. 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
delete('fir_out.txt');
delete('fir_in.txt');

%%%%%%%%%%%%%%%% Define Top Level Parameters %%%%%%%%%%%%%%%%%%%%%%
sample_rate = 16e6;            % ADC Sample rate (Hz)
N_taps = 9;                     % Number of FIR filter taps
bit_rate = sample_rate/16;      % Data bit rate (b/s)
cut_off = bit_rate*0.7;         % Filter target cut-off frequency (Hz)
A_sig = 3.5;                      % Amplitude of the signal
A_int = 2.5;                      % Amplitude of the interfering tone
A_noise = 1;
F_int = 3e6;                   % Frequency of the interfering tone
adc_bits = 4;                   % Resolution of the ADC (bits)
c_bits = 4;                     % Resolution of the FIR tap weights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% Define a binary test pattern %%%%%%%%%%%%%%%%%%%%%%
data = [1     1     0     1     1     0     1     0     0 ...
        1     0     0     1     1     1     0     0     0 ...
        1     0     1     1     1     1     0     0     1 ...
        0     1     0     0     0     1     1     0     0 ...
        0     0     1     0     0     0     0     0     1 ...
        1     1     0     1     1     0     1     0     1 ...
        0     1     1     0     0     1     1     0     1   1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% Generate Test Signal %%%%%%%%%%%%%%%%%%%%%%%%
Ns = sample_rate/bit_rate;
N_samples = max(size(data)).*Ns;
time = (0:N_samples-1)./sample_rate;    % Time vector in seconds
noise = A_noise .* randn(1, N_samples);
noise_rms = sqrt(mean((noise.^2)));
delta=ones(1,Ns);
signal_ideal(1,:)=kron(data,delta);
signal_int = A_int.*sin(2.*pi.*F_int.*time);
signal = signal_int + noise + (A_sig.*signal_ideal)-(A_sig/2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% Quantise signal to model ADC %%%%%%%%%%%%%%%%%%
signal_adc_out = floor((2^adc_bits).*(signal - min(signal))...
    ./((max(signal)-min(signal))*1.001));
%signal_adc_out = signal_adc_out - 8;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% Generate FIR filter tap weights and quantise %%%%%%%%%
c = fir1(N_taps-1, (2*cut_off/sample_rate));
c = floor((2^c_bits).*(c./(max(c)*1.001)))
figure(2), freqz(c./sum(c), 1, 512)
    title('FIR Filter Characteristics')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% Output test signal to file %%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen('fir_in.txt', 'w');
for k=1:N_samples,
    fprintf(fid, '%s\n', dec2bin(mod((signal_adc_out(k)),2^adc_bits),adc_bits));  % 2s complement  
end
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% Simulate fir9 with test signal as stimulus %%%%%%%%%%%
% Call modelsim
if isunix,
     ms_run = system('/apps/altera/15.0/modelsim_ase/linux/vsim -c -do fir.do');
else
    ms_run = system('C:\altera\15.0\modelsim_ase\win32aloem\vsim -c -do fir.do');
end
if ms_run ~= 0,
    disp('Call to Modelsim failed - check path in lines 69-73 of Matlab test bench');
    return
end

% Read simulation output from file
fid_in = fopen('fir_out.txt', 'r');
disp('');
disp('==== VERIFICATION REPORT ====');
if fid_in<0,
    disp('No output file from Modelsim.  Simulation has probably not run to completion.');
    disp('Recommend that you debug the design in Modelsim.  When the fir.do script is run');
    disp('it should run for 128100 ns and generate a file called "fir_out.txt".');
    rmdir('work', 's')
    delete('vsim.wlf')
    return
end
% Read in 2 full pattern cycles
for k=1:2*N_samples,
    line_in = fgetl(fid_in);
    if (~isempty(findstr('x',line_in)) | ~isempty(findstr('X',line_in))),
        disp('Modlesim output (signal y) has unknown values.  This is usually due to');
        disp('missing reset conditions on registers.  Check both input and output registers');
        disp('in your SystemVerilog code. Recomend that you debug in Modelsim until output');
        disp('does not contain unknown values, denoted by "x" in the waveform window.');
        rmdir('work', 's')
        delete('vsim.wlf')
        return
    end
    fir_out(k) = str2num(line_in);
end
fclose(fid_in);
fir_out = fir_out(N_samples+1:2*N_samples);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% Generate Expected FIR Output %%%%%%%%%%%%%%%%%%%%%%%
% Software model for verification
expected_output_before_thresh = filter(c, 1, [signal_adc_out signal_adc_out]);
expected_output_after_thresh = expected_output_before_thresh > 450;
% Use the 2nd pattern cycle
expected_output_after_thresh = expected_output_after_thresh(N_samples+1:2*N_samples);
expected_output_before_thresh = expected_output_before_thresh(N_samples+1:2*N_samples);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% Plot Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%
end_time = time(end);
figure(1),  
    subplot(5,1,1), plot(time, signal_ideal)
        xlim([0 end_time]), ylim([-0.1 1.1])
        title('Transmitted Signal'), ylabel('Amplitude (arb)'), grid off
    subplot(5,1,2), plot(time, signal_adc_out)
        xlim([0 end_time]), grid off, ylim([0 15])
        title('Received Signal')
        ylabel('Amplitude (4 bit)')
    subplot(5,1,3), plot(time, expected_output_before_thresh)
        xlim([0 end_time]), ylim([min(expected_output_before_thresh)-50 max(expected_output_before_thresh)+50])
        title('Expected FIR Output - Software Verification Model'),
        ylabel('Amplitude (11 bit)')
        xlabel('Time (s)')    
    subplot(5,1,4), plot(time, expected_output_after_thresh)
        xlim([0 end_time]), ylim([-0.1 1.1])
        title('Expected FIR Filter Output after threshold - Software Verification Model'), 
        ylabel('Amplitude (1-bit)')
        xlabel('Time (s)')
    subplot(5,1,5), plot(time, fir_out)
        xlim([0 end_time]), ylim([-0.1 1.1])
        title('FIR Filter Output after threshold - SystemVerilog Model'), ylabel('Amplitude (1-bit)')
        xlabel('Time (s)')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
best_match = 0;
best_shift = 0;
for k=1:N_samples,
    current_match = sum(expected_output_after_thresh==fir_out);
    if current_match > best_match,
        best_match = current_match;
        best_shift = k-1;
    end
    fir_out = [fir_out(2:end) fir_out(1)];
end
if best_match<N_samples-2,
    disp('The output from hardware has significant differences from the expected');
    disp('output.  Check that your SystemVerilog code correctly describes the required');
    disp('circuit.  For example, check (1) the number of registers in the input chain'); 
    disp('(2) the combinational logic for multipliers and adders (3) all signals have ');
    disp('an appropriate bit width.');
    rmdir('work', 's')
    return
else
    if best_shift == 2,
        disp('Verification successful.  The circuit is working correctly and has the correct');
        disp('delay between input and output.');
        rmdir('work', 's')
        return
    else
        disp('Your circuit is giving the correct ouput, but the delay between input and output ');
        disp('is not correct.  Check that you have an output register and that you have not ');
        disp('inadvertantly inserted additional registers into the combinational logic.  This');
        disp('message will be displayed if you are testing the pipelined design as this adds ');
        disp('additional delay.');
        rmdir('work', 's')
        return
    end
end

