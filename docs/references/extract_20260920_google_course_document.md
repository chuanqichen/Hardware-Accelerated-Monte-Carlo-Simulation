# VLSI Project References

Source: https://docs.google.com/document/d/1HtkrbLGjYYA4PTOaw3DYqKB7lMUMRVkPTSnsi5JD8do/edit?usp=sharing

Extracted: 2026-09-20

1. Tan et al., “ThundeRiNG: Generating Multiple Independent Random Number Sequences on FPGAs,” ACM ICS, 2021.

   Probably the most useful modern paper for our parallel RNG architecture and validation methodology. Also includes a Monte Carlo option-pricing case study. A Google Docs comment marks this as “Best paper.”

2. AMD/Xilinx Vitis Quantitative Finance Library — Monte Carlo and L1 primitives.

   Extremely useful as an architecture reference. Includes xoshiro128, Sobol, Gaussian transforms, Brownian Bridge, antithetic sampling, path generators, and accumulators.

3. Ma, Muslim & Lavagno, “High Performance and Low Power Monte Carlo Methods to Option Pricing Models via High Level Design and Synthesis,” IEEE EMS, 2016.

   Directly addresses FPGA Monte Carlo option pricing, including Black-Scholes and Heston. This is probably the closest older paper to our exact application.

4. Crols et al., “TreeGRNG: Binary Tree Gaussian Random Number Generator for Efficient Probabilistic AI Hardware,” DATE, 2024.

   Best paper to examine if we want the Gaussian-generator architecture itself to become one of our optimization contributions.

5. Gutiérrez Arance et al., “FPGA Acceleration of Matrix-Element Calculations for Monte Carlo Event Generation,” 2026.

   Different Monte Carlo application, but particularly valuable because it analyzes precision, replication, throughput, energy, resource utilization, and scaling limits—the style of experiments the project should reproduce for its own accelerator.
