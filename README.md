# Digital Vending Machine — Verilog HDL / Vivado FPGA Controller

[![RTL Standard](https://img.shields.io/badge/Verilog-IEEE%201364--2001-blue.svg)](rtl/)
[![Digital Verification](https://img.shields.io/badge/Verification-42%20Dir%20%2B%201000%20Rand%20%2B%201000%20Stress%20PASSED-brightgreen.svg)](#digital-verification--simulation-results)
[![FPGA Target](https://img.shields.io/badge/Target-Basys%203%20%20(Artix--7)-orange.svg)](#fpga-synthesis--resource-utilization)
[![Timing Closure](https://img.shields.io/badge/Timing-WNS%20%2B2.852ns%20%40%20100MHz-green.svg)](#fpga-synthesis--resource-utilization)

---

## Overview

This repository contains the complete design, synthesizable **Verilog-2001 (IEEE 1364-2001)** RTL implementation, self-checking simulation verification suite, and Vivado FPGA build for a **Digital Vending Machine (DVM) Controller** targeting the **Digilent Basys 3** evaluation board (`xc7a35tcpg236-1`).

The design uses a fully decoupled architecture where product catalog pricing, inventory data, coin decoding, payment accumulation, change calculation, refund routing, online payment handshaking, statistics collection, admin mode navigation, and 7-segment display menu driving are encapsulated in dedicated synchronous sub-modules.

---

## Key Features

- **IEEE 1364-2001 Verilog Compliance**: 100% synthesizable Verilog-2001 code (no SystemVerilog, no inferred latches).
- **Decoupled FSM Architecture**: Products are treated strictly as **DATA**. The FSM contains 10 operational states (`ST_IDLE`, `ST_SELECT`, `ST_PAYMENT`, `ST_EVALUATE`, `ST_ONLINE_WAIT`, `ST_DISPENSE`, `ST_CHANGE`, `ST_REFUND`, `ST_COMPLETE`, `ST_ERROR`) and zero product-specific states.
- **Multi-Denomination Coin Support**: Accepts and validates ₹1, ₹2, ₹5, ₹10, and ₹20 coin codes; rejects unsupported or unsolicited coins without corrupting transaction state.
- **Exact & Overpayment Handling**: Computes exact single-cycle change strobes on overpayment; supports full refund on customer cancellation.
- **Abstract Online Payment Handshake**: Handshakes with external payment gateways for net remaining balance deltas (`prod_price - accum_balance`) with an integrated 5-second watchdog timer for automatic timeout recovery.
- **Inventory & Stock Management**: Tracks 4 product slots (10 initial stock each) with underflow protection, low-stock warnings (`<= 2` units), and out-of-stock lockouts (`0` units).
- **Admin & Maintenance Mode**: Isolated control domain entered via switch `SW15` in idle state; navigates BCD statistics menus (vends, revenue, errors, stock) and triggers restocking via `SW13`.
- **7-Segment Display & LED Mapping**: Drives 4-digit multiplexed 7-segment display and 16 status LEDs on the Basys 3 board.
- **Verification Suite**: 42 directed tests, 1,000 constrained-random transactions, 1,000 back-to-back stress transactions, cycle-accurate scoreboard, and 15 continuous safety invariant checkers (**100% PASSED**).
- **Timing Closure at 100 MHz**: WNS = **+2.852 ns**, $F_{max}$ = **139.9 MHz**, **0 DRC errors**, **0 latches**.

---

## Directory Structure

```text
.
├── constraints/
│   └── basys3_vending_machine.xdc   # Xilinx Design Constraints for Digilent Basys 3
├── rtl/                             # Synthesizable Verilog-2001 HDL modules
│   ├── admin_controller.v           # Admin mode & menu navigation logic
│   ├── btn_debouncer.v              # Synchronous pushbutton debouncer & edge detector
│   ├── change_calculator.v          # Overpayment change calculation logic
│   ├── coin_processor.v             # Coin denomination decoder & validation
│   ├── dispense_controller.v        # 1-second timed dispensing output controller
│   ├── display_menu_controller.v    # 7-segment display menu decoder
│   ├── inventory_controller.v       # Product stock tracking & underflow guard
│   ├── led_status_driver.v          # 16 status LED decoder
│   ├── online_payment_interface.v   # Net balance online payment handshake
│   ├── payment_accumulator.v        # Balance accumulator with overflow protection
│   ├── payment_evaluator.v          # Exact/under/overpayment comparator
│   ├── product_catalog.v            # Central product pricing lookup table
│   ├── refund_controller.v          # Single-cycle cancellation refund calculator
│   ├── seven_seg_display_ctrl.v     # 4-digit active-low multiplexer & anode driver
│   ├── statistics_controller.v      # Revenue, vend, cancel, & error counters
│   ├── vending_fsm.v                # Canonical 10-state operational FSM
│   ├── vending_machine_board_wrapper.v # Top-level Basys 3 FPGA wrapper
│   └── vending_machine_top.v        # Decoupled core top-level interconnect
├── scripts/
│   ├── build_project.tcl            # Vivado batch build & bitstream script
│   └── run_sim.tcl                  # Icarus Verilog simulation automation
├── sim/                             # Simulation VCD waveform dumps (.vcd)
├── tb/
│   ├── inventory_statistics_tb.v    # Extension testbench (Inventory, Stats, Admin, Display)
│   └── vending_machine_tb.v         # Core verification testbench (Directed, Random, Stress, Scoreboard)
└── vivado/
    ├── VendingMachine.xpr           # Vivado project file
    ├── timing_summary_report.txt    # Genuine Vivado timing report (+2.852ns WNS)
    └── utilization_report.txt       # Genuine Vivado resource utilization report
```

---

## RTL Module Breakdown

### 1. Top-Level Wrapper (`rtl/vending_machine_board_wrapper.v`)
Integrates physical input debouncers, synchronizers, 7-segment display multiplexer, LED status mapping, admin mode switches, and the core vending top module.

### 2. Core Interconnect (`rtl/vending_machine_top.v`)
Wires together the operational FSM, product catalog, coin decoder, payment accumulator, evaluator, change calculator, refund logic, online payment interface, dispense controller, inventory controller, statistics counters, and admin controller.

### 3. Operational FSM (`rtl/vending_fsm.v`)
Manages system lifecycle across 10 generic states:
- `ST_IDLE` (`0000`): System ready, awaiting product selection.
- `ST_SELECT` (`0001`): Captures selection, checks catalog validity & stock.
- `ST_PAYMENT` (`0010`): Accepts valid coin insertions, accumulates balance.
- `ST_EVALUATE` (`0011`): Compares balance against product price.
- `ST_ONLINE_WAIT` (`0100`): Requests net remaining payment from external gateway.
- `ST_DISPENSE` (`0101`): Drives 1-second dispense output; masks cancellation.
- `ST_CHANGE` (`0110`): Generates 1-cycle change strobe for overpayment.
- `ST_REFUND` (`0111`): Generates 1-cycle refund strobe on cancellation.
- `ST_COMPLETE` (`1000`): Transaction completion cleanup.
- `ST_ERROR` (`1001`): Error handling state (out of stock / invalid selection).

### 4. Product Catalog (`rtl/product_catalog.v`)
Authoritative lookup table for product pricing and initial stock:
- **Product 0 (`2'b00`)**: Water — Price: ₹10, Initial Stock: 10
- **Product 1 (`2'b01`)**: Soda — Price: ₹15, Initial Stock: 10
- **Product 2 (`2'b10`)**: Chips — Price: ₹20, Initial Stock: 10
- **Product 3 (`2'b11`)**: Candy — Price: ₹25, Initial Stock: 10

### 5. Coin Processor (`rtl/coin_processor.v`)
Decodes 3-bit input codes (`coin_denom[2:0]`):
- `3'b001` $\rightarrow$ ₹1
- `3'b010` $\rightarrow$ ₹2
- `3'b011` $\rightarrow$ ₹5
- `3'b100` $\rightarrow$ ₹10
- `3'b101` $\rightarrow$ ₹20
- `3'b000`, `3'b110`, `3'b111` $\rightarrow$ Rejected (`coin_reject = 1`)

---

## Basys 3 Pin & Control Mapping

| Function | Physical Control | Basys 3 Pin / SW | Initial Position |
| :--- | :--- | :--- | :---: |
| **System Reset** | Center Pushbutton | `btnC` (`U18`) | Released (`0`) |
| **Product Select Trigger** | Top Pushbutton | `btnU` (`T18`) | Released (`0`) |
| **Product Select Code** | Switches `SW1`..`SW0` | `SW1` (`V16`), `SW0` (`V17`) | `2'b00` (`OFF`, `OFF`) |
| **Coin Insert Trigger** | Left Pushbutton | `btnL` (`W19`) | Released (`0`) |
| **Coin Denomination Code** | Switches `SW4`..`SW2` | `SW4` (`W17`), `SW3` (`W15`), `SW2` (`V15`) | `3'b000` (`OFF`, `OFF`, `OFF`) |
| **Cancel Transaction** | Right Pushbutton | `btnR` (`T17`) | Released (`0`) |
| **Online Payment Trigger** | Bottom Pushbutton | `btnD` (`U17`) | Released (`0`) |
| **Admin Mode Enable** | Switch `SW15` | `SW15` (`R2`) | `OFF` (`0`) |
| **Admin Menu Next** | Switch `SW14` | `SW14` (`T1`) | `OFF` (`0`) |
| **Admin Restock Trigger** | Switch `SW13` | `SW13` (`U1`) | `OFF` (`0`) |
| **Status LEDs** | LEDs `LED15`..`LED0` | `LED15`..`LED0` | Displayed |
| **7-Segment Display** | 4-Digit Cathodes/Anodes | `an[3:0]`, `seg[6:0]`, `dp` | Displayed |

---

## Digital Verification & Simulation Results

Verification is executed via self-checking testbenches targeting IEEE 1364-2001 Verilog compliance using Icarus Verilog (`iverilog -g2001`).

```text
============================================================
DIGITAL VENDING MACHINE - VERIFICATION SUMMARY
============================================================
DIRECTED TESTS
Passed : 42 / 42
Failed : 0

RANDOM TESTS (Seed: 12345)
Passed : 1000 / 1000
Failed : 0

STRESS TESTS (Back-to-Back Consecutive Transactions)
Passed : 1000 / 1000
Failed : 0

MONITOR CHECKS
Passed : 42 / 42
Failed : 0

SCOREBOARD CHECKS
Passed : 2042 / 2042
Failed : 0

INVARIANT CHECKS (INV-001 through INV-015)
Passed : 112660 / 112660
Failed : 0

FUNCTIONAL COVERAGE
Products             : 4/4 (100%)
Valid Coins          : 5/5 (100%)
Invalid Coins        : 3/3 (100%)
Payment Scenarios    : 3/3 (100%)
Online Scenarios     : 3/3 (100%)
Admin Scenarios      : 5/5 (100%)
Conflict Scenarios   : 3/3 (100%)

TOTAL FAILURES: 0

OVERALL DIGITAL VERIFICATION STATUS:
>>> PASS <<<
============================================================
```

### Safety Invariants Verified
- **INV-001**: Balance never exceeds `MAX_MONEY_CAP` (65535).
- **INV-002**: Balance never underflows or becomes negative.
- **INV-003**: Dispense occurs only for valid, in-stock products after complete payment.
- **INV-004**: Refund occurs only on explicit cancellation or error paths.
- **INV-005**: Change occurs only on overpayment transactions (`change = cash - price`).
- **INV-006**: Invalid coin codes never increase credited transaction balance.
- **INV-007**: Inventory stock never underflows below 0.
- **INV-008**: Successful dispensing decrements product inventory exactly once per transaction.
- **INV-009**: Failed or declined online payment never authorizes product dispensing.
- **INV-010**: Cancellation prior to dispensing prevents product dispense and issues full refund.
- **INV-011**: Synchronous reset returns FSM to `ST_IDLE`, clears balance, and places outputs in safe states.
- **INV-012**: FSM always remains within legal encoding states (`0000` through `1001`).
- **INV-013**: Conflicting input priority is respected according to FSM contract.
- **INV-014**: Rejected coins do not corrupt active transaction balance or state.
- **INV-015**: Total accumulated revenue matches exact cumulative product prices of completed vends.

---

## FPGA Synthesis & Resource Utilization

The design was synthesized and implemented targeting the **Xilinx Artix-7 XC7A35T-1CPG236 FPGA** using **Vivado 2019.2**.

### Resource Utilization (`vivado/utilization_report.txt`)
| Resource | Used | Available | Utilization % |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **826** | 20,800 | **3.97 %** |
| **Slice Registers (Flip-Flops)** | **465** | 41,600 | **1.12 %** |
| **Inferred Latches** | **0** | 41,600 | **0.00 %** |
| **Block RAM Tile** | **0** | 50 | **0.00 %** |
| **DSPs** | **0** | 90 | **0.00 %** |
| **Bonded IOBs** | **45** | 106 | **42.45 %** |

### Timing Closure Summary (`vivado/timing_summary_report.txt`)
- **Target Clock Frequency**: 100.0 MHz ($T_{clk} = 10.0\text{ ns}$)
- **Worst Negative Slack (WNS)**: **+2.852 ns** (Setup Timing Met)
- **Worst Hold Slack (WHS)**: **+0.140 ns** (Hold Timing Met)
- **Total Negative Slack (TNS)**: **0.000 ns** (Zero Timing Violations)
- **Maximum Operating Frequency ($F_{max}$)**: **139.9 MHz**
- **Bitstream Status**: Generated (`vivado/VendingMachine.runs/impl_1/vending_machine_board_wrapper.bit`)

---

## How to Run Simulation & Build

### 1. Run Simulation with Icarus Verilog

```bash
# Core Verification Suite (Directed, Random 1000, Stress 1000, Scoreboard & Invariants)
iverilog -g2001 -o sim/vending_machine_tb.vvp tb/vending_machine_tb.v rtl/*.v
vvp sim/vending_machine_tb.vvp

# Phase 4 Feature Extension Suite (Inventory, Statistics, Admin, Display Menu)
iverilog -g2001 -o sim/inventory_statistics_tb.vvp tb/inventory_statistics_tb.v rtl/*.v
vvp sim/inventory_statistics_tb.vvp
```

### 2. View Waveforms in GTKWave

```bash
gtkwave sim/vending_machine_tb.vcd
```

### 3. Run Vivado Build (Batch Mode)

```cmd
vivado -mode batch -source scripts/build_project.tcl
```

### 4. Open Project in Vivado GUI

1. Launch **Xilinx Vivado**.
2. Click **Open Project**.
3. Select `vivado/VendingMachine.xpr`.
4. Click **Run Simulation** for XSIM waveforms, or click **Open Implemented Design** to inspect the interactive FPGA chip schematic and placement floorplan.

---

## License & Standards

- **HDL Standard**: IEEE 1364-2001 Verilog (Verilog-2001)
- **Target Board**: Digilent Basys 3 Evaluation Board (Artix-7 XC7A35T)
- **Status**: Production-Ready / Fully Verified Digital Design
