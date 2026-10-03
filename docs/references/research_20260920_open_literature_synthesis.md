# Open-literature synthesis for hardware-accelerated Monte Carlo

_Research audit for the Fall 2026 ECE 382M-7 project plan, searched 2026-09-20_

---

## Scope and method

The search combined the local course documents, the linked Google document, OpenAlex, arXiv, Semantic Scholar, Crossref, public publisher manuscripts, and official open-source repositories. Search concepts included hardware-accelerated Monte Carlo option pricing, parallel random-number generation, Gaussian random-number generation, Sobol sequences, Brownian bridges, variance reduction, Black–Scholes and Heston models, fixed-point precision, FPGA/ASIC resource scaling, and statistical RNG validation. The authenticated Parallel and Perplexity backends were unavailable because neither `PARALLEL_API_KEY` nor `OPENROUTER_API_KEY` is configured, so the research used open APIs and primary sources instead.

This is a targeted engineering review rather than a formal systematic review. Papers were prioritized when they provided a peer-reviewed hardware architecture, reproducible implementation details, numerical-quality tests, PPA/resource measurements, an option-pricing case study, or a directly reusable experimental method. All 16 DOI-bearing references retained for the plan were resolved and metadata-checked through Crossref; see `citation_validation_20260920_hardware_monte_carlo.md`.

## Evidence most relevant to the project

### Parallel random-number generation

Tan et al.'s ThundeRiNG is the strongest direct architecture reference. It combines a shared 64-bit LCG root transition, per-stream additive leaf transitions, PCG-style output permutation, and xorshift128 decorrelators. Its key architectural claim is that one expensive root multiplication can serve any number of output streams, while each additional stream primarily adds an adder, permutation logic, and decorrelator state. The FPGA implementation passed BigCrush for individual and interleaved streams, PractRand beyond 8 TB for individual streams, pairwise correlation tests, and a Hamming-weight-dependency test. On an Alveo U250 it reported 655 Gsample/s raw throughput; its 256-instance Black–Scholes case study delivered 86 Gsample/s, 2.33× the throughput and 6.83× the power efficiency of the compared Tesla P100 implementation. These are FPGA results, not ASIC guarantees, which creates a useful course-project question: does state sharing retain its advantage in a 45 nm standard-cell flow where replicated xoshiro state updates use shifts, XORs, rotations, and additions rather than scarce FPGA DSP/BRAM resources?[^1]

The official AMD/Xilinx Vitis Quantitative Finance library supplies the best open implementation reference for the comparison baseline and common Monte Carlo pipeline. The last repository branch found with the Quantitative Finance library is `2024.2`; the library is absent from `main`, `2025.2`, and `2026.1`. Its L1 code includes independent `xoshiro128` generators with jump and long-jump stream separation, Sobol generators up to 128 dimensions, Box–Muller and inverse-CDF Gaussian transforms, Brownian bridge, antithetic sampling, Black–Scholes and Heston path generators, path pricers, and sum/square-sum accumulators. The Monte Carlo framework uses streaming dataflow, an initiation interval of one where practical, replicated engines for parallelism, and banked accumulators to hide floating-point adder latency.[^2]

Counter-based generators such as Random123 are another credible parallel baseline because stream identity and sample index define a random value without mutable shared state. They simplify deterministic partitioning but use more rounds of arithmetic than xoshiro. For a ten-week RTL project, xoshiro is the lower-risk replicated-lane baseline, while Random123 is best retained as a literature comparator rather than a required implementation.[^3]

### Gaussian and nonuniform generation

Monte Carlo pricing under geometric Brownian motion needs Gaussian or a carefully justified discrete approximation. Lee et al. provide the seminal FPGA Box–Muller architecture and error analysis, but the transform requires logarithm, square root, sine, and cosine hardware. That makes it a valuable accuracy baseline but a schedule risk for a project whose main research question concerns multistream scaling.[^4]

