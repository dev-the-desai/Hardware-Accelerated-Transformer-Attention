



# ECE464/564 HW6
This document contains the instructions and commands to setup HW6 directory. In the folder tree of this HW, several ```Makefile```s are used to 

## Overview
- [Unzip](#unzip)
- [Start Designing](#start-designing)
- [Synthesis](#synthesis)
- [Submission](#submission)
- [Appendix](#appendix)

## Unzip
Once you have placed ```HW6.zip``` at desired directory. Launch a terminal at that directory and use the following command to unzip.
```bash
unzip HW6.zip
```
You should find the unzipped HW6 folder ```HW6/```

## Start Designing
### Setup script

```HW6/setup.sh``` is provided to load Modelsim and Synopsys

To source the script:
```bash
source setup.sh
```
This script also enables you to <kbd>Tab</kbd> complete ```make``` commands

### HW6 description

The document is located in ```HW6/HW_specification/```

### Where to put your design

A Verilog file ```HW6/rtl/dut.sv``` is provided with all the ports already connected to the test fixture

### How to compile your design

To compile your design

Change directory to ```HW6/run/``` 

```bash
make build-dw
make build
```

All the .sv files in ```HW6/rtl/``` will be compiled with this command.

### How to run your design

Run with Modelsim UI 564:
```bash
make debug
```

### Evaluation Testing
To evaluate you design headless/no-gui, change directory to ```HW6/run/```
```
make eval
```
This will produce a set of log files that will highlight the results of your design. This should only be ran as a final step before Synthesis

All log files is in the following directory ```HW6/run/logs```

All test resutls is in the results log file ```HW6/run/logs/RESULTS.log```

All simulation resutls is in the following log file ```HW6/run/logs/output.log```

All simulation info is in the following log file ```HW6/run/logs/INFO.log```

## Synthesis

Once you have a functional design, you can synthesize it in ```HW6/synthesis/```

### Synthesis Command
The following command will synthesize your design with a default clock period of 10 ns
```bash
make all
```
### Clock Period

To run synthesis with a different clock period
```bash
make all CLOCK_PER=<YOUR_CLOCK_PERIOD>
```
For example, the following command will set the target clock period to 4 ns.

```bash
make all CLOCK_PER=10
```

## Appendix

### Directory Rundown

You will find the following directories in ```HW6/```

* ```inputs/``` 
  * Contains the .dat files for the input SRAMs used in HW 
* ```HW_specification/```
  * Contains the HW specification document
* ```rtl/```
  * All .v files will be compiled when executing ```make vlog-v``` in ```HW6/run/```
  * A template ```dut.v``` that interfaces with the test fixture is provided
* ```run/```
  * Contains the ```Makefile``` to compile and simulate the design
* ```scripts/```
  * Contains the python script that generates a random input/output
* ```synthesis/```
  * The directory you will use to synthesize your design
  * Synthesis reports will be exported to ```synthesis/reports/```
  * Synthesized netlist will be generated to ```synthesis/gl/```
* ```testbench/```
  * Contains the test fixture of the HW


