Here’s a polished **GitHub README** draft for your project. I’ve structured it to highlight the motivation, methods, and results from your report while also referencing the MATLAB code. Image placeholders are included—you can replace them with the actual file names (e.g., `bpsk.png`, `qamBaseline.png`, etc.) in your repo.

---

# High Bit-Rate and Low BER Communication over Moderate ISI Channel

This project implements a **wireless link simulation** in MATLAB designed to achieve **high bit-rate and reliable communication** under **moderate inter-symbol interference (ISI)**. The system leverages:

* **16-QAM modulation**
* **Maximum Likelihood Sequence Estimation (MLSE) equalization**
* **Concatenated error coding** (Reed-Solomon + Convolutional + Viterbi decoding)

Through careful system design, the implementation achieves a **Bit Error Rate (BER) < 10⁻⁷ at 12 dB SNR** while maintaining an **effective bit rate of \~1733 bits/packet**.

---

## Features

* Simulation of **Additive White Gaussian Noise (AWGN)** channels with moderate ISI
* Custom **noise scaling** to match theoretical BER baselines
* Evaluation of multiple equalizers: **LMS, RLS, and MLSE**
* **Concatenated error coding** combining:

  * Reed-Solomon (15,13)
  * Convolutional coding (rate 1/2, constraint length 7)
* Performance benchmarking against **theoretical BER curves**
* Analysis of tradeoffs between **bit-rate efficiency** and **error resilience**

---

## System Architecture

1. **Modulation**

   * 16-QAM (Gray coded)
   * Bits grouped into symbols

2. **Error Coding**

   * Symbol-level Reed-Solomon coding
   * Bit-level Convolutional coding + Viterbi decoding

3. **Channel**

   * Multipath channel introduces ISI (e.g., `[1, 0.2, 0.4]`)
   * AWGN added using custom scaling

4. **Equalization**

   * MLSE equalizer (optimal sequence detection using Viterbi algorithm)

5. **BER Measurement**

   * Monte Carlo iterations across SNR range (0–16 dB)
   * Comparison with theoretical BER

---

## Simulation Workflow

```matlab
% Main parameters
numIter = 10000;      % Number of iterations
nSym = 1000;          % Symbols per packet
M = 16;               % QAM order
chan = [1 .2 .4];     % Moderate ISI channel

% Error coding
trellis = poly2trellis(7, [171 133]);
rsEncoder = comm.RSEncoder(15, 13, 'BitInput', true);
rsDecoder = comm.RSDecoder(15, 13, 'BitInput', true);

% Equalizer
equalizer = comm.MLSEEqualizer('Channel', chan.', ...
    'Constellation', qammod(0:M-1, M, 'gray', 'UnitAveragePower', true));
```

---

## Results

### Noise Scaling Validation

![bpsk](bpsk.png)
*BPSK simulation matches theoretical BER baseline.*

![qamBaseline](qamBaseline.png)
*4-QAM and 16-QAM without ISI confirming correct noise scaling.*

---

### Inter-Symbol Interference Effects

![4qammerateISI](4qammerateISI.png)
*Moderate ISI applied to 4-QAM link.*

---

### Equalizer Comparison

![eqComp](eqComp.png)
*MLSE outperforms LMS and RLS equalizers under moderate ISI.*

---

### Final 16-QAM System with Error Coding

![rs16mlse](rs16mlse.png)
*Concatenated coding + MLSE achieves BER < 10⁻⁷ at 12 dB SNR.*

Effective bit rate: **1733.33 bits/packet**

---

## Honorable Mention: LDPC + 16-PSK

An alternative approach explored **π/4-offset 16-PSK + LDPC coding** with MLSE equalization. While promising, it was **too computationally expensive** to evaluate fully.

![final](final.png)

---

## File Structure

```
├── README.md            # Project documentation
├── main_simulation.m    # MATLAB script for BER simulation
├── report.pdf           # Full project report (IEEE format)
├── figures/             # Simulation plots (used in README)
```

---

## Authors

* **Arav Sharma** – [arav.sharma@cooper.edu](mailto:arav.sharma@cooper.edu)
* **Timothy Hoerning** – [timothy.hoerning@cooper.edu](mailto:timothy.hoerning@cooper.edu)

Department of Electrical Engineering
The Cooper Union for the Advancement of Science and Art, New York, US

---

## Citation

If you use this project, please cite the report:

```
A. Sharma, T. Hoerning,
"High Bit-Rate and Low BER Communication over Moderate ISI Channel,"
Department of Electrical Engineering, Cooper Union, 2024.
```

---

👉 Would you like me to also add a **"Quick Start" section** showing how to run the MATLAB code with example commands (`run main_simulation.m`) and expected outputs, so it’s beginner-friendly for GitHub readers?
