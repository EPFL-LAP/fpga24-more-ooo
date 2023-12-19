# Survival of the Fastest: Enabling More Out-of-Order Execution in Dataflow Circuits
This repository holds the source code, benchmarks and results of the work presented in the "Survival of the Fastest: Enabling More Out-of-Order Execution in Dataflow Circuits" paper, which allows for new levels of out-of-order execution, not achievable by prior work, in dataflow circuits.

## Prerequisites
1) We prepared a virtual machine (VM) containing an installation of the Dynamatic tool, that we implemented our technique within, with its dependencies. It also contains an installation of Modelsim 20.1, which we use to get the cycles count. The VM is available through the following link [TO ADD] and is compatible with VirtualBox 5.2 or above. Please follow the following steps to install it:
   - Extract the zip file of the VM image on your machine. The extracted folder contains a .vbox, which contains the settings required to run the VM and the .vdi, which contains the virtual hard drive.
   - Add the machine by opening the VirtualBox application and clicking on "Machine" -> "+Add", then selecting the file "DynamaticVM.vbox".
   - Start the machine by clicking on "Start".
   - In case of resolution issues, go to "View" -> " + Virtual Screen 1" and choose a zoom factor that best suits your screen, for instance 300. Then, go to "View" and select the option "Full screen mode".
3) Installation of Vivado 2019.2

## Repository Organization

## Results Reproduction

### Clone this repository

### Ensure that tools installations comply with our scripts

### Install our plugins into Dynamatic

### Run the HLS flow and simulate the designs

### Synthesize and place and route
[TO ADD the files needed for FP synthesis to the repo...]

## Contact
For any questions, please contact Ayatallah Elakhras (ayatallah.elakhras@epfl.ch).
