import os
import sys
import argparse

# --- Constants for Compilation/Elaboration ---
CMD_COMPILE = "vsim -c -do compile.do"
CMD_ELABORATE = "vsim -c -do elaborate.do"

def run_command(command, step_name):
    """Runs a shell command and exits if it fails."""
    print(f"\n--- INFO: Starting Step: {step_name} ---")
    print(f"Executing: {command}")
    
    # We use subprocess.run for better control and error handling
    # but os.system is kept here to match the original style
    return_code = os.system(command) 
    
    if return_code != 0:
        print(f"\n--- ERROR: Step '{step_name}' failed! ---")
        input("\nPress Enter to see the error and exit...")
        sys.exit(1) # Exit the script with an error

# --- Main Script Execution Block ---
try:
    # --- 1. Define and Parse Arguments (Must happen before using 'args') ---
    parser = argparse.ArgumentParser(description="Run QuestaSim simulation for Lab 1")
    # Add a '--gui' flag. 'action' means it's just a switch.
    parser.add_argument('--gui', action='store_true', help="Run simulation in GUI mode for debugging.")
    # Add a '--seed' argument. It takes an integer value.
    parser.add_argument('--seed', type=int, default=1, help="Set the random number seed for simulation.")
    # Add a '--test' argument. This will be the name of our run.
    parser.add_argument('--test', type=str, default='base_test', help="Name of the test. Used for log/wlf filenames.")
    
    # This line reads the command line arguments
    args = parser.parse_args()

    # --- 2. Clean up (FIXED for Windows 'rm' error) ---
    print("\n--- INFO: Cleaning up previous run files... ---")
    if os.name == 'nt': # Check for Windows
        # Use 'del' for files and 'rmdir' for directories, suppressing errors (2>nul)
        # We run the commands sequentially using '&'
        os.system("del /f /q *.log *.wlf 2>nul & rmdir /s /q work lab1_opt lab6_opt 2>nul")
    else: # Linux/macOS/POSIX
        os.system("rm -rf work *.log *.wlf lab1_opt lab6_opt")
    
    # --- 3. Run Compile and Elaborate ---
    run_command(CMD_COMPILE, "Compile")
    run_command(CMD_ELABORATE, "Elaborate")

    # --- 4. Build the Simulate Command ---
    # Dynamically create filenames based on the test name
    log_file = f"{args.test}.log" 
    wlf_file = f"{args.test}.wlf" 
    
    # Start with the base command, using our new variables
    # FIXED: Changed 'lab1_opt' to 'lab6_opt' to match the Elaborate output.
    cmd = ( f"vsim mid_course_project_opt -voptargs=+acc " f"-sv_seed {args.seed} ")
    
    # Now, add the GUI or Batch mode commands conditionally
    if args.gui:
        # GUI Mode: Open the GUI, add waves, and run
        print("INFO: GUI mode detected. Opening GUI...")
        cmd += ' -gui'
        
        cmd += ' -do "add wave -r /*; run -all"' 
    else: 
        # Batch Mode: Run in console, run, and quit
        print("INFO: Batch mode detected. Running...")
        cmd += ' -c'
        cmd += f" -logfile {log_file} -wlf {wlf_file}"
        
        cmd += ' -do "add wave -r /*; run -all; quit -f"' 
        
    # Run the final, dynamically-built command
    run_command(cmd, "Simulate")
    
    print(f"\n--- INFO: All steps completed. Check {log_file} for results. ---")

except Exception as e:
    # Handles errors from argument parsing or any step failure
    print(f"\n--- FATAL ERROR: An unexpected error occurred: {e} ---")
    input("\nPress Enter to exit...")
    sys.exit(1)
