# ============================================================================
# Script: build_project.tcl
# Description: Vivado Tcl automation script to create/recreate the Vivado project,
#              add design sources, hardware wrappers, XDC constraints, and
#              testbenches, configure synthesis/simulation settings, and run
#              synthesis, implementation, timing, utilization, and bitstream generation.
# Standard: Xilinx Vivado Tcl Toolchain (2019.2+)
# ============================================================================

# Project directory definitions
set script_dir [file dirname [info script]]
set proj_dir   [file normalize [file join $script_dir ".."]]
set vivado_dir [file join $proj_dir "vivado"]
set rtl_dir    [file join $proj_dir "rtl"]
set tb_dir     [file join $proj_dir "tb"]
set constr_dir [file join $proj_dir "constraints"]

set project_name "VendingMachine"
set part_number  "xc7a35tcpg236-1" ;# Standard Digilent Basys-3 / Artix-7 evaluation part

puts "======================================================================="
puts "       DIGITAL VENDING MACHINE — VIVADO BUILD & SYNTHESIS              "
puts "======================================================================="
puts "Project Name : $project_name"
puts "Project Path : $vivado_dir"
puts "Target Part  : $part_number"
puts "======================================================================="

# Ensure target vivado directory exists
file mkdir $vivado_dir

# Create Vivado project non-interactively
create_project $project_name $vivado_dir -part $part_number -force

# Set target project properties
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property default_lib work [current_project]

# Add RTL source files
puts "--> Adding RTL source files..."
set rtl_files [glob -nocomplain [file join $rtl_dir "*.v"]]
if {[llength $rtl_files] > 0} {
    add_files -norecurse $rtl_files
}

# Add Testbench files (simulation only)
puts "--> Adding Simulation Testbench files..."
set tb_files [glob -nocomplain [file join $tb_dir "*.v"]]
if {[llength $tb_files] > 0} {
    add_files -fileset sim_1 -norecurse $tb_files
}

# Add Constraint files
puts "--> Adding XDC Constraint files..."
set xdc_files [glob -nocomplain [file join $constr_dir "*.xdc"]]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 -norecurse $xdc_files
}

# Set Top Modules (Hardware Wrapper for Synthesis/Impl, Testbench for Simulation)
set_property top vending_machine_board_wrapper [current_fileset]
set_property top vending_machine_tb [get_filesets sim_1]
set_property top_lib work [get_filesets sim_1]

# Update Compile Order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "======================================================================="
puts "   VIVADO PROJECT CREATION COMPLETE: $vivado_dir/$project_name.xpr    "
puts "======================================================================="

# Run Synthesis
puts "--> Launching Vivado Synthesis (synth_1)..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed. Inspect synth_1 log for details."
} else {
    puts "--> Synthesis completed successfully."

    # Run Implementation
    puts "--> Launching Vivado Implementation (impl_1)..."
    launch_runs impl_1 -jobs 4
    wait_on_run impl_1

    if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
        puts "ERROR: Implementation failed. Inspect impl_1 log for details."
    } else {
        puts "--> Implementation completed successfully."

        # Open Implementation Run for Timing and Utilization Analysis
        open_run impl_1

        # Generate Reports
        puts "--> Generating Utilization Report..."
        report_utilization -file [file join $vivado_dir "utilization_report.txt"]

        puts "--> Generating Timing Summary Report..."
        report_timing_summary -file [file join $vivado_dir "timing_summary_report.txt"]

        # Generate Bitstream
        puts "--> Launching Bitstream Generation..."
        launch_runs impl_1 -to_step write_bitstream -jobs 4
        wait_on_run impl_1
        puts "--> Bitstream generation completed."
    }
}
