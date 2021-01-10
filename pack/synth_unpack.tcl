create_project unpack -f ./unpack -part xcvu9p-fsgd2104-3-e

read_verilog unpack.v


synth_design -top unpack -mode out_of_context;
report_utilization -file unpack_utilization.txt;
write_checkpoint -force -file unpack.dcp
exit
