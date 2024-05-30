# simple RISC-V 32I multicycle pipline

## Introduction
This document provides an simple 4 multi-cycle stage risc-v pipeline cpu  
implemented in Verilog. In addition, This project was used by Kathryn 
(The hardware construction framework with hybrid design flow) to show a simple pipeline RISC-V implementation

## Specification
- Version : ```RISC-V 32I```
- Exclude : ```Fence, syscal, and Csr instruction```

## usage
### run example [merge sort example]
1. Clone the repository from GitHub: `git clone https://github.com/Tanawin1701d/riscv-rv32I-multicycle-pipeline`
2. modify ```./runner.sh```