#!/bin/sh
#Authors: Andrea Guerrieri <andrea.guerrieri@epfl.ch> Ayatallah Elakhras <ayatallah.elakhras@epfl.ch>

export TODAY_IS=`date +%F%H%M%S`

#environment variables for gurobi
export GUROBI_HOME="/opt/gurobi951/linux64"
export PATH="${PATH}:${GUROBI_HOME}/bin"
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
export LD_LIBRARY_PATH="${GUROBI_HOME}/lib"
export GRB_LICENSE_FILE=/opt/gurobi951/gurobi.lic


# report_file=regression_test_detailed_$TODAY_IS.rpt
# report=regression_test_$TODAY_IS.rpt

file=filelist.lst
clean="clean"

benchmarks_directory=$(pwd)"/benchmarks"
path_to_tagging_info_directory="/home/dynamatic/Dynamatic/etc/dynamatic/"

experiment_type="baseline"

i=0
myArray=(gemm matvec mvt bicg img_avg)

while IFS= read -r line
do
    if [ "$clean" = "$1" ]; then
    	echo "Clean-up" $line
    	rm $line/dynamatic_*
    	rm -r $line/hdl
    	rm -r $line/reports
    	rm -r $line/sim
    else
    	echo "Testing" $line
        echo ${benchmarks_directory}"/"${myArray[$i]}"/untagged_baseline.txt" > ${path_to_tagging_info_directory}/path_to_tagging_info.txt
    	report_file=${myArray[$i]}_detailed_sim.rpt
        report=${myArray[$i]}_verification.rpt
        cycle_file=${myArray[$i]}_cycles_count.rpt
        simulation_scripts/regression_test.sh $line $report $report_file $cycle_file $experiment_type
        ((i=i+1))
    fi
 
done < "$file"

