
create_project finegrain -f ./project -part xcvu9p-fsgd2104-3-e

read_verilog pe.v
read_verilog omni_switch.v

# set_property generic num_channel=3 [current_fileset]

synth_design -top omni_switch -mode out_of_context;
report_utilization -file utilization.txt;
write_checkpoint -force -file fine_grained.dcp
exit
