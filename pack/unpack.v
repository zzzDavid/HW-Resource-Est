module unpack #(
    LOAD_INS_LEN = 32 * 3,
    SAVE_INS_LEN = 32 * 4,
    DATAWIDTH = 512
)(
    input clk,
    input rst,
    input [DATAWIDTH-1:0]    frame_data,
    input                    wr_ready,
    input                    wr_done,
    output [DATAWIDTH-1:0]   inst_data,
    output                   inst_ready,
    output [DATAWIDTH-1:0]   data,
    output                   data_ready,
    output                   done 
);

    reg [DATAWIDTH-1:0] instruction;
    reg [DATAWIDTH-1:0] inst_data_r;
    reg [DATAWIDTH-1:0] data_r;
    reg inst_ready_r = 0;
    reg data_ready_r = 0;
    reg finished = 0;


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
        DONE: nxt_state_r <= wr_ready ? INST : IDLE; 
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
            inst_data_r <= 0;
            data_r <= 0;
        end else if (cur_state_r == INST) begin
            inst_data_r <= frame_data;
            inst_ready_r <= 1;
        end else if (cur_state_r == DATA) begin
            data_r <= frame_data;
        end else if (cur_state_r == DONE) begin
            data_ready_r <= 1;
            finished <= 1;
        end
    end

    assign inst_data = inst_data_r;
    assign data  = data_r;
    assign inst_ready = inst_ready_r;
    assign data_ready = data_ready_r;
    assign done = finished;

endmodule