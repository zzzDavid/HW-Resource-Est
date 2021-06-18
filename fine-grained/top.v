module top #(
    parameter D_W = 64,         // level-2 NoC data width
    parameter A_W = 16,          // activation data width
    parameter ADDR_W = 14,      // addr width
    parameter OFFCHIP_DW = 512, // level-1 NoC data width
    parameter M_W=18,           // BRAM data width
    parameter PIPENUM = 12      // pipeline stages
)(
    input wire clk,
    input wire rst,
    input wire ce,
    input  wire [OFFCHIP_DW*4-1:0] DDR_rdata_bus,
    output wire [ADDR_W*4-1:0]     DDR_raddr_bus,
    output wire [ADDR_W*4-1:0]     DDR_waddr_bus,
    output wire [OFFCHIP_DW*4-1:0] DDR_wdata_bus
);

(* dont_touch = "true" *) reg [ADDR_W-1:0]     membus_raddr_pipe_reg [3:0][PIPENUM-1:0];
(* dont_touch = "true" *) reg [OFFCHIP_DW-1:0] membus_rdata_pipe_reg [3:0][PIPENUM-1:0];
(* dont_touch = "true" *) reg [ADDR_W-1:0]     membus_waddr_pipe_reg [3:0][PIPENUM-1:0];
(* dont_touch = "true" *) reg [OFFCHIP_DW-1:0] membus_wdata_pipe_reg [3:0][PIPENUM-1:0];
wire [ADDR_W-1:0]     membus_raddr_pipe_net [3:0][1:0];
wire [OFFCHIP_DW-1:0] membus_rdata_pipe_net [3:0][1:0];
wire [ADDR_W-1:0]     membus_waddr_pipe_net [3:0][1:0];
wire [OFFCHIP_DW-1:0] membus_wdata_pipe_net [3:0][1:0];

(* dont_touch = "true" *) reg [A_W-1:0]        actv_pipe_reg [15:0][1:0][PIPENUM-1:0];
(* dont_touch = "true" *) reg [D_W-1:0]        psum_pipe_reg [15:0][1:0][PIPENUM-1:0];
wire [A_W-1:0] actv_pipe_net [15:0][1:0][1:0];
wire [D_W-1:0] psum_pipe_net [15:0][1:0][1:0];

// connections between pod memory and PEs
wire [ADDR_W-1:0] pod_w_addr_net [3:0][3:0];
wire [D_W-1:0]    pod_w_data_net[3:0][3:0];
wire [ADDR_W-1:0] pod_r_addr_net [3:0][3:0];
wire [D_W-1:0]    pod_r_data_net [3:0][3:0];

// connections between pod memories
wire [ADDR_W-1:0]     mem_bus_w_addr [3:0];
wire [OFFCHIP_DW-1:0] mem_bus_w_data [3:0];
wire [ADDR_W-1:0]     mem_bus_r_addr [3:0];
wire [OFFCHIP_DW-1:0] mem_bus_r_data [3:0];

