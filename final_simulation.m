% A skeleton BER script for a wireless link simulation
clear;close all;clc
% dbstop if error; % Useful for debug - comment out if stopping too much

% For the final version of this project, you must use these 3
% parameter. You will likely want to set numIter to 1 while you debug your
% link, and then increase it to get an average BER.
numIter = 10000;  % The number of iterations of the simulation
nSym = 1000;    % The number of symbols per packet
SNR_Vec = 0:2:16;
lenSNR = length(SNR_Vec);

M = 16;        % The M-ary number, 2 corresponds to binary modulation

% chan = 1;          % No channel
chan = [1 .2 .4]; % Somewhat invertible channel impulse response, Moderate ISI
% chan = [0.227 0.460 0.688 0.460 0.227]';   % Not so invertible, severe ISI

bitsPerSymbol = log2(M);


% Convolutional Encoder Configuration
trellis = poly2trellis(7, [171 133]);

% Reed-Solomon Code Configuration
n = 15; % Codeword length
k = 13; % Message length
m = 4;  % Bits per RS symbol
rsEncoder = comm.RSEncoder(n, k, 'BitInput', true);
rsDecoder = comm.RSDecoder(n, k, 'BitInput', true);

% Create MLSE equalizer object with correct QAM parameters
equalizer = comm.MLSEEqualizer('Channel', chan.', ...
    'Constellation', qammod(0:M-1, M, 'gray', 'UnitAveragePower', true), ...
    'TracebackDepth', 10*length(chan), ...
    'SamplesPerSymbol', 1);

totalSymbolBits = nSym * bitsPerSymbol;    % Total raw bits per packet
rsBlockSize = n * m;                        % Bits per RS block
numRSBlocks = floor(totalSymbolBits / rsBlockSize);  % Complete RS blocks per packet
dataBitsPerRSBlock = k * m;                % Data bits per RS block
totalDataBits = numRSBlocks * dataBitsPerRSBlock;  % Total data bits per packet
packetBitRate = totalDataBits;  % Actual data bits per packet

% Time-varying Rayleigh multipath channel, try it if you dare. Or take
% wireless comms next semester.
% ts = 1/1000;
% chan = rayleighchan(ts,1);
% chan.pathDelays = [0 ts 2*ts];
% chan.AvgPathGaindB = [0 5 10];
% chan.StoreHistory = 1; % Uncomment if you want to be able to do plot(chan)
% 

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, lenSNR);

h = waitbar(0, 'Simulating...');

% Run the simulation numIter amount of times
for i = 1:numIter

    bits = randi([0 1], totalDataBits, 1);     % Generate random bits
    % New bits must be generated at every
    % iteration

    % Process each RS block
    rsEncodedBits = [];
    for block = 1:numRSBlocks
        blockStart = (block-1)*dataBitsPerRSBlock + 1;
        blockEnd = block*dataBitsPerRSBlock;
        blockBits = bits(blockStart:blockEnd);
        rsEncodedBits = [rsEncodedBits; rsEncoder(blockBits)];
    end

    % Convolutional encode
    encBits = convenc(rsEncodedBits, trellis);
    
    % Pad to fit QAM symbols
    padLength = mod(length(encBits), bitsPerSymbol);
    if padLength > 0
        encBits = [encBits; zeros(bitsPerSymbol - padLength, 1)];
    end

    % If you increase the M-ary number, as you most likely will, you'll need to
    % convert the bits to integers. See the BIN2DE function
    % For binary, our MSG signal is simply the bits
    msg = bi2de(reshape(encBits, bitsPerSymbol, []).', 'left-msb');

    for j = 1:lenSNR % one iteration of the simulation at each SNR Value


         tx = qammod(msg, M, 'gray', 'UnitAveragePower', true);  % BPSK modulate the signal

        if isequal(chan,1)
            txChan = tx;
        elseif isa(chan,'channel.rayleigh')
            reset(chan) % Draw a different channel each iteration
            txChan = filter(chan,tx);
        else
            txChan = filter(chan,1,tx);  % Apply the channel.
        end

        SNR_linear = 10^(SNR_Vec(j)/10); % Convert SNR from dB to linear
        noise_std = sqrt(1/(2*log2(M)*SNR_linear)); % Compute noise standard deviation
        txNoisy = txChan + noise_std * (randn(size(txChan)) + 1i * randn(size(txChan))); % Add noise

        %txNoisy = awgn(tx, SNR_Vec(j), 'measured'); % Add AWGN

        % Equalize and demodulate
        rxSymbols = equalizer(txNoisy);
        rxDemod = qamdemod(rxSymbols, M, 'gray', 'UnitAveragePower', true);
        rxBits = de2bi(rxDemod, bitsPerSymbol, 'left-msb');
        rxMSG = reshape(rxBits.', [], 1);

        % Remove padding
        rxMSG = rxMSG(1:length(encBits));

        % Viterbi decode
        rxDecodedBits = vitdec(rxMSG, trellis, 7*length(chan), 'trunc', 'hard');

        % RS decode each block
        rxDataBits = [];
        for block = 1:numRSBlocks
            blockStart = (block-1)*rsBlockSize + 1;
            blockEnd = block*rsBlockSize;
            if blockEnd <= length(rxDecodedBits)
                blockBits = rxDecodedBits(blockStart:blockEnd);
                rxDataBits = [rxDataBits; rsDecoder(blockBits)];
            end
        end

        % Compute and store the BER for this iteration

        [~, berVec(i,j)] = biterr(bits(1:length(rxDataBits)), rxDataBits);  % We're interested in the BER, which is the 2nd output of BITERR

    end  % End SNR iteration
    reset(equalizer);

    waitbar(i/numIter, h, sprintf('Progress: %d%%', round(i/numIter*100)));

end      % End numIter iteration

close(h);

% Compute and plot the mean BER
ber = mean(berVec,1);

semilogy(SNR_Vec, ber)

% Compute the theoretical BER for this scenario
% THIS IS ONLY VALID FOR BPSK!
% YOU NEED TO CHANGE THE CALL TO BERAWGN FOR DIFF MOD TYPES
% Also note - there is no theoretical BER when you have a multipath channel
berTheory = berawgn(SNR_Vec,'qam',M,'nondiff');
hold on
semilogy(SNR_Vec,berTheory,'r--')
legend('BER', 'Theoretical BER')