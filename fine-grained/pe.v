/**
*   dummy PE
*/

module PE #(
    parameter D_W = 64, // partial sum and weights data width
    parameter A_W = 16  // activation data width
) (
    input wire clk,
    input wire rst,
    input wire [D_W-1:0]  weight,
    input wire [D_W-1:0]  in_psum,
    input wire [A_W-1:0]  in_act,
    output wire [D_W-1:0] out_psum
);

(* dont_touch = "true" *) reg [D_W-1:0] w_reg;
(* dont_touch = "true" *) reg [D_W-1:0] psum_reg;
(* dont_touch = "true" *) reg [A_W-1:0] act_reg;
(* dont_touch = "true" *) reg [D_W-1:0] out_reg;

always @(posedge clk) begin
    if (rst) begin
        w_reg <= 0;
        psum_reg <= 0;
        act_reg <= 0;
    end else begin
        w_reg <= weight;
        psum_reg <= in_psum;
        act_reg <= in_act;
    end
end

always @(posedge clk) begin
    if (rst) begin
        out_reg <= 0;
    end else begin
        out_reg <= psum_reg;
    end
end

assign out_psum = out_reg;

endmodule