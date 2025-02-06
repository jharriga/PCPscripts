#!/bin/bash
# Script which runs the SYSBENCH CPU stressor and creates a PCP
# Archive with metrics as specified in the $pcp_conf_file
# NOTE: the number of samples runs is hard-coded to 5
###################################################################

# Include the PCP Functions file
source $PWD/pcp_functions.sh

# PCP Dirs and Files
# NOTE: pcp_archive_name is defined in Workload while-loop
pcp_conf_file="$PWD/pcp_sysbench.cfg"
pcp_archive_dir="$PWD/archive.$(date +%Y%m%d%H%M%S)"

# Define Timings
delay=15             # Fixed DELAY between INNER-LOOP runs
runtime=100          # Runtime duration for each workload run
pcp_sample_rate=5    # Sample time for PMLOGGER recorded Metrics

# Define workload
thread_cnt=$(nproc)                       # record number of cores
pcp_archive_name="${thread_cnt}threads"
runlog="${pcp_archive_dir}/${pcp_archive_name}.runlog"
## use an array to build up cmdline with runtime args
workload=( sysbench cpu run --time="$runtime" --threads="$NPROC" )

##workload="${executable} ${options} ${runtime}"
parsing=">>$runlog 2>&1"                # specific to $workload output
exec_str="${workload[@]} ${parsing}"

echo "Workload: ${workload[@]}"
echo " Exec string: ${exec_str}"
echo "Number of threads for this set of runs: ${thread_cnt}"

# Verify workload is available on the system
if [ ! -x "$executable" ]; then
  echo "File ${executable} is not found. Exiting"
  exit 1
fi

#----------------------------------
# Start PMLOGGER to create ARCHIVE
pcp_verify $pcp_conf_file
pcp_start $pcp_conf_file $pcp_sample_rate $pcp_archive_dir $pcp_archive_name

# Loop - repeat Workload for 5 samples
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

echo "DONE"