De Schryver et al. present a segmented inversion-based generator for arbitrary nonuniform distributions and report up to 48% area savings over a prior inversion design. This supports a more practical common backend: a precomputed, symmetric, segmented inverse-normal mapper whose table/segment precision can be swept and whose tail error is measured explicitly.[^5]

Crols et al.'s TreeGRNG replaces arithmetic-heavy Gaussian transforms with a binary tree of hardwired constant-threshold comparisons. In a matched 45 nm standard-cell synthesis at INT8 precision, the pipelined design reports 1,020 NAND2-equivalent gates, 3,021 Msamples/s, a Kolmogorov–Smirnov error of 0.00820, 3.7× better energy efficiency, and 5.8× higher throughput per area than its time-interleaved Hadamard-transform comparator. The design is compelling as a gated extension, but its discrete output and finite tails must be tested against option-pricing bias rather than accepted solely from a global K–S statistic.[^6]

### Option-pricing accelerators

Ma, Muslim, and Lavagno compare Black–Scholes and Heston Monte Carlo implementations across GPUs and FPGAs. Their Virtex-7 Black–Scholes implementation achieved 1.71× the compared GTX 960 performance while consuming 9.8% of its energy per simulation step; the Heston implementation achieved 2.56× performance while consuming 5.9% of GPU energy. The paper emphasizes outer-loop path replication, inner-loop pipelining, interleaving independent paths to break loop-carried dependence, and balancing DSP/LUT resources. It also identifies Gaussian generation as an important remaining optimization target.[^7]

Earlier work established the viability of FPGA financial Monte Carlo, including reconfigurable financial simulation, energy-efficient Heston pricing, multi-level Monte Carlo, low-discrepancy sequences, and Brownian-bridge/stratified sampling. These papers support Sobol, Brownian bridge, and Heston as credible stretch directions, but each adds substantial dimension management, numerical complexity, or verification burden.[^8][^9][^10][^11]

A 2024 survey screened 131 studies and retained 99, reporting published FPGA speedups ranging from 270× to 5,400× depending on model and baseline. Such cross-paper speedups are not directly comparable because the workloads, numerical formats, devices, host-transfer accounting, and reference implementations vary. The course project should therefore avoid headline speedup claims and use matched flows, identical inputs, identical quality targets, and both kernel-only and end-to-end measurements.[^12]

### Experimental methodology

Gutiérrez Arance et al. provide a strong contemporary evaluation template even though their Monte Carlo application is particle event generation rather than finance. They separate full-workflow acceleration from isolated-kernel acceleration, report numerical accuracy, resource use, initiation interval, latency, throughput, energy, and scaling, and explicitly warn against interpreting isolated-kernel speedup as end-to-end speedup. Their iterative fixed-/floating-point selection against a CPU reference is directly applicable to this project.[^13]

Random-number quality must be measured at both the single-stream and cross-stream levels. TestU01 remains the primary empirical suite; ThundeRiNG supplements it with PractRand, interleaved-stream batteries, Hamming-weight dependency, and Pearson, Spearman, and Kendall pairwise tests. For generated Gaussian values, the plan should add mean, variance, skew, excess kurtosis, K–S and Anderson–Darling tests, quantile/tail error, and Q–Q plots. Application validity then requires price bias, RMSE, confidence-interval coverage, and convergence versus path count, not only distribution-level tests.[^14]

## Engineering conclusion

The best semester scope is a matched comparison of replicated independent xoshiro lanes and a ThundeRiNG-inspired shared-state multistream frontend, both driving the same inverse-normal mapper, finite-step Black–Scholes path engine, payoff block, and accumulator. This directly tests whether an FPGA-oriented state-sharing idea transfers to a 45 nm ASIC flow. It is distinct from the 2025 class project, which implemented repeated FFT convolution instead of trial-based paths.

