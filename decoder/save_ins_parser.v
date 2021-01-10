module save_ins_parser#(
    parameter   BID_W       = 6,
    parameter   ADDR_W      = 12,  
    parameter   DDR_ADDR_W  = 32,
    parameter   LINE_SIZE_W = 12,
    parameter   ALL_SIZE_W  = 16,
    parameter   OFFSET_W    = 4,
    parameter   INS_LEN     = 32*4  //instruction length
    )(
    input               clk,        // scheduler clock
    input               rst,        // positive synchronous reset
    // instruction input
    input   [INS_LEN-1: 0]  ins_data,   // instruction
    input                   ins_valid,  // instruction valid
    output                  ins_ready,  // ready to receive instructions
    // instruction done
    output                  ins_done,       // instruction done state to scheduler
    input                   ins_done_ack,   // instruction done answer
    // write done / ready to start
    input                   wr_done,    // write done pulse from write module
    output                  start,      // trigger pulse
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

    reg                         start_r;
    //load
    reg     [BID_W      -1 : 0] reg_wr_bank_id_r;
    reg     [ADDR_W     -1 : 0] reg_wr_bank_addr_r;
    reg     [ADDR_W     -1 : 0] reg_wr_bank_step_r;
    reg     [OFFSET_W   -1 : 0] reg_wr_bank_offset_r;
    reg     [LINE_SIZE_W-1 : 0] reg_wr_line_size_r;
    reg     [ALL_SIZE_W -1 : 0] reg_wr_total_size_r;
    reg     [ALL_SIZE_W -1 : 0] reg_wr_ddr_step_r;
    reg     [DDR_ADDR_W -1 : 0] reg_wr_ddr_addr_r;

    localparam  HEAD_SAVE   = 4'b0010;

    localparam  STAT_IDLE   = 2'd0;
    localparam  STAT_WORK   = 2'd1;
    localparam  STAT_DONE   = 2'd2;

    reg [1          : 0] cur_stat_r, nxt_stat_r;

    always @ ( * ) begin
        case(cur_stat_r)
        STAT_IDLE: nxt_stat_r <= (ins_ready && ins_valid && (ins_data[31:28] == HEAD_SAVE)) ? STAT_WORK : STAT_IDLE;
        STAT_WORK: nxt_stat_r <= wr_done ? STAT_DONE : STAT_WORK;
        STAT_DONE: nxt_stat_r <= (ins_done && ins_done_ack) ? STAT_IDLE : STAT_DONE;
        default:   nxt_stat_r <= STAT_IDLE;
        endcase
    end

    always @ (posedge clk) begin
        if (rst) begin
            cur_stat_r <= STAT_IDLE;
        end
        else begin
            cur_stat_r <= nxt_stat_r;
        end
    end

//=============================================================================
// hand shake pulse generation
//=============================================================================

    // receive instruction
    reg     ins_ready_r;
    assign  ins_ready = ins_ready_r;
    always @ (posedge clk) begin
        if (rst) begin
            ins_ready_r <= 1'b1;
        end
        else if (ins_valid && ins_ready) begin
            ins_ready_r <= 1'b0;
        end
        else if (ins_done && ins_done_ack) begin
            ins_ready_r <= 1'b1;
        end
    end

    // generate start pulse
    always @ (posedge clk) begin
        if (rst) begin
            start_r <= 1'b0;
        end
        else if (ins_ready && ins_valid && ins_data[31:28] == HEAD_SAVE) begin
            start_r <= 1'b1;
        end
        else begin
            start_r <= 1'b0;
        end
    end

    // return instruction done
    reg     ins_done_r;
    assign  ins_done = ins_done_r;
    always @ (posedge clk) begin
        if (rst) begin
            ins_done_r <= 1'b0;
        end
        else if (ins_done_r && ins_done_ack) begin
            ins_done_r <= 1'b0;
        end
        else if (cur_stat_r == STAT_DONE) begin
            ins_done_r <= 1'b1;
        end
    end

//=============================================================================
// instruction decode
//=============================================================================
    always @(posedge clk) begin
        if(rst) begin
            reg_wr_bank_id_r    <= 0;
            reg_wr_bank_addr_r  <= 0;
            reg_wr_bank_step_r  <= 0;
            reg_wr_bank_offset_r<= 0;
            reg_wr_line_size_r  <= 0;
            reg_wr_total_size_r <= 0;
            reg_wr_ddr_step_r   <= 0;
            reg_wr_ddr_addr_r   <= 0;
        end
        else if(ins_ready && ins_valid && (ins_data[31:28] == HEAD_SAVE)) begin
            reg_wr_bank_id_r    <= ins_data[19 : 12];
            reg_wr_bank_addr_r  <= ins_data[11 :  0];
            reg_wr_bank_step_r  <= ins_data[83 : 72];
            reg_wr_bank_offset_r<= ins_data[71 : 68];
            reg_wr_line_size_r  <= ins_data[95 : 84];
            reg_wr_total_size_r <= ins_data[63 : 48];
            reg_wr_ddr_step_r   <= ins_data[47 : 32];
            reg_wr_ddr_addr_r   <= ins_data[127 : 96];
        end
    end

    assign start                = start_r;
    assign zero_ddr_step        = (reg_wr_ddr_step == 0);
    //load
    assign reg_wr_bank_id       = reg_wr_bank_id_r;
    assign reg_wr_bank_addr     = reg_wr_bank_addr_r;
    assign reg_wr_bank_step     = reg_wr_bank_step_r;
    assign reg_wr_bank_offset   = reg_wr_bank_offset_r; 
    assign reg_wr_line_size     = reg_wr_line_size_r;
    assign reg_wr_total_size    = reg_wr_total_size_r;
    assign reg_wr_ddr_step      = reg_wr_ddr_step_r;
    assign reg_wr_ddr_addr      = reg_wr_ddr_addr_r;

endmodule // save_ins_parser