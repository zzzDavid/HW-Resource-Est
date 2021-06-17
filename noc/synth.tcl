create_project hoplite_noc -f ./hoplite_noc -part xcvu9p-fsgd2104-3-e

read_verilog NoC.v 
read_verilog hoplite.v

set_property generic num_channel=4 [current_fileset]

synth_design -top NoC -mode out_of_context;
report_utilization -file utilization_channel4.txt;
write_checkpoint -force -file noc.dcp
exit
