# README

Provides pcp_function.sh, a collection of utility functions for integrating Performance
Co-Pilot archive creation into bash scripts. The functions are
* pcp_verify()
* pcp_start()
* pcp_stop()  
  **NOTE: the system must have PCP installed and running or these functions will fail** 

## Usage example are provided:
* sysbench_example.sh: executes the 'sysbench' CPU stressor on all cores for 5 samples, and creates PCP Archive
  
The example script includes a PCP pmlogger configuration file. The contents of that
file specifies the PCP metrics to be recorded in the PCP Archive
* pcp_sysbench.cfg  
  **NOTE: both the script and configuration files are heavily commented**

## To run the 'sysbench_example.sh' script
> Clone the repo and 'cd' into it  
> $ chmod 755 *.sh  
> $ ./sysbench_example.sh  

### View PCP Archive contents
Both example scripts will output the name and file contents of the PCP Archive
directory. Various PCP utilities can be used to view the created archives.  
> To dump the Archive contents (timestamps, metrics and readings):   
> $ pmdumplog archive.20250206125655/144threads
>   
> To see the timestamped readings for a specific metric set:  
> $ pmrep -p -a archive.20250206125655/144threads kernel.all

