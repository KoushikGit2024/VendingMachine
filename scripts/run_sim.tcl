# ============================================================================
# Script: run_sim.tcl
# Description: Tcl automation script for Vivado XSIM / batch HDL simulators to
#              compile, elaborate, and run behavioral simulation for the
#              Digital Vending Machine project.
# ============================================================================

# Define relative path root
set proj_dir [file normalize [file join [file dirname [info script]] ".."]]
set rtl_dir  [file join $proj_dir "rtl"]
set tb_dir   [file join $proj_dir "tb"]
set sim_dir  [file join $proj_dir "sim"]

puts "======================================================================="
puts "       DIGITAL VENDING MACHINE — RUNNING BEHAVIORAL SIMULATION        "
puts "======================================================================="
puts "Project Directory : $proj_dir"
puts "RTL Directory     : $rtl_dir"
puts "TB Directory      : $tb_dir"
puts "SIM Output Dir    : $sim_dir"
puts "======================================================================="

# Ensure output directory exists
file mkdir $sim_dir

# List of RTL design files
set rtl_files [list \
    [file join $rtl_dir "coin_processor.v"] \
    [file join $rtl_dir "payment_evaluator.v"] \
    [file join $rtl_dir "product_catalog.v"] \
    [file join $rtl_dir "payment_accumulator.v"] \
    [file join $rtl_dir "change_calculator.v"] \
    [file join $rtl_dir "refund_controller.v"] \
    [file join $rtl_dir "online_payment_interface.v"] \
    [file join $rtl_dir "dispense_controller.v"] \
    [file join $rtl_dir "vending_fsm.v"] \
    [file join $rtl_dir "vending_machine_top.v"] \
]

# Testbench source
set tb_file [file join $tb_dir "vending_machine_tb.v"]

# Execute Vivado XSim flow if running inside Vivado Tcl shell
if {[info commands xvlog] ne ""} {
    puts "--> Compiling Verilog sources with xvlog..."
    foreach f $rtl_files {
        exec xvlog -work worklog $f
    }
    exec xvlog -work worklog $tb_file

    puts "--> Elaborating design with xelab..."
    exec xelab -debug typical worklog.vending_machine_tb -s vending_machine_tb_sim

    puts "--> Running simulation with xsim..."
    exec xsim vending_machine_tb_sim -runall
    puts "--> Vivado XSim simulation completed successfully."
} else {
    puts "--> Tcl environment initialized. For shell execution, run using:"
    puts "    iverilog -g2001 -o sim/vending_machine_tb.vvp tb/vending_machine_tb.v rtl/*.v"
    puts "    vvp sim/vending_machine_tb.vvp"
}
