clear;close all;clc

numIter = 100;
nSym = 500; % 500 additional training symbols will be added on afterwards
SNR_Vec = 0:2:16;
lenSNR = length(SNR_Vec);
M = 2;
chan = [1 0.2 0.4];

% equalizer parameters
nTaps = 11;
mu = 0.01;
delay = (nTaps-1)/2;

berVec = zeros(numIter, lenSNR);
mseVec = zeros(numIter, lenSNR); % store MSE as well

% create training symbols
trainSeq = randi([0 1], 1, nSym/2);
trainSyms = 2*trainSeq - 1; % NRZ encoding the training symbols

for i = 1:numIter
    bits = randi([0 1], 1, nSym*M);
    msg = bits;
    dataSym = 2*msg - 1; % NRZ again
    
    for j = 1:lenSNR
        w = zeros(nTaps, 1); % init equalizer weights
        w((nTaps+1)/2) = 1;
        % center tap

        tx = [trainSyms dataSym]; %add training symbols to data
        txChan = filter(chan, 1, tx);
        
        SNR_linear = 10^(SNR_Vec(j)/10);
        noise_std = sqrt(1/(2*SNR_linear));
        txNoisy = txChan + noise_std*(randn(size(tx)) + 1i*randn(size(tx)));
        
        % buffer equalizer input
        x_buffer = zeros(nTaps, 1);
        y_eq = zeros(size(tx));
        
        for n = 1:length(tx)
            x_buffer = [txNoisy(n); x_buffer(1:end-1)]; %update
            y_eq(n) = w' * x_buffer;
            % calculate outpput

            % Error calculation
            if n <= length(trainSyms)
                d = trainSyms(n);
            else
                d = sign(real(y_eq(n)));
            end
            error = d - y_eq(n);
            w = w + mu * conj(error) * x_buffer;

        end
        
        rx_data = sign(real(y_eq(length(trainSyms)+1:end))); % hard decisions
        rxMSG = (rx_data + 1)/2; % NRZ to bits
        [~, berVec(i,j)] = biterr(msg, rxMSG);
    end
end

ber = mean(berVec, 1);
figure;
semilogy(SNR_Vec, ber, 'bo-', 'LineWidth', 2);
hold on;

berTheory = berawgn(SNR_Vec, 'psk', 2, 'nondiff');
semilogy(SNR_Vec, berTheory, 'r--', 'LineWidth', 2);

grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
title('BER Performance with Adaptive Equalizer');
legend('Adaptive Equalizer', 'Theoretical BPSK in AWGN');
