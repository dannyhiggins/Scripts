## Script to create 10's or 100's of snapshots of oracle volumes to demonstrate that there's no performance implication
## This script should be used against the PSTGFADB database whilst a high swingbench workload is being run
## The swingbench workload can be run from the oem.puresg.com server - see the preconfigured workload  fbperf_PSTGFADB_OE_OLTP.xml
## Author:      Danny Higgins
## Date:        March 2020
## Version:     1.0
## Pre-reqs:    Run and monitor the workload in SwingBench whilst monitoring the RedDotX array performance and snaps.
##		The relevant ssh keys for passwordles access to $FA_NAME must exist
##		The protecction group $FA_PGROUP must exist and contain the database volujes for PSTGFADB database
## Issues:
###################################################################################
LOG=~/snap_perf_demo.log
FA_NAME=RedDotX
FA_IP="10.226.224.112"
FA_USER=pureuser
FA_PGROUP="fbperf-PSTGFADB"
SNAP_COUNT=50
SNAP_FREQ_SECS=10

logme ()
{
echo "`date`: ${*}" | tee -a ${LOG}
}

run_fa ()
{
ssh -q -o StrictHostKeyChecking=no ${FA_USER}@${FA_IP} ${*}
}

logme "--------------------------------------------------"
logme "Starting Pure FlashArray Snapshot Performance Demo"
logme "Listing existing Snapshots on protection group ${FA_PGROUP}"

run_fa "purepgroup list --snap ${FA_PGROUP}"
logme "Taking ${SNAP_COUNT} new snaphosts of ${FA_PGROUP} at ${SNAP_FREQ_SECS} second intervals"

i=0
until [ $i -eq ${SNAP_COUNT} ]
do
	((i++))
	CURRENT_TIME=`date +%Y%m%d%H%M%S`
	SNAPNAME=SNAP-PERF-DEMO${CURRENT_TIME}
	logme "Taking snapshot ${i} at ${CURRENT_TIME}"
	run_fa "purepgroup snap --suffix ${SNAPNAME} ${FA_PGROUP}"
	sleep ${SNAP_FREQ_SECS}
done

logme "Listing existing Snapshots on protection group ${FA_PGROUP}"
run_fa "purepgroup list --snap ${FA_PGROUP}"

echo "Monitor the Swingbench workload and the FA performance metrics for as long as you need then press <RETURN> to clean up the snapshots...."
read me

logme "Cleaning up all snapshots"
SNAPLIST=`run_fa "purepgroup list --snap --filter \"name = '*SNAP-PERF-DEMO*'\"" | grep ${FA_PGROUP} | awk  '{print $1}'`
for s in ${SNAPLIST}
do 
	#echo $s
	run_fa "purepgroup destroy ${s}"
done

logme "Completed Pure FlashArray Snapshot Performance Demo"
logme "---------------------------------------------------"
