#!/bin/bash
# Collection of utility Functions for working with Perf Co-Pilot
# - pcp_verify($cfg_file)
# - pcp_start($cfg_file, $sample_rate, $archive_dir, $archive_name)
# - pcp_stop()
#
# NOTE: use of these Functions require that PCP is already installed on the system 
##################################################################################

# Global VARs
# PCP Dirs and Files
# NOTE: pcp_archive_name is defined in Workload while-loop
##pcp_conf_file="$PWD/pcp_conf_file.cfg"
##pcp_archive_dir="$PWD/archive.$(date +%Y%m%d%H%M%S)"

##pcp_sample_rate=5    # Sample time for PMLOGGER recorded Metrics

#-------------------------------------------------------

pcp_verify()
{
    cfg_file="$1"          # PMLOGGER Configuration File

# Verify PMCD is running (pcp-zeroconf is installed)
    pgrep pmcd > /dev/null
    if [ $? != 0 ]; then
        echo "PCP pmcd is not running. Is PCP installed?"
        echo "Suggested syntax: sudo dnf install pcp-zeroconf"; echo
        exit 2
    fi

# Verify primary pmlogger is not running
    pgrep pmlogger > /dev/null
    if [ $? == 0 ]; then
        echo "Primary PCP pmlogger is running. It must be stopped to run script"
        echo "Suggested syntax: sudo systemctl stop pmlogger"; echo
        exit 2
    fi

# Verify user provided pmlogger.conf file exists. If not abort.
    if [ ! -f "$cfg_file" ]; then
        echo "File $cfg_file not found!"; echo
        exit 2
    fi

    # TBD: use 'pmlogger -c $PWD/$cfg_file -C' to Verify syntax

}

pcp_start()
{
    echo "PCP Starting pmlogger"

    cfg_file="$1"
    sample_rate="$2"
    archive_dir="$3"
    archive_name="$4"

    mkdir -p ${pcp_archive_dir}

# Run PCP logger
# JTH - VERIFY success, ensure pmlogger starts
    pmlogger -c "${cfg_file}" -t "$sample_rate" -l "${archive_dir}/${archive_name}.log" "${archive_dir}/${archive_name}" &

# Sleep 5 seconds prior to continuing and starting workload
    sleep 5

# JTH - VERIFY success, ensure pmlogger started and remained running
    pgrep pmlogger > /dev/null
    if [ $? != 0 ]; then
        echo "FAILED to Start PCP pmlogger. Aborting test."; echo
# Reset GPU Frequencies
        restore_gpu_freq
        exit 2
    fi

}

pcp_stop()
{
    echo "PCP Stop. Stopping pmlogger, creating archive"

# Stop PCP logger and pause for pmlogger to write archive
    pkill -USR1 pmlogger
    sleep 3

# JTH - VERIFY success, ensure pmlogger stops
    pid=$(pgrep pmlogger)
    if [ $? == 0 ]; then
        echo "FAILED to Stop PCP pmlogger. PID $pid should be manually stopped"
        echo                  # improves output readability
    fi
}

#-------------------------------------------------------



