create_project pack -f ./pack -part xcvu9p-fsgd2104-3-e

read_verilog pack.v

synth_design -top pack -mode out_of_context;
report_utilization -file pack_utilization.txt;
write_checkpoint -force -file pack.dcp
exit
