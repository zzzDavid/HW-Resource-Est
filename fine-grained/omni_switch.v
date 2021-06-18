module omni_switch #(
    parameter D_W = 64, // partial sum and weights data width
    parameter A_W = 16, // activation data width
    parameter ADDR_W = 14 // address width
)(
  input  wire clk,
  input  wire rst, 
  input  wire [D_W-1:0] in_psum_top, // partial sum from top PE
  input  wire [D_W-1:0] in_psum_btm, // partial sum from bottom PE
  input  wire [D_W-1:0] weight,      // weights
  output wire [D_W-1:0] out_psum_top,// partial sum to top PE
  output wire [D_W-1:0] out_psum_btm,// partial sum to bottom PE
  input  wire [A_W-1:0] in_act_lft,  // input activation from left PE
  input  wire [A_W-1:0] in_act_rht,  // input activation from right PE
  output wire [A_W-1:0] out_act_lft, // output activation to left PE
  output wire [A_W-1:0] out_act_rht, // output activation to right PE
  output wire [ADDR_W-1:0]  weight_addr,  // weight address in pod memory
  output wire [D_W-1:0]     out_pod_data, // write to pod data
  output wire [ADDR_W-1:0]  out_pod_addr  // write to pod addr
);

// selection register
(* dont_touch = "true" *) reg ps_d_sel;
(* dont_touch = "true" *) reg a_d_sel;

// input output register
(* dont_touch = "true" *) reg [D_W-1:0] in_psum_reg;
(* dont_touch = "true" *) reg [A_W-1:0] in_act_reg;
(* dont_touch = "true" *) reg [D_W-1:0] out_psum_reg;
(* dont_touch = "true" *) reg [D_W-1:0] out_act_reg;

always @* begin
    // Southbound MUX
    case(ps_d_sel)
        1'b0: begin
            in_psum_reg <= in_psum_top;
        end
        1'b1: begin
            in_psum_reg <= in_psum_btm;
        end
    endcase
    // Eastbound MUX
    case(a_d_sel)
        1'b0: begin
            in_act_reg <= in_act_lft;
        end
        1'b1: begin
            in_act_reg <= in_act_rht;
        end
    endcase
end

wire [D_W-1:0] psum_wire;
wire [A_W-1:0] act_wire;
wire [D_W-1:0] out_psum_wire;

assign psum_wire = in_psum_reg;
assign act_wire  = in_act_reg;

(* dont_touch = "true" *) PE #(
    .D_W(D_W),
    .ADDR_W(ADDR_W),
    .A_W(A_W)
) PE_inst(
    .clk(clk),
    .rst(rst),
    .weight(weight),
    .weight_addr(weight_addr),
    .out_pod_data(out_pod_data),
    .out_pod_addr(out_pod_addr),
    .in_psum(psum_wire),
    .in_act(act_wire),
    .out_psum(out_psum_wire)
);

always @(posedge clk) begin
    if (rst) begin
        out_psum_reg <= 0;
        out_act_reg <= 0;
    end else begin
        out_act_reg <= in_act_reg;
        out_psum_reg <= out_psum_wire;
    end
end

// output control
(* dont_touch = "true" *) reg [D_W-1:0] out_psum_btm_reg;
(* dont_touch = "true" *) reg [D_W-1:0] out_psum_top_reg;
(* dont_touch = "true" *) reg [A_W-1:0] out_act_rht_reg;
(* dont_touch = "true" *) reg [A_W-1:0] out_act_lft_reg;

always @* begin
    if (rst) begin
        out_psum_btm_reg <= 0;
        out_psum_top_reg <= 0;
        out_act_rht_reg  <= 0;
        out_act_lft_reg  <= 0;
    end 
    else begin
        // Southbound MUX
        case (ps_d_sel)
            1'b0: begin
                out_psum_top_reg <= out_psum_reg;
            end
            1'b1: begin
                out_psum_btm_reg <= out_psum_reg;
            end
        endcase
        // EAST bound MUX
        case (a_d_sel)
            1'b0: begin
                out_act_lft_reg <= out_act_reg; 
            end
            1'b1: begin
                out_act_rht_reg <= out_act_reg;
            end
        endcase
    end
end

assign out_psum_top = out_psum_top_reg;
assign out_psum_btm = out_psum_btm_reg;
assign out_act_lft  = out_act_lft_reg;
assign out_act_rht  = out_act_rht_reg; 

endmodule