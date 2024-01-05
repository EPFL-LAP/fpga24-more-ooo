#!/bin/sh
#Author: Ayatallah Elakhras <ayatallah.elakhras@epfl.ch>

workingdir="$(pwd)/synth_place_route_reports_N_tags"
file=filelist_N_exp.lst
i=0
myArray=(2 3 4 5 6 7 8 9 10 11 12 14 20)

timing_rpt=timing_post_pr.rpt
util_rpt=utilization_post_pr.rpt
sim_report_dir=simulation_reports_N_tags
clk_period=4

path="simulation_reports_N_tags/resulting_simulation_files"

# generate the summary reports
while IFS= read -r line
do
    # first create the synth directory by copying the needed scripts
    cp -r synth_place_route_scripts/bicg/synth ${path}/bicg_N_${myArray[$i]}/
    cd ${path}/bicg_N_${myArray[$i]}/synth/
    /softs/xilinx/Vivado/2019.2/bin/vivado -mode batch -source synthesize_4.tcl
    cd ../../../../
    # generate summary reports
    synth_summary_rpt=bicg_N_${myArray[$i]}_synth_p_r_summary.rpt
    str=`grep -A 2 "Timing Report" "${path}/bicg_N_${myArray[$i]}/synth/${timing_rpt}"`
    slack_with_unit=`echo $str | cut -d' ' -f 6`
    slack=`echo $slack_with_unit | cut -d'n' -f 1`
    actual_cp=`echo "$clk_period - $slack" | bc`
    echo "**************************************************" >> $workingdir/$synth_summary_rpt
    echo "Timing Summary for the bicg_N_${myArray[$i]} example" >> $workingdir/$synth_summary_rpt
    echo "The clk period constraint applied during synthesis is 4ns" >> $workingdir/$synth_summary_rpt
    echo "The slack is ${slack}ns" >> $workingdir/$synth_summary_rpt
    echo "The actual clk period (CP) is ${actual_cp}ns" >> $workingdir/$synth_summary_rpt

    #echo " " >> $workingdir/$synth_summary_rpt
    cycle_count_str=`grep "cycles" "${sim_report_dir}/bicg_N_${myArray[$i]}_cycles_count.rpt"`
    #cycle_count=`echo $cycle_count_str | tr -dc '0-9'`
    cycle_count=`echo ${cycle_count_str% *}` 
    cycle_count_final=`echo ${cycle_count##* }`
    echo "The cycles count from simulation is ${cycle_count_final}" >> $workingdir/$synth_summary_rpt
    exec_time=`echo "$cycle_count_final * $actual_cp" | bc`
    echo "The total execution time is ${exec_time}ns" >> $workingdir/$synth_summary_rpt
    echo " " >> $workingdir/$synth_summary_rpt

    echo "**************************************************" >> $workingdir/$synth_summary_rpt
    echo "Area Summary for the bicg_N_${myArray[$i]} example" >> $workingdir/$synth_summary_rpt

    luts_str=`grep "Slice LUTs" "${path}/bicg_N_${myArray[$i]}/synth/${util_rpt}"`
    luts=`echo $luts_str | cut -d'|' -f 3`
    echo "The LUTs count is ${luts}" >> $workingdir/$synth_summary_rpt

    ffs_str=`grep -m 1 "Slice Registers" "${path}/bicg_N_${myArray[$i]}/synth/${util_rpt}"`
    ffs=`echo $ffs_str | cut -d'|' -f 3`
    echo "The FFs count is ${ffs}" >> $workingdir/$synth_summary_rpt

    dsps_str=`grep -m 1 "DSPs" "${path}/bicg_N_${myArray[$i]}/synth/${util_rpt}"`
    dsps=`echo $dsps_str | cut -d'|' -f 3`
    echo "The DSPs count is ${dsps}" >> $workingdir/$synth_summary_rpt

    ((i=i+1))
done < "$file"