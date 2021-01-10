create_project decoder -f ./decoder -part xcvu9p-fsgd2104-3-e

read_verilog top.v
read_verilog load_ins_parser.v
read_verilog save_ins_parser.v

# set_property generic num_channel=3 [current_fileset]

synth_design -top decoder -mode out_of_context;
report_utilization -file utilization.txt;
write_checkpoint -force -file decoder.dcp
exit
