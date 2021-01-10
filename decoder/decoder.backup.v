module decoder #(
    parameter   BID_W       = 6,
    parameter   ADDR_W      = 12,  
    parameter   DDR_ADDR_W  = 32,
    parameter   LINE_SIZE_W = 12,
    parameter   ALL_SIZE_W  = 16,
    parameter   OFFSET_W    = 4,
    parameter   LOAD_INS_LEN     = 32 * 3, // LOAD instruction length
    parameter   SAVE_INS_LEN     = 32*4,   //SAVE instruction length
    parameter   IWB_SEL_W   = 2,
    parameter   MAX_ADDR_W  = 12,
    parameter   INST_FIFO_SIZE = 10
)(
    input wire clk,
    input wire rst,
    // instruction input
    input [LOAD_INS_LEN-1:0] load_ins_data,
    input                    load_ins_valid,
    input                    load_ins_ready,
    // instruction done
    output                   load_ins_done,
    input                    load_ins_done_ack,
    // write done / ready to start
    input                     load_wr_done,
    output                    load_start,
    // register output
    output  [IWB_SEL_W  -1 : 0] reg_rd_iwb_id,
    output  [BID_W      -1 : 0] reg_rd_bank_id,
    output  [MAX_ADDR_W -1 : 0] reg_rd_bank_addr,
    output  [LINE_SIZE_W-1 : 0] reg_rd_line_size,
    output  [ALL_SIZE_W -1 : 0] reg_rd_total_size,
    output                      reg_zero_fill,
    output  [DDR_ADDR_W -1 : 0] reg_rd_ddr_add,
    // instruction input
    input   [SAVE_INS_LEN-1: 0]  save_ins_data,   // instruction
    input                   save_ins_valid,  // instruction valid
    output                  save_ins_ready,  // ready to receive instructions
    // instruction done
    output                  ins_done,       // instruction done state to scheduler
    input                   ins_done_ack,   // instruction done answer
    // write done / ready to start
    input                   save_wr_done,    // write done pulse from write module
    output                  save_start,      // trigger pulse
    output                  zero_ddr_step,
    //register output
    output  [BID_W      -1 : 0] reg_wr_bank_id,
    output  [ADDR_W     -1 : 0] reg_wr_bank_addr,
    output  [ADDR_W     -1 : 0] reg_wr_bank_step,
    output  [OFFSET_W   -1 : 0] reg_wr_bank_offset,
    output  [LINE_SIZE_W-1 : 0] reg_wr_line_size,
    output  [ALL_SIZE_W -1 : 0] reg_wr_total_size,
    output  [ALL_SIZE_W -1 : 0] reg_wr_ddr_step,
    output  [DDR_ADDR_W -1 : 0] reg_wr_ddr_addr
);

    reg  [LOAD_INS_LEN-1:0]  load_inst_bank [3:0];
    wire [7:0]  bank_id_3;
    wire [11:0] bank_addr_3;
    wire [11:0] line_size_3;
    wire [15:0] total_size_3;
    wire [31:0] ddr_addr_3;
    wire [7:0]  bank_id_2;
    wire [11:0] bank_addr_2;
    wire [11:0] line_size_2;
    wire [15:0] total_size_2;
    wire [31:0] ddr_addr_2;
    wire [7:0]  bank_id_1;
    wire [11:0] bank_addr_1;
    wire [11:0] line_size_1;
    wire [15:0] total_size_1;
    wire [31:0] ddr_addr_1;
    wire [7:0]  bank_id_0;
    wire [11:0] bank_addr_0;
    wire [11:0] line_size_0;
    wire [15:0] total_size_0;
    wire [31:0] ddr_addr_0; 
    
    always @(posedge clk) begin
        if (rst) begin
            load_inst_bank[0] <= 0;
            load_inst_bank[1] <= 0;
            load_inst_bank[2] <= 0;
            load_inst_bank[3] <= 0;
        end else begin
            load_inst_bank[3] <= load_ins_data;
            load_inst_bank[2] <= load_inst_bank[3];
            load_inst_bank[1] <= load_inst_bank[2];
            load_inst_bank[0] <= load_inst_bank[1];
        end
    end

    
    assign bank_id_3    = load_inst_bank[3][19:12];
    assign bank_addr_3  = load_inst_bank[3][11:0];
    assign line_size_3  = load_inst_bank[3][61:50];
    assign total_size_3 = load_inst_bank[3][49:34];
    assign ddr_addr_3   = load_inst_bank[3][95:64];
    assign bank_id_2    = load_inst_bank[2][19:12];
    assign bank_addr_2  = load_inst_bank[2][11:0];
    assign line_size_2  = load_inst_bank[2][61:50];
    assign total_size_2 = load_inst_bank[2][49:34];
    assign ddr_addr_2   = load_inst_bank[2][95:64];
    assign bank_id_1    = load_inst_bank[1][19:12];
    assign bank_addr_1  = load_inst_bank[1][11:0];
    assign line_size_1  = load_inst_bank[1][61:50];
    assign total_size_1 = load_inst_bank[1][49:34];
    assign ddr_addr_1   = load_inst_bank[1][95:64];
    assign bank_id_0    = load_inst_bank[0][19:12];
    assign bank_addr_0  = load_inst_bank[0][11:0];
    assign line_size_0  = load_inst_bank[0][61:50];
    assign total_size_0 = load_inst_bank[0][49:34];
    assign ddr_addr_0   = load_inst_bank[0][95:64];

    always@(posedge clk) begin
        if (bank_id_0 == bank_id_1 == bank_id_2 == bank_id_3 &&
            bank_addr_0 == bank_addr_1 == bank_addr_2 == bank_addr_3 &&
            line_size_0 == line_size_1 == line_size_2 == line_size_3 &&
            total_size_0 == total_size_1 == total_size_2 == total_size_3 &&
            ddr_addr_0 == ddr_addr_1 == ddr_addr_2 == ddr_addr_3) begin
            // flush load instruction bank
            load_inst_bank[0] <= 0;
            load_inst_bank[1] <= 0;
            load_inst_bank[2] <= 0;
        end
    end
        

    (* dont_touch = "true" *) save_ins_parser #() save_ins_parser_inst(
        .clk(clk),
        .rst(rst),
        .ins_data(save_ins_data),
        .ins_valid(save_ins_valid),
        .ins_ready(save_ins_ready),
        .ins_done(save_ins_done),
        .ins_done_ack(save_ins_done_ack),
        .wr_done(save_wr_done),
        .start(save_start),
        .zero_ddr_step(zero_ddr_step),
        .reg_wr_bank_id(reg_wr_bank_id),
        .reg_wr_bank_addr(reg_wr_bank_addr),
        .reg_wr_bank_step(reg_wr_bank_step),
        .reg_wr_bank_offset(reg_wr_bank_offset),
        .reg_wr_line_size(reg_wr_line_size),
        .reg_wr_total_size(reg_wr_total_size),
        .reg_wr_ddr_step(reg_wr_ddr_step),
        .reg_wr_ddr_addr(reg_wr_ddr_addr)
    );

    (* dont_touch = "true" *) load_ins_parser #() load_ins_parser_inst(
        .clk(clk),
        .rst(rst),
        .ins_data(load_inst_bank[3]),
        .ins_valid(load_ins_valid),
        .ins_ready(load_ins_ready),
        .ins_done(load_ins_done),
        .ins_done_ack(load_ins_done_ack),
        .wr_done(load_wr_done),
        .start(load_start),
        .reg_rd_iwb_id(reg_rd_iwb_id),
        .reg_rd_bank_id(reg_rd_bank_id),
        .reg_rd_bank_addr(reg_rd_bank_addr),
        .reg_rd_line_size(reg_rd_line_size),
        .reg_rd_total_size(reg_rd_total_size),
        .reg_zero_fill(reg_zero_fill),
        .reg_rd_ddr_addr(reg_rd_ddr_addr)
    );

endmodule