genvar i, j, p, io;
generate for (i = 0; i < 4; i = i + 1) begin
    (* dont_touch = "true" *)
    pod_memory #(
        .D_W(D_W), .ADDR_W(ADDR_W), .OFFCHIP_DW(OFFCHIP_DW), .M_W(M_W)
    ) pod_memory_inst(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .w_addr_0(pod_w_addr_net[i][0]),
        .w_data_0(pod_w_data_net[i][0]),
        .r_addr_0(pod_r_addr_net[i][0]),
        .r_data_0(pod_r_data_net[i][0]),
        .w_addr_1(pod_w_addr_net[i][1]),
        .w_data_1(pod_w_data_net[i][1]),
        .r_addr_1(pod_r_addr_net[i][1]),
        .r_data_1(pod_r_data_net[i][1]),
        .w_addr_2(pod_w_addr_net[i][2]),
        .w_data_2(pod_w_data_net[i][2]),
        .r_addr_2(pod_r_addr_net[i][2]),
        .r_data_2(pod_r_data_net[i][2]),
        .w_addr_3(pod_w_addr_net[i][3]),
        .w_data_3(pod_w_data_net[i][3]),
        .r_addr_3(pod_r_addr_net[i][3]),
        .r_data_3(pod_r_data_net[i][3]),
        .w_addr_offchip_0(membus_waddr_pipe_net[i][0]),
        .w_data_offchip_0(membus_wdata_pipe_net[i][0]),
        .r_addr_offchip_0(membus_raddr_pipe_net[i][0]),
        .r_data_offchip_0(membus_rdata_pipe_net[i][1]),
        .w_addr_offchip_1(membus_waddr_pipe_net[(i+1)%4][1]),
        .w_data_offchip_1(membus_wdata_pipe_net[(i+1)%4][1]),
        .r_addr_offchip_1(membus_raddr_pipe_net[(i+1)%4][1]),
        .r_data_offchip_1(membus_rdata_pipe_net[(i+1)%4][0]),
        .w_addr_offchip_2(DDR_waddr_bus[i*ADDR_W + ADDR_W-1 : i*ADDR_W]),
        .w_data_offchip_2(DDR_wdata_bus[i*OFFCHIP_DW + OFFCHIP_DW-1 : i*OFFCHIP_DW]),
        .r_addr_offchip_2(DDR_raddr_bus[i*ADDR_W + ADDR_W-1 : i*ADDR_W]),
        .r_data_offchip_2(DDR_rdata_bus[i*OFFCHIP_DW + OFFCHIP_DW-1 : i*OFFCHIP_DW])
    );

    assign membus_waddr_pipe_net[i][0] = membus_waddr_pipe_reg[i][0];
    assign membus_waddr_pipe_net[i][1] = membus_waddr_pipe_reg[i][PIPENUM-1];
    assign membus_wdata_pipe_net[i][0] = membus_wdata_pipe_reg[i][0];
    assign membus_wdata_pipe_net[i][1] = membus_wdata_pipe_reg[i][PIPENUM-1];
    assign membus_raddr_pipe_net[i][0] = membus_raddr_pipe_reg[i][0];
    assign membus_raddr_pipe_net[i][1] = membus_raddr_pipe_reg[i][PIPENUM-1];
    assign membus_rdata_pipe_net[i][0] = membus_rdata_pipe_reg[i][0];
    assign membus_rdata_pipe_net[i][1] = membus_rdata_pipe_reg[i][PIPENUM-1];


    // membus pipeline
    for (p = 0; p < PIPENUM-1; p = p + 1) begin
        always @* begin
            if (rst) begin
                membus_waddr_pipe_reg[i][p] <= 0;
                membus_wdata_pipe_reg[i][p] <= 0;
                membus_raddr_pipe_reg[i][p] <= 0;
                membus_rdata_pipe_reg[i][p] <= 0;
            end else begin
                membus_waddr_pipe_reg[i][p+1] <= membus_waddr_pipe_reg[i][p];
                membus_wdata_pipe_reg[i][p+1] <= membus_wdata_pipe_reg[i][p];
                membus_raddr_pipe_reg[i][p+1] <= membus_raddr_pipe_reg[i][p];
                membus_rdata_pipe_reg[i][p+1] <= membus_rdata_pipe_reg[i][p];
            end
       end
    end 


    for (j = 0; j < 4; j = j + 1) begin
        (* dont_touch = "true" *)
        omni_switch #(
            .D_W(D_W), .A_W(A_W), .ADDR_W(ADDR_W)
        ) PE_inst(
            .clk(clk),
            .rst(rst),
            .in_psum_top(psum_pipe_net[(i*4+j+1)%16][0][1]),
            .in_psum_btm(psum_pipe_net[i*4+j][0][1]),
            .weight(pod_r_data_net[i][j]),
            .out_psum_top(psum_pipe_net[(i*4+j+1)%16][1][0]),
            .out_psum_btm(psum_pipe_net[i*4+j][1][0]),
            .in_act_lft(actv_pipe_net[i*4+j][0][1]),
            .in_act_rht(actv_pipe_net[(i*4+j+1)%16][0][1]),
            .out_act_lft(actv_pipe_net[i*4+j][1][0]),
            .out_act_rht(actv_pipe_net[(i*4+j+1)%16][1][0]),
            .weight_addr(pod_r_addr_net[i][j]),
            .out_pod_data(pod_w_data_net[i][j]),
            .out_pod_addr(pod_w_addr_net[i][j])
        );

        for (io = 0; io < 2; io = io + 1) begin
            assign psum_pipe_net[i*4+j][io][0] = psum_pipe_reg[i*4+j][io][0];
            assign actv_pipe_net[i*4+j][io][1] = actv_pipe_reg[i*4+j][io][PIPENUM-1];
        end

        // level-2 ring bus pipeline
        for (p = 0; p < PIPENUM-1; p = p + 1) begin
            for (io = 0; io < 2; io = io + 1) begin
                always @* begin
                    if (rst) begin
                        psum_pipe_reg[i*4+j][io][p] <= 0;
                        actv_pipe_reg[i*4+j][io][p] <= 0;
                    end else begin
                        psum_pipe_reg[i*4+j][io][p+1] <= psum_pipe_reg[i*4+j][io][p];
                        actv_pipe_reg[i*4+j][io][p+1] <= actv_pipe_reg[i*4+j][io][p];
                    end
                end
            end
        end 

    end
end
endgenerate

endmodule