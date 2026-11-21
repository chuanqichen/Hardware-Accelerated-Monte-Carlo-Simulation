# TreeGRNG (third party, unmodified)

Source: https://github.com/KULeuven-MICAS/TreeGRNG, `ExampleGRNG/`, commit 0bb20793e56e (2024-03-26).
Paper: J. Crols, G. Paim, S. Zhao, M. Verhelst, "TreeGRNG: Binary Tree Gaussian Random Number
Generator for Efficient Probabilistic AI Hardware," DATE 2024.

Vendored here only as the state-of-the-art low-cost GRNG baseline for the research study in
`docs/research/` (synthesised on our shared flow, output distribution enumerated by
`model/treegrng_study.py`). Not part of the project's production RTL. The upstream repository
states no licence file; treat as the authors' copyright, research use only.

Top module: `compGRNG` (`topgrng8_8.sv`), ports `clk`, `LD_seed`, `result[7:0]` (INT8, sign-magnitude, 32 LSB per sigma).
