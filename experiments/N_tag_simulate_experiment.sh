#!/bin/sh
#Authors: Ayatallah Elakhras <ayatallah.elakhras@epfl.ch>

export TODAY_IS=`date +%F%H%M%S`

#environment variables for gurobi
export GUROBI_HOME="/opt/gurobi951/linux64"
export PATH="${PATH}:${GUROBI_HOME}/bin"
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
export LD_LIBRARY_PATH="${GUROBI_HOME}/lib"
export GRB_LICENSE_FILE=/opt/gurobi951/gurobi.lic


file=filelist_N_exp.lst
clean="clean"

benchmark_directory=$(pwd)"/benchmarks/bicg"
path_to_tagging_info_directory="/home/dynamatic/Dynamatic/etc/dynamatic/"

experiment_type="N_tags"


i=0
myArray=(2 3 4 5 6 7 8 9 10 11 12 14 20)

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
        echo -e 'true\n'${myArray[$i]}'\n1\n_\n7' > ${benchmark_directory}"/tagging_info.txt"
        echo ${benchmark_directory}"/tagging_info.txt" > ${path_to_tagging_info_directory}/path_to_tagging_info.txt
        report_file=bicg_N_${myArray[$i]}_detailed_sim.rpt
        report=bicg_N_${myArray[$i]}_verification.rpt
        cycle_file=bicg_N_${myArray[$i]}_cycles_count.rpt
        simulation_scripts/regression_test.sh $line $report $report_file $cycle_file $experiment_type
        # copy the generated sim directory to save it to be used for synthesis later; otherwise it gets overwritten by the next N
        cp -r ${benchmark_directory}/sim simulation_reports_N_tags/resulting_simulation_files/bicg_N_${myArray[$i]}/sim

        ((i=i+1))

    fi
 
done < "$file"

