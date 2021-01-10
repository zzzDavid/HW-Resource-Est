#!/bin/bash

rm utilization.txt
rm vivado*
rm decoder.dcp
vivado -mode tcl -source synth.tcl