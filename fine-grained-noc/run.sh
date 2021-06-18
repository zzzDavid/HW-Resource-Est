#!/bin/bash

rm utilization.txt
rm vivado*
rm *.dcp
vivado -mode tcl -source synth.tcl