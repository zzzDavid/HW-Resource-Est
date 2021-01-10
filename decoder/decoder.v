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
    parameter   INST_FIFO_SIZE = 10,
    parameter   DATA_WIDTH  = 512
)(
    input wire clk,
    input wire rst,
    input [DATA_WIDTH-1:0]   ethernet_inst,
    input [DATA_WIDTH-1:0]   core0_inst,
    input [DATA_WIDTH-1:0]   core1_inst,
    input [DATA_WIDTH-1:0]   core2_inst,
    input [DATA_WIDTH-1:0]   core3_inst,    
    // hand shake signals that should be generated internally according to each instruction source
    // but I'm going to leave them here for now because this does not significantly affect
    // hardware resource estimation
    input                    load_ins_valid,
    input                    load_ins_ready,
    output                   load_ins_done,
    input                    load_ins_done_ack,
    input                    load_wr_done,
    output                   load_start,
    input                    save_ins_valid,
    output                   save_ins_ready,
    output                   ins_done,
    input                    ins_done_ack,
    input                    save_wr_done,
    output                   save_start,
    output                   zero_ddr_step,
    // registered output
    output  [IWB_SEL_W  -1 : 0] reg_rd_iwb_id,
    output  [BID_W      -1 : 0] reg_rd_bank_id,
    output  [MAX_ADDR_W -1 : 0] reg_rd_bank_addr,
    output  [LINE_SIZE_W-1 : 0] reg_rd_line_size,
    output  [ALL_SIZE_W -1 : 0] reg_rd_total_size,
    output                      reg_zero_fill,
    output  [DDR_ADDR_W -1 : 0] reg_rd_ddr_add,
    output  [BID_W      -1 : 0] reg_wr_bank_id,
    output  [ADDR_W     -1 : 0] reg_wr_bank_addr,
    output  [ADDR_W     -1 : 0] reg_wr_bank_step,
    output  [OFFSET_W   -1 : 0] reg_wr_bank_offset,
    output  [LINE_SIZE_W-1 : 0] reg_wr_line_size,
    output  [ALL_SIZE_W -1 : 0] reg_wr_total_size,
    output  [ALL_SIZE_W -1 : 0] reg_wr_ddr_step,
    output  [DDR_ADDR_W -1 : 0] reg_wr_ddr_addr,
    // control signals
    output                      B0,
    output  [1:0]               B1,
    output  [1:0]               B2,
    output  [1:0]               B3,
    output                      F0,
    output  [1:0]               F1,
    output                      S0,
    output                      hyperconnect
);

    (* dont_touch = "true" *) reg [DATA_WIDTH-1:0] inst_fifo [INST_FIFO_SIZE-1:0];
    (* dont_touch = "true" *) reg [DATA_WIDTH-1:0] instruction;

    // registers for the controllers
    (* dont_touch = "true" *) reg       B0_r;
    (* dont_touch = "true" *) reg [1:0] B1_r;
    (* dont_touch = "true" *) reg [1:0] B2_r;
    (* dont_touch = "true" *) reg [1:0] B3_r;
    (* dont_touch = "true" *) reg       F0_r;
    (* dont_touch = "true" *) reg [1:0] F1_r;
    (* dont_touch = "true" *) reg       S0_r;
    (* dont_touch = "true" *) reg       hyperconnect_r;

    // instruction fifo
    genvar i;
    generate for (i = 0; i < INST_FIFO_SIZE; i=i+1) begin
        if (i == 0) begin
            always@(posedge clk) begin
                if (rst) begin
                    inst_fifo[0] <= 0;
                end else begin
                    inst_fifo[0] <= instruction;
                end
            end
        end else begin
            always@(posedge clk) begin
                if(rst) begin
                    inst_fifo[i] <= 0;
                end else begin
                    inst_fifo[i] <= inst_fifo[i-1];
                end
            end
        end
    end
    endgenerate

    // poll instruction sources
    reg [2:0] counter = 0;
    always @ ( * ) begin
        case(counter)
        3'b000: instruction <= core0_inst;
        3'b001: instruction <= core1_inst;
        3'b010: instruction <= core2_inst;
        3'b011: instruction <= core3_inst;
        3'b100: instruction <= ethernet_inst;
        default: counter <= 0;
        endcase
    end
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end else if (counter == 3'b100) begin
            counter <=0;
        end else begin
            counter <= counter + 1;
        end
    end

    // instruction bank
    reg  [DATA_WIDTH-1:0]  inst_bank [3:0];
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
            inst_bank[0] <= 0;
            inst_bank[1] <= 0;
            inst_bank[2] <= 0;
            inst_bank[3] <= 0;
        end else begin
            inst_bank[3] <= inst_fifo[INST_FIFO_SIZE-1];
            inst_bank[2] <= inst_bank[3];
            inst_bank[1] <= inst_bank[2];
            inst_bank[0] <= inst_bank[1];
        end
    end    
    assign bank_id_3    = inst_bank[3][19:12];
    assign bank_addr_3  = inst_bank[3][11:0];
    assign line_size_3  = inst_bank[3][61:50];
    assign total_size_3 = inst_bank[3][49:34];
    assign ddr_addr_3   = inst_bank[3][95:64];
    assign bank_id_2    = inst_bank[2][19:12];
    assign bank_addr_2  = inst_bank[2][11:0];
    assign line_size_2  = inst_bank[2][61:50];
    assign total_size_2 = inst_bank[2][49:34];
    assign ddr_addr_2   = inst_bank[2][95:64];
    assign bank_id_1    = inst_bank[1][19:12];
    assign bank_addr_1  = inst_bank[1][11:0];
    assign line_size_1  = inst_bank[1][61:50];
    assign total_size_1 = inst_bank[1][49:34];
    assign ddr_addr_1   = inst_bank[1][95:64];
    assign bank_id_0    = inst_bank[0][19:12];
    assign bank_addr_0  = inst_bank[0][11:0];
    assign line_size_0  = inst_bank[0][61:50];
    assign total_size_0 = inst_bank[0][49:34];
    assign ddr_addr_0   = inst_bank[0][95:64];

    always@(posedge clk) begin
        if (bank_id_0 == bank_id_1 == bank_id_2 == bank_id_3 &&
            bank_addr_0 == bank_addr_1 == bank_addr_2 == bank_addr_3 &&
            line_size_0 == line_size_1 == line_size_2 == line_size_3 &&
            total_size_0 == total_size_1 == total_size_2 == total_size_3 &&
            ddr_addr_0 == ddr_addr_1 == ddr_addr_2 == ddr_addr_3) begin
            // flush load instruction bank
            inst_bank[0] <= 0;
            inst_bank[1] <= 0;
            inst_bank[2] <= 0;
        end
    end

    // decide LOAD or SAVE
    reg [LOAD_INS_LEN-1:0] load_ins_data;
    reg [SAVE_INS_LEN-1:0] save_ins_data;
    always@(posedge clk) begin
        if (rst) begin
            load_ins_data <= 0;
            save_ins_data <= 0;
        end else begin
            if (inst_bank[3][SAVE_INS_LEN-1:SAVE_INS_LEN-LOAD_INS_LEN] == 0) begin
                load_ins_data <= inst_bank[3][LOAD_INS_LEN-1:0];
            end else begin
                save_ins_data <= inst_bank[3][SAVE_INS_LEN-1:0];
            end
        end
    end

    // decode
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
        .ins_data(load_ins_data),
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


    assign B0 =  B0_r;
    assign B1 =  B1_r;
    assign B2 =  B2_r;
    assign B3 =  B3_r;
    assign F0 =  F0_r;
    assign F1 =  F1_r;
    assign S0 =  S0_r;
    assign hyperconnect = hyperconnect_r;

endmodule