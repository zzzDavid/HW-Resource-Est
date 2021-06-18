/**
*   handshake signals are ommited
#   data pack/unpack are ommited
*/

module pod_memory #(
    parameter D_W = 64,         // level-2 NoC data width
    parameter ADDR_W = 14,      // addr width
    parameter OFFCHIP_DW = 512, // level-1 NoC data width
    parameter M_W=18            // BRAM data width
)(
    input wire clk,
    input wire rst,
    input wire ce,
    // weight ports, 2nd level NoC
    input   wire [ADDR_W-1:0] w_addr_0,
    input   wire [D_W-1:0]    w_data_0,
    input   wire [ADDR_W-1:0] r_addr_0,
    output  wire [D_W-1:0]    r_data_0,
    input   wire [ADDR_W-1:0] w_addr_1,
    input   wire [D_W-1:0]    w_data_1,
    input   wire [ADDR_W-1:0] r_addr_1,
    output  wire [D_W-1:0]    r_data_1,
    input   wire [ADDR_W-1:0] w_addr_2,
    input   wire [D_W-1:0]    w_data_2,
    input   wire [ADDR_W-1:0] r_addr_2,
    output  wire [D_W-1:0]    r_data_2,
    input   wire [ADDR_W-1:0] w_addr_3,
    input   wire [D_W-1:0]    w_data_3,
    input   wire [ADDR_W-1:0] r_addr_3,
    output  wire [D_W-1:0]    r_data_3,
    // offchip ports, 1st level NoC
    // master
    output  wire [ADDR_W-1:0]     w_addr_offchip_0,
    output  wire [OFFCHIP_DW-1:0] w_data_offchip_0,
    output  wire [ADDR_W-1:0]     r_addr_offchip_0,
    input   wire [OFFCHIP_DW-1:0] r_data_offchip_0,
    
    // slave
    input   wire [ADDR_W-1:0]     w_addr_offchip_1,
    input   wire [OFFCHIP_DW-1:0] w_data_offchip_1,
    input   wire [ADDR_W-1:0]     r_addr_offchip_1,
    output  wire [OFFCHIP_DW-1:0] r_data_offchip_1,
    
    // master
    output  wire [ADDR_W-1:0]     w_addr_offchip_2,
    output  wire [OFFCHIP_DW-1:0] w_data_offchip_2,
    output  wire [ADDR_W-1:0]     r_addr_offchip_2,
    input   wire [OFFCHIP_DW-1:0] r_data_offchip_2
);

// bus arbiter : an FSM
(* dont_touch="true" *) reg [2:0] select;
always @* begin
    if (rst) begin
        select <= 0; 
    end else begin
        case (select)
            3'b 110: begin
                select <= 0;
            end 
            default: begin
                select <= select + 1;
            end
        endcase
    end
end

// input buffer
(* dont_touch="true" *) reg [ADDR_W-1:0]        r_addr_reg;
(* dont_touch="true" *) reg [OFFCHIP_DW-1:0]    w_data_reg;
(* dont_touch="true" *) reg [ADDR_W-1:0]        w_addr_reg; 
(* dont_touch="true" *) reg [OFFCHIP_DW-1:0]    r_data_reg;
always @* begin
    if (rst) begin
        r_addr_reg <= 0;
        w_addr_reg <= 0;
        w_addr_reg <= 0;
        r_data_reg <= 0;
    end else begin
    case (select)
        3'b000: begin // level-1 NOC 0
            r_data_reg <= r_data_offchip_0;
        end
        3'b001: begin // level-1 NOC 1
            r_addr_reg <=  r_addr_offchip_1;
            w_data_reg <=  w_data_offchip_1;
            w_addr_reg <=  w_addr_offchip_1;
        end
        3'b010: begin // level-1 NOC 2
            r_data_reg <= r_data_offchip_1;
        end
        3'b011: begin // level-2 NOC 0
            r_addr_reg <=  r_addr_0;
            w_data_reg <=  w_data_0;
            w_addr_reg <=  w_addr_0;
        end
        3'b100: begin // level-2 NOC 1
            r_addr_reg <=  r_addr_0;
            w_data_reg <=  w_data_0;
            w_addr_reg <=  w_addr_0;
        end
        3'b101: begin // level-2 NOC 2
            r_addr_reg <=  r_addr_0;
            w_data_reg <=  w_data_0;
            w_addr_reg <=  w_addr_0;
        end
        3'b110: begin // level-2 NOC 3
            r_addr_reg <=  r_addr_0;
            w_data_reg <=  w_data_0;
            w_addr_reg <=  w_addr_0;
        end
        default: begin // default
            r_addr_reg <=  r_addr_reg;
            w_data_reg <=  w_data_reg;
            w_addr_reg <=  w_addr_reg;
        end
    endcase
    end
