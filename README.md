# Survival of the Fastest: Enabling More Out-of-Order Execution in Dataflow Circuits
This repository holds the source code, benchmarks and results of the work presented in the "Survival of the Fastest: Enabling More Out-of-Order Execution in Dataflow Circuits" paper, which allows for new levels of out-of-order execution, not achievable by prior work, in dataflow circuits.

## Prerequisites
1) We prepared a virtual machine (VM) containing an installation of the Dynamatic tool, that we implemented our technique within, with its dependencies. It also contains an installation of Modelsim 20.1, which we use to get the cycles count. The VM is available through the following link https://drive.google.com/file/d/1-WE5ffLJNCAGaBMgAMR08HGpS6jcgVTJ/view and is compatible with VirtualBox 5.2 or above. Please follow the following steps to install it:
   - Extract the zip file of the VM image on your machine. The extracted folder contains a .vbox, which contains the settings required to run the VM and the .vdi, which contains the virtual hard drive.
   - Add the machine by opening the VirtualBox application and clicking on "Machine" -> "+Add", then selecting the file "DynamaticVM.vbox".
   - Start the machine by clicking on "Start".
   - In case of resolution issues, go to "View" -> " + Virtual Screen 1" and choose a zoom factor that best suits your screen, for instance 300. Then, go to "View" and select the option "Full screen mode".
3) Installation of Vivado 2019.2

## Repository Organization

This repository is composed of two main directories:
1) plugins/ holds the implementation of the technique presented in the paper as a set of plugins that should be installed into the Dynamatic tool through the provided install_plugins.sh script.
2) experiments/ holds the (i) C++ source code files of the benchmarks used for generating the results reported in the paper, (ii) the tagging information for each benchmark composed of the number of tags used and information about which components are out-of-order or MERGEs, (iii) hls_verifier that verifies the correctness of the generated circuits, (iv) scripts that automate the process of running the HLS tool, simulating, synthesizing the generated designs and reporting the results.


## Results Reproduction

### Clone this repository
Inside the VM, execute the following commands from a terminal.
```
cd Dynamatic/etc/dynamatic/
git clone git@github.com:EPFL-LAP/fpga24-more-ooo.git
```

### Install our plugins inside Dynamatic
To install our plugins into Dynamatic's infrastructure, run the following commands from a terminal. 
```
cd Dynamatic/etc/dynamatic/fpga24-more-ooo/
chmod +x install_plugins.sh
bash ./install_plugins.sh
```
### Run the HLS flow and simulate the designs
To generate our tagged circuits for each of the C++ source files of our benchmarks, run the following commands from a terminal. 
```
cd Dynamatic/etc/dynamatic/fpga24-more-ooo/experiments
chmod +x compile_simulate_test_ours.sh
bash ./compile_simulate_test_ours.sh
```
The previous commands do the following for each of the benchmarks, one after the other:
1) Run our HLS flow to generate VHDL netlists
2) Simulate the generated designs using Modelsim 20.1 to report the cycles count
3) Run the HLS verifier to verify the correctness of our designs.

The outcome of this step is the generation of the following reports for each benchmark in the Dynamatic/etc/dynamatic/fpga24-more-ooo/experiments/simulation_reports_ours/ directory, where benchmarkName is replaced with the corresponding benchmark name.
1) benchmarkName_detailed_sim.rpt which contains the detailed report that records the outputs of the different passes of Dynamatic as well as outputs from the Modelsim simulation. 
2) benchmarkName_verification.rpt which reports the output of the HLS verifier. A "Pass" indicates the correcntess of the design.
3) benchmarkName_cycles_count.rpt which contains the simulation time and the cycle count of the corresponding benchmark.

If you would like to check the generated designs (HDL netlists), go to the Dynamatic/etc/dynamatic/fpga24-more-ooo/experiments/benchmarks/benchmarkName/hdl directory, where benchmarkName should be the name of the benchmark of your choice.

If you would like to simulate the generated desgins using Modelsim, go to the Dynamatic/etc/dynamatic/fpga24-more-ooo/experiments/benchmarks/benchmarkName/sim/HLS_VERIFY directory where you will find the Modelsim project there.

To generate the untagged baseline's circuits for each of the C++ source files of our benchmarks, run the following commands from a terminal. 
```
cd Dynamatic/etc/dynamatic/fpga24-more-ooo/experiments
chmod +x compile_simulate_test_baseline.sh
bash ./compile_simulate_test_baseline.sh
```

### Synthesize and place and route
[TO ADD the files needed for FP synthesis to the repo...] [Also, to require a specific path for Vivado's installation..]

## Contact
For any questions, please contact Ayatallah Elakhras (ayatallah.elakhras@epfl.ch).
