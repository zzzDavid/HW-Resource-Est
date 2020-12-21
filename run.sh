#!/bin/bash

rm utilization.txt
rm noc.dcp
vivado -mode tcl -source synth.tcl
rm vivado*