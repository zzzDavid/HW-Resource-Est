module NoC #(
    parameter num_channel = 1,
    parameter PIPENUM = 4,
    parameter D_W = 512,
    parameter DDR_num = 4
)(
    input wire clk,
    input wire rst,
    input wire [D_W-1:0] from_DDR [DDR_num-1:0],
    output wire done [DDR_num-1:0][num_channel-1:0],
    output wire [D_W-1:0] to_pe  [DDR_num-1:0][num_channel-1:0]
);

// connection wires
wire [D_W-1:0] horiz  [DDR_num-1:0][num_channel-1:0]; // east bound channels
genvar x, c;
generate 
for (x = 0; x < DDR_num; x = x + 1) begin : xs
    for (c = 0; c < num_channel; c = c + 1) begin : cs
        // adding don't touch to prevent vivado from removing NoC node
        // because DDR data is not real now
        (* dont_touch = "true" *) hoplite #(
            .D_W(D_W),
            .PIPENUM(PIPENUM)
        ) hoplite_inst(
            .clk(clk),
            .rst(rst),
            .n_in(from_DDR[x]), // north DDR input
            .w_in(horiz[(x-1+DDR_num)%DDR_num][c]), // west input data
            .e_out(horiz[x][c]), // east output data
            .pe_out(to_pe[x][c]), // sourth output data
            .done(done[x][c])  // done signal
        );
    end

end
endgenerate 

endmodule