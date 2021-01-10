module hoplite #(
    parameter D_W = 512,
    parameter PIPENUM = 4,
    parameter SCHED = 8,
    parameter LENGTH = 4 // data length?
)(
    input wire clk,
    input wire rst,
    input wire [D_W-1:0] n_in, // input data from DDR
    input wire [D_W-1:0] w_in, // input data from west
    output wire [D_W-1:0] e_out, // output data to east
    output wire [D_W-1:0] pe_out, // output data to PE
    output reg done
);

// dummy selection memory
reg [SCHED-1:0] e_bound_sel_memory[LENGTH-1:0]; // east-bound select memory
reg [SCHED-1:0] pe_bound_sel_memory[LENGTH-1:0]; // pe-bound select memory
// there should be data loading for memory
// but I'll leave it out for now 
initial begin
    done = 0;
end

// register inputs
reg [D_W-1:0] n_in_reg;
reg [D_W-1:0] w_in_reg;
always @(posedge clk) begin
    if (rst) begin
        n_in_reg <= 0;
        w_in_reg <= 0;
    end
    else begin
       n_in_reg <= n_in;
       w_in_reg <= w_in;
    end
end

reg [D_W-1:0] e_out_c;
reg [D_W-1:0] pe_out_c;
reg now_cycle;

always @* begin
    // Eastbound MUX
    case(e_bound_sel_memory[now_cycle][0])
        1'b0: begin // send from west input
            e_out_c <= w_in_reg;
        end
        1'b1: begin // send from north DDR input
            e_out_c <= n_in_reg;
        end
    endcase
    // PE-bound MUX
    case(pe_bound_sel_memory[now_cycle][0])
        1'b0: begin // send from west input
            pe_out_c <= w_in_reg;
        end
        1'b1: begin // send form north DDR input
            pe_out_c <= n_in_reg;
        end 
    endcase
end

// register output
reg [D_W-1:0] e_out_reg;
reg [D_W-1:0] e_out_pipe [PIPENUM-1:0];
reg [D_W-1:0] pe_out_reg;
reg [D_W-1:0] pe_out_pipe [PIPENUM-1:0];
always @(posedge clk) begin
    if (rst) begin
        e_out_reg <= 0;
        pe_out_reg <= 0;
        now_cycle <= 0;
    end else begin
        e_out_reg <= e_out_c;
        pe_out_reg <= pe_out_c;
        now_cycle = now_cycle + 1;

        if (now_cycle >= LENGTH) done = 1;
    end
end 

// pipeline outputs
genvar i;
generate for (i = 0; i < PIPENUM; i = i+1) begin
    if (i == 0) begin
        always@(posedge clk) begin
            if(rst) begin
                e_out_pipe[0] <= 0;
                pe_out_pipe[0] <= 0;
            end else begin
                e_out_pipe[0] <= e_out_reg;
                pe_out_pipe[0] <= pe_out_reg;
            end
        end
    end else begin
        always@(posedge clk) begin
            if(rst) begin
                e_out_pipe[i] <= 0;
                pe_out_pipe[i] <= 0;
            end else begin
                e_out_pipe[i]  <= e_out_pipe[i-1];
                pe_out_pipe[i] <= pe_out_pipe[i-1];
            end
        end
    end
end
endgenerate

assign e_out = e_out_pipe[PIPENUM-1];
assign pe_out = pe_out_pipe[PIPENUM-1];

endmodule