TreeGRNG, Sobol quasi-Monte Carlo, Brownian bridge, and Heston should not all be core requirements. TreeGRNG is the most valuable first extension because it substitutes a clearly bounded block and creates a tail-accuracy-versus-PPA study. Sobol plus Brownian bridge is the next extension if the common pipeline is stable by the October design gate. Heston should remain future work unless the one-factor engine closes synthesis and verification early.

## References

[^1]: H. Tan, X. Chen, Y. Chen, B. He, and W.-F. Wong. (2021). “ThundeRiNG: Generating Multiple Independent Random Number Sequences on FPGAs.” _ACM ICS_. https://doi.org/10.1145/3447818.3461664

[^2]: AMD/Xilinx. _Vitis Quantitative Finance Library_, branch `2024.2`. https://github.com/Xilinx/Vitis_Libraries/tree/2024.2/quantitative_finance

[^3]: J. K. Salmon, M. A. Moraes, R. O. Dror, and D. E. Shaw. (2011). “Parallel Random Numbers: As Easy as 1, 2, 3.” _SC_. https://doi.org/10.1145/2063384.2063405

[^4]: D.-U. Lee, J. D. Villasenor, W. Luk, and P. H. W. Leong. (2006). “A Hardware Gaussian Noise Generator Using the Box-Muller Method and Its Error Analysis.” _IEEE Transactions on Computers_. https://doi.org/10.1109/TC.2006.81

[^5]: C. de Schryver et al. (2012). “A Hardware Efficient Random Number Generator for Nonuniform Distributions with Arbitrary Precision.” _International Journal of Reconfigurable Computing_. https://doi.org/10.1155/2012/675130

[^6]: J. Crols, G. Paim, S. Zhao, and M. Verhelst. (2024). “TreeGRNG: Binary Tree Gaussian Random Number Generator for Efficient Probabilistic AI Hardware.” _DATE_. https://doi.org/10.23919/DATE58400.2024.10546516

[^7]: L. Ma, F. B. Muslim, and L. Lavagno. (2016). “High Performance and Low Power Monte Carlo Methods to Option Pricing Models via High Level Design and Synthesis.” _European Modelling Symposium_. https://doi.org/10.1109/EMS.2016.036

[^8]: G. Zhang et al. (2005). “Reconfigurable Acceleration for Monte Carlo Based Financial Simulation.” _FPT_. https://doi.org/10.1109/FPT.2005.1568549

[^9]: C. de Schryver et al. (2011). “An Energy Efficient FPGA Accelerator for Monte Carlo Option Pricing with the Heston Model.” _ReConFig_. https://doi.org/10.1109/ReConFig.2011.11

[^10]: I. L. Dalal, D. Stefan, and J. Harwayne-Gidansky. (2008). “Low Discrepancy Sequences for Monte Carlo Simulations on Reconfigurable Platforms.” _ASAP_. https://doi.org/10.1109/ASAP.2008.4580163

[^11]: M. de Jong, V.-M. Sima, K. Bertels, and D. B. Thomas. (2014). “FPGA-Accelerated Monte-Carlo Integration Using Stratified Sampling and Brownian Bridges.” _FPT_. https://doi.org/10.1109/FPT.2014.7082755

[^12]: A. O Mahony, B. Hanzon, and E. Popovici. (2024). “The Role of FPGAs in Modern Option Pricing Techniques: A Survey.” _Electronics_. https://doi.org/10.3390/electronics13163186

[^13]: H. Gutiérrez Arance et al. (2026). “FPGA Acceleration of Matrix-Element Calculations for Monte Carlo Event Generation.” _Computer Physics Communications_. https://doi.org/10.1016/j.cpc.2026.110394

[^14]: P. L’Ecuyer and R. Simard. (2007). “TestU01: A C Library for Empirical Testing of Random Number Generators.” _ACM Transactions on Mathematical Software_. https://doi.org/10.1145/1268776.1268777
