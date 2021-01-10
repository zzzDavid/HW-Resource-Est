module pack #(
    LOAD_INS_LEN = 32 * 3,
    SAVE_INS_LEN = 32 * 4,
    DATAWIDTH = 512
)(
    input clk,
    input rst,
    input [LOAD_INS_LEN-1:0] load_ins_data,
    input [SAVE_INS_LEN-1:0] save_ins_data,
    input                    load_ins_ready,
    input                    save_ins_ready,
    input [DATAWIDTH-1:0]    data,
    input                    wr_ready,
    input                    wr_done,
    output                   ready,
    output [DATAWIDTH-1:0]   frame_data
);

    reg [DATAWIDTH-1:0] instruction;
    reg [DATAWIDTH-1:0] frame_data_r;

    reg done = 0;

    localparam INST = 2'b00;
    localparam DATA = 2'b01;
    localparam IDLE = 2'b10;
    localparam DONE = 2'b11;

    reg [1:0] cur_state_r, nxt_state_r;

    always @ ( * ) begin
        case(cur_state_r)
        INST: nxt_state_r <= DATA;
        DATA: nxt_state_r <= wr_ready ? DATA : IDLE;
        IDLE: nxt_state_r <= wr_done ? DONE : (wr_ready ? DATA : IDLE);
        DONE: nxt_state_r <= (load_ins_ready || save_ins_ready) ? INST : IDLE; 
        default:   nxt_state_r <= IDLE;
        endcase
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            cur_state_r <= IDLE;
        end
        else begin
            cur_state_r <= nxt_state_r;
        end
    end

    always@(posedge clk) begin
        if (rst) begin
            instruction <= 0;
        end else if (load_ins_ready) begin
            instruction[LOAD_INS_LEN-1:0] <= load_ins_data;
        end else if (save_ins_ready) begin
            instruction[SAVE_INS_LEN-1:0] <= save_ins_data;
        end
    end

    always@(posedge clk) begin
        if (rst) begin
            frame_data_r <= 0;
        end else if (cur_state_r == INST) begin
            frame_data_r <= instruction;
        end else if (cur_state_r == DATA) begin
            frame_data_r <= data;
        end else if (cur_state_r == DONE) begin
            done <= 1;
        end
    end

    assign ready = done;
    assign frame_data = frame_data_r;

endmodule