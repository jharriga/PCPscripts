#!/bin/bash
# Script which attempts to quantify GPU Power Efficiency by varying
# the GPU Frequency while the 'gpu_burn' stress test runs.
# NOTE: the script does not modify the existing Power Cap
###################################################################

# Include the PCP Functions file
source $PWD/pcp_functions.sh

# PCP Dirs and Files
# NOTE: pcp_archive_name is defined in Workload while-loop
pcp_conf_file="$PWD/pcp_conf_file.cfg"
pcp_archive_dir="$PWD/archive.$(date +%Y%m%d%H%M%S)"

# Define Timings
delay=15             # Fixed DELAY between INNER-LOOP runs
runtime=100          # Runtime duration for each workload run
pcp_sample_rate=5    # Sample time for PMLOGGER recorded Metrics

# Define workload
NPROC=$(nproc)                          # record number of cores
##runlog="${PCPARCHIVE_DIR}/${PCPARCHIVE_NAME}.runlog"
## use an array to build up cmdline with runtime args
workload=( sysbench cpu run --time="$runtime" --threads="$NPROC" )

##workload="${executable} ${options} ${runtime}"
# Record GFLOPS for the run
##parsing="| tac | grep -m 1 Gflop"          # specific to gpu_burn output
##exec_str="${workload} ${parsing}"

echo "Workload: ${workload[@]}"
##echo " Exec string: ${exec_str}"

# Verify workload is available on the system
if [ ! -x "$executable" ]; then
  echo "File ${executable} is not found. Exiting"
  exit 1
fi

# OUTER Loop - incrementally increase number of threads
# Initialize vars for first loop
loop_ctr=1
thread_cnt=$(( min_freq*loop_ctr ))

while [ $thread_cnt -lt $NPROC ]; do
    echo "Number of threads for this set of runs: ${thread_cnt}"
    pcp_archive_name="${thread_cnt}threads"

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

echo "DONE"
