# Digital Vending Machine — Verilog HDL / Vivado FPGA Controller

[![RTL Standard](https://img.shields.io/badge/Verilog-IEEE%201364--2001-blue.svg)](rtl/)
[![Digital Verification](https://img.shields.io/badge/Verification%20Suite-PASSED%20(42%20Dir%20%2B%201000%20Rand%20%2B%201000%20Stress)-brightgreen.svg)](docs/13_verification_report.md)
[![FPGA Target](https://img.shields.io/badge/Target-Basys%203%20%20(Artix--7)-orange.svg)](docs/14_hardware_validation_report.md)
[![Timing Closure](https://img.shields.io/badge/Timing-WNS%20%2B2.852ns%20%40%20100MHz-green.svg)](docs/14_hardware_validation_report.md)

## Overview
This repository contains the complete design, synthesizable Verilog-2001 RTL implementation, self-checking simulation verification suite, and Vivado FPGA build for a **Digital Vending Machine (DVM) Controller** targeting the **Digilent Basys 3** evaluation board (`xc7a35tcpg236-1`).

---

## Directory Structure
```text
.
├── constraints/   # Xilinx Design Constraints (.xdc) for Digilent Basys 3
├── docs/          # Authoritative technical specifications & project reports
├── rtl/           # Synthesizable Verilog-2001 HDL source modules
├── scripts/       # Vivado build Tcl scripts and simulation automation
├── sim/           # Simulation outputs and VCD waveform dumps (.vcd)
├── tb/            # Verification environment (Directed, Constrained-Random, Stress, Scoreboard, Invariants)
└── vivado/        # Vivado project files, reports, and generated bitstreams
```

---

## Documentation Index & Recommended Reading Order

| Document Name | Engineering Purpose |
| :--- | :--- |
| [`docs/FINAL_PROJECT_REPORT.md`](docs/FINAL_PROJECT_REPORT.md) | **Master Project Summary Report** (Executive summary, architecture, results) |
| [`docs/01_requirements.md`](docs/01_requirements.md) | Technical Specification: System Requirements |
| [`docs/02_architecture.md`](docs/02_architecture.md) | Technical Specification: System Architecture & Dataflow |
| [`docs/03_fsm.md`](docs/03_fsm.md) | Technical Specification: Canonical Operational FSM |
| [`docs/04_rtl_module_specification.md`](docs/04_rtl_module_specification.md) | Technical Specification: RTL Modules & Interfaces |
| [`docs/05_verification_and_test_plan.md`](docs/05_verification_and_test_plan.md) | Technical Specification: Verification & Test Plan |
| [`docs/06_interface_timing_specification.md`](docs/06_interface_timing_specification.md) | Technical Specification: Signal Timing & Handshakes |
| [`docs/07_product_catalog_specification.md`](docs/07_product_catalog_specification.md) | Technical Specification: Product Catalog & Pricing |
| [`docs/08_coin_system_specification.md`](docs/08_coin_system_specification.md) | Technical Specification: Coin Denomination Processor |
| [`docs/09_payment_system_specification.md`](docs/09_payment_system_specification.md) | Technical Specification: Payment Accumulator & Evaluator |
| [`docs/10_online_payment_specification.md`](docs/10_online_payment_specification.md) | Technical Specification: Online Payment Interface |
| [`docs/11_dispensing_inventory_specification.md`](docs/11_dispensing_inventory_specification.md) | Technical Specification: Dispense Controller |
| [`docs/12_feature_extensions.md`](docs/12_feature_extensions.md) | Technical Specification: Phase 4 Extensions (Inventory, Stats, Admin, Display Menu) |
| [`docs/13_verification_report.md`](docs/13_verification_report.md) | **Authoritative Verification Report** (Directed, Constrained-Random, Stress, Invariants & Scoreboard) |
| [`docs/14_hardware_validation_report.md`](docs/14_hardware_validation_report.md) | **Authoritative FPGA Build & Hardware Report** (Vivado synthesis, impl, timing, pinout, HW-001..HW-018) |

---

## Quick Start — Simulation & Build

### Running Simulation (Icarus Verilog)
```bash
# Core Verification Suite (Directed, Random 1000, Stress 1000, Scoreboard & Invariants)
iverilog -g2001 -o sim/vending_machine_tb.vvp tb/vending_machine_tb.v rtl/*.v
vvp sim/vending_machine_tb.vvp

# Extension Verification Suite (Inventory, Statistics, Admin, Display Menu)
iverilog -g2001 -o sim/inventory_statistics_tb.vvp tb/inventory_statistics_tb.v rtl/*.v
vvp sim/inventory_statistics_tb.vvp
```

### Running Vivado Build (Batch Mode)
```cmd
vivado -mode batch -source scripts/build_project.tcl
```
Generated Bitstream: `vivado/VendingMachine.runs/impl_1/vending_machine_board_wrapper.bit`.