end


// Block RAMs
wire [M_W-1:0] casc_data_b1;
wire [M_W-1:0] casc_data_b2;
wire [M_W-1:0] casc_data_b3;
wire [M_W-1:0] rd_data_b3;
wire [47:0] p[0:9];
wire [47:0] p_out[0:1];
wire [M_W-1:0] dsp_a0;

(* dont_touch="true" *)
RAMB18E2#(
        .DOA_REG(1), .DOB_REG(1),
        .CASCADE_ORDER_A("FIRST"), .CASCADE_ORDER_B("NONE"),
        .CLOCK_DOMAINS("COMMON"),
        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),

        .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
        .READ_WIDTH_A(18), .READ_WIDTH_B(18))
    bram_inst_rdc0(
        .ADDRARDADDR(b1_rd_addr),
        .ADDRBWRADDR(b1_wr_addr),
        .ADDRENA(1'b1),
        .ADDRENB(1'b1),
        .WEA({2{1'b0}}),
        .WEBWE({4{b1_wr_en}}),

        // horizontal links
        .CASDOUTA(casc_data_b1[15:0]),
        .CASDOUTPA(casc_data_b1[17:16]),
        .DINBDIN(w_data_reg[15:0]),
        .DINPBDINP(2'b00),
        .CASDIMUXA(1'b0),
        .CASDIMUXB(1'b0),
        .DOUTADOUT(dsp_a0[15:0]),
        .DOUTPADOUTP(dsp_a0[17:16]),

        // clocking, reset, and enable control
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),

        .ENARDEN(ce),
        .ENBWREN(ce),
        .REGCEAREGCE(ce),
        .REGCEB(ce),

        .RSTRAMARSTRAM(rst),
        .RSTRAMB(rst),
        .RSTREGARSTREG(rst),
        .RSTREGB(rst)
    );

(* dont_touch="true" *)
    RAMB18E2#(
        .DOA_REG(1), .DOB_REG(1),
        .CASCADE_ORDER_A("MIDDLE"), .CASCADE_ORDER_B("FIRST"),
        .CLOCK_DOMAINS("COMMON"),

        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
        .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
        .READ_WIDTH_A(18), .READ_WIDTH_B(18))
    bram_inst_rdc1(
        .ADDRARDADDR(b2_wr_addr),
        .ADDRBWRADDR(b2_rd_addr),
        .ADDRENA(1'b1),
        .ADDRENB(1'b1),
        .WEA({2{b2_wr_en}}),
        .WEBWE({4{1'b0}}),

        // horizontal links
        .CASDOUTB(casc_data_b2[15:0]),
        .CASDOUTPB(casc_data_b2[17:16]),
        .CASDINA(casc_data_b1[15:0]),
        .CASDINPA(casc_data_b1[17:16]),
        .CASDIMUXB(1'b0),
        .CASDIMUXA(1'b1),
        .DOUTBDOUT(),
        .DOUTPBDOUTP(),

        // clocking, reset, and enable control
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),

        .ENARDEN(ce),
        .ENBWREN(ce),
        .REGCEAREGCE(ce),
        .REGCEB(ce),

        .RSTRAMARSTRAM(rst),
        .RSTRAMB(rst),
        .RSTREGARSTREG(rst),
        .RSTREGB(rst)
    );
(* dont_touch="true" *)
    RAMB18E2#(
        .DOA_REG(1), .DOB_REG(1),
        .CASCADE_ORDER_A("LAST"), .CASCADE_ORDER_B("MIDDLE"),
        .CLOCK_DOMAINS("COMMON"),

        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
        .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
        .READ_WIDTH_A(18), .READ_WIDTH_B(18))
    bram_inst_rdc2(
        .ADDRARDADDR(b3_rd_addr),
        .ADDRBWRADDR(b3_wr_addr),
        .ADDRENA(1'b1),
        .ADDRENB(1'b1),
        .WEA({2{1'b0}}),
        .WEBWE({4{b3_wr_en}}),

        // horizontal links
        .CASDINB(casc_data_b2[15:0]),
        .CASDINPB(casc_data_b2[17:16]),
        .DOUTBDOUT(),
        .DOUTPBDOUTP(),
        .CASDIMUXB(1'b1),
        .CASDIMUXA(1'b0),

        // clocking, reset, and enable control
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),

        .ENARDEN(ce),
        .ENBWREN(ce),
        .REGCEAREGCE(ce),
        .REGCEB(ce),

        .RSTRAMARSTRAM(rst),
        .RSTRAMB(rst),
        .RSTREGARSTREG(rst),
        .RSTREGB(rst)
    );
(* dont_touch="true" *)
RAMB18E2#(
        .DOA_REG(1), .DOB_REG(1),
        .CASCADE_ORDER_A("NONE"), .CASCADE_ORDER_B("LAST"),
        .CLOCK_DOMAINS("COMMON"),

        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
        .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
        .READ_WIDTH_A(18), .READ_WIDTH_B(18))
    bram_inst_rdc3(
        .ADDRARDADDR(b3_rd_addr),
        .ADDRBWRADDR(b3_wr_addr),
        .ADDRENA(1'b1),
        .ADDRENB(1'b1),
        .WEA({2{1'b0}}),
        .WEBWE({4{b3_wr_en}}),

        // horizontal links
        .DOUTADOUT(rd_data_b3[15:0]),
        .DOUTPADOUTP(rd_data_b3[17:16]),
        .CASDINB(casc_data_b3[15:0]),
        .CASDINPB(casc_data_b3[17:16]),
        .DOUTBDOUT(),
        .DOUTPBDOUTP(),
        .CASDIMUXB(1'b1),
        .CASDIMUXA(1'b0),

        // clocking, reset, and enable control
        .CLKARDCLK(clk),
        .CLKBWRCLK(clk),

        .ENARDEN(ce),
        .ENBWREN(ce),
        .REGCEAREGCE(ce),
        .REGCEB(ce),

        .RSTRAMARSTRAM(rst),
        .RSTRAMB(rst),
        .RSTREGARSTREG(rst),
        .RSTREGB(rst)
    );

always @(posedge clk) begin
    r_data_reg[15:0] <= rd_data_b3;
end


(* dont_touch="true" *) reg [D_W-1:0]    r_data_0_reg;
(* dont_touch="true" *) reg [D_W-1:0]    r_data_1_reg;
(* dont_touch="true" *) reg [D_W-1:0]    r_data_2_reg;
(* dont_touch="true" *) reg [D_W-1:0]    r_data_3_reg;
(* dont_touch="true" *) reg [OFFCHIP_DW-1:0] w_data_offchip_0_reg;
(* dont_touch="true" *) reg [ADDR_W-1:0]     w_addr_offchip_0_reg;
(* dont_touch="true" *) reg [ADDR_W-1:0]     r_addr_offchip_0_reg;
(* dont_touch="true" *) reg [OFFCHIP_DW-1:0] r_data_offchip_1_reg;
(* dont_touch="true" *) reg [OFFCHIP_DW-1:0] w_data_offchip_2_reg;
(* dont_touch="true" *) reg [ADDR_W-1:0]     w_addr_offchip_2_reg;
(* dont_touch="true" *) reg [ADDR_W-1:0]     r_addr_offchip_2_reg;

always @* begin
    case (select)
        3'b000: begin // level-1 NOC 0
            w_data_offchip_0_reg <= r_data_reg;
        end
        3'b001: begin // level-1 NOC 1
            r_data_offchip_1_reg <= r_data_reg;
        end
        3'b010: begin // level-1 NOC 2
            w_data_offchip_2_reg <= r_data_reg;
        end
        3'b011: begin // level-2 NOC 0
            r_data_0_reg <= r_data_reg;
        end
        3'b100: begin // level-2 NOC 1
            r_data_1_reg <= r_data_reg;
        end
        3'b101: begin // level-2 NOC 2
            r_data_2_reg <= r_data_reg;
        end
        3'b110: begin // level-2 NOC 3
            r_data_3_reg <= r_data_reg;
        end
    endcase
end

assign r_data_0 = r_data_0_reg;
assign r_data_1 = r_data_1_reg;
assign r_data_2 = r_data_2_reg;
assign r_data_3 = r_data_3_reg;
assign w_data_offchip_0 = w_data_offchip_0_reg;
assign w_addr_offchip_0 = w_addr_offchip_0_reg;
assign r_addr_offchip_0 = r_addr_offchip_0_reg;
assign w_data_offchip_1 = r_data_offchip_1_reg;
assign w_data_offchip_2 = w_data_offchip_2_reg;
assign w_addr_offchip_2 = w_addr_offchip_2_reg;
assign r_addr_offchip_2 = r_addr_offchip_2_reg;
endmodule