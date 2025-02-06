#!/bin/bash
# Script which attempts to quantify GPU Power Efficiency by varying
# the GPU Frequency while the 'gpu_burn' stress test runs.
# NOTE: the script does not modify the existing Power Cap
###################################################################

# Function definitions
restore_gpu_freq () {
    # reset GPU Frequency range back to original
#    echo "GPU Frequencies being restored..."

    # Uses GLOBAL vars
    # do not supress the output. Helpful for user to know.
    nvidia-smi -lgc $min_freq,$max_freq

    # Verify
    if [ $? != 0 ]; then
        echo "Unable to reset GPU Frequency"
        echo "Query frequencies using nvidia-smi cmdline utility"
        exit 2
    fi

    echo; echo "GPU Frequencies successfully restored. Exiting"
}

# Include the PCP Functions file
source $PWD/pcpfile.sh

# PCP Dirs and Files
# NOTE: pcp_archive_name is defined in Workload while-loop
pcp_conf_file="$PWD/pcp_conf_file.cfg"
pcp_archive_dir="$PWD/archive.$(date +%Y%m%d%H%M%S)"

# Configure GPU Frequencies for the test runs
# MIN and MAX are hardcoded for Nvidia A100
min_freq=210
max_freq=1410
multiplier=2           # how much to increase frequency for next test

# Define Timings
delay=15             # Fixed DELAY between INNER-LOOP runs
runtime=100          # Runtime duration for each 'gpu-burn' run
pcp_sample_rate=5    # Sample time for PMLOGGER recorded Metrics

# Define workload
executable="/home/John/gpu_burn"
options="-c /home/John/compare.ptx"
workload="${executable} ${options} ${runtime}"
# Record GFLOPS for the run
parsing="| tac | grep -m 1 Gflop"          # specific to gpu_burn output
exec_str="${workload} ${parsing}"
echo "Workload: ${workload}"
echo " Exec string: ${exec_str}"

# Verify workload is available on the system
if [ ! -x "$executable" ]; then
  echo "File ${executable} is not found. Exiting"
  exit 1
fi

# OUTER Loop - incrementally increase GPU Frequency
# Initialize vars for first loop
loop_ctr=1
this_freq=$(( min_freq*loop_ctr ))

while [ $this_freq -lt $max_freq ]; do
    echo "GPU Freq for this set of runs: ${this_freq}"
    # Apply GPU Frequency
    nvidia-smi -lgc $min_freq,$this_freq > /dev/null 2>&1

    pcp_archive_name="${this_freq}watts"

    # Start PMLOGGER to create ARCHIVE
    pcp_verify $pcp_conf_file
    pcp_start $pcp_conf_file $pcp_sample_rate $pcp_archive_dir $pcp_archive_name

    # INNER Loop - repeat Workload for 5 samples
    echo -n "Sample "
    for sample_ctr in {1..5}; do
        echo -n "${sample_ctr} "
        sleep $delay
        return=$(eval "$exec_str")            # Run the Workload
        echo $return
    done

    echo                             # complete the new-line

    # Terminate PMLOGGER. Flush buffers by sending SIGUSR1 signal
    pcp_stop

    # Verify PCP ARCHIVE was created
    echo; echo "${pcp_archive_dir}"
    ls -l "${pcp_archive_dir}"

    echo; echo "------------------"

    # Initialize vars for next loop. Bail when you exceed MAX_FREQ
    ((loop_ctr++))
    this_freq=$(( min_freq*loop_ctr ))
done

# Reset GPU Frequencies
restore_gpu_freq

echo "DONE"

