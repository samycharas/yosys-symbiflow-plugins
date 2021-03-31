(* abc9_box, lib_whitebox *)
module adder(
        output sumout,
        output cout,
        input a,
        input b,
        input cin
);
        assign sumout = a ^ b ^ cin;
        assign cout = (a & b) | ((a | b) & cin);

endmodule



(* abc9_lut=1, lib_whitebox *)
module frac_lut6(
        input [0:5] in,
        output [0:3] lut4_out,
        output [0:1] lut5_out,
        output lut6_out
);
        parameter [0:63] LUT = 0;
        // Effective LUT input
        wire [0:5] li = in;

        // Output function
        wire [0:31] s1 = li[0] ?
           {LUT[0] , LUT[2] , LUT[4] , LUT[6] , LUT[8] , LUT[10], LUT[12], LUT[14], 
            LUT[16], LUT[18], LUT[20], LUT[22], LUT[24], LUT[26], LUT[28], LUT[30],
            LUT[32], LUT[34], LUT[36], LUT[38], LUT[40], LUT[42], LUT[44], LUT[46],
            LUT[48], LUT[50], LUT[52], LUT[54], LUT[56], LUT[58], LUT[60], LUT[62]}:
           {LUT[1] , LUT[3] , LUT[5] , LUT[7] , LUT[9] , LUT[11], LUT[13], LUT[15], 
            LUT[17], LUT[19], LUT[21], LUT[23], LUT[25], LUT[27], LUT[29], LUT[31],
            LUT[33], LUT[35], LUT[37], LUT[39], LUT[41], LUT[43], LUT[45], LUT[47],
            LUT[49], LUT[51], LUT[53], LUT[55], LUT[57], LUT[59], LUT[61], LUT[63]};

        wire [0:15] s2 = li[1] ?
           {s1[0] , s1[2] , s1[4] , s1[6] , s1[8] , s1[10], s1[12], s1[14],
            s1[16], s1[18], s1[20], s1[22], s1[24], s1[26], s1[28], s1[30]}:
           {s1[1] , s1[3] , s1[5] , s1[7] , s1[9] , s1[11], s1[13], s1[15],
            s1[17], s1[19], s1[21], s1[23], s1[25], s1[27], s1[29], s1[31]};

        wire [0:7] s3 = li[2] ?
            {s2[0], s2[2], s2[4], s2[6], s2[8], s2[10], s2[12], s2[14]}:
            {s2[1], s2[3], s2[5], s2[7], s2[9], s2[11], s2[13], s2[15]};

        wire [0:3] s4 = li[3] ? {s3[0], s3[2], s3[4], s3[6]}:
                                {s3[1], s3[3], s3[5], s3[7]};

        wire [0:1] s5 = li[4] ? {s4[0], s4[2]} : {s4[1], s4[3]};

        assign lut4_out[0] = s4[0];
        assign lut4_out[1] = s4[1];
        assign lut4_out[2] = s4[2];
        assign lut4_out[3] = s4[3];

        assign lut5_out[0] = s0[0];
        assign lut5_out[1] = s5[1];

        assign lut6_out = li[5] ? s5[0] : s5[1];

endmodule

(* abc9_flop, lib_whitebox *)
module dff(
        output reg Q,
        input D,
        (* clkbuf_sink *)
        input C
);
        parameter [0:0] INIT = 1'b0;
        initial Q = INIT;

        always @(posedge C)
                Q <= D;
endmodule

(* abc9_flop, lib_whitebox *)
module dffr(
        output reg Q,
        input D,
        input R,
        (* clkbuf_sink *)
        input C
);
        parameter [0:0] INIT = 1'b0;
        initial Q = INIT;

        always @(posedge C)
                if (R == 1'b1)
                        Q <= 1'b0;
                else
                        Q <= D;
endmodule

(* abc9_flop, lib_whitebox *)
module dffre(
    output reg Q,
    input D,
    input R,
    input E,
    (* clkbuf_sink *)
    input C
);
    parameter [0:0] INIT = 1'b0;
    initial Q = INIT;

    always @(posedge C)
       if (R == 1'b1)
            Q <= 1'b0;
       else if(E)
            Q <= D;
endmodule

(* abc9_flop, lib_whitebox *)
module latch(
    output reg Q,
    input D,
    input E,
    input R
);
    parameter [0:0] INIT = 1'b0;
    initial Q = INIT;

    always @*
	if (R == 1'b1)
            Q <= D;
endmodule

(* abc9_flop, lib_whitebox *)
module scff(
        output reg Q,
        input D,
        input clk
);
        parameter [0:0] INIT = 1'b0;
        initial Q = INIT;

        always @(posedge clk)
                Q <= D;
endmodule


module DP_RAM16K (
        input rclk, 
        input wclk,
        input wen,
        input ren,
        input[8:0] waddr,
        input[8:0] raddr,
        input[31:0] d_in,
        input[31:0] wenb,
        output[31:0] d_out );

        _dual_port_sram memory_0 (
                .wclk           (wclk),
                .wen            (wen),
                .waddr          (waddr),
                .data_in        (d_in),
                .rclk           (rclk),
                .ren            (ren),
                .raddr          (raddr),
                .wenb		(wenb),
                .d_out          (d_out) );

endmodule

module _dual_port_sram (
        input wclk,
        input wen,
        input[8:0] waddr,
        input[31:0] data_in,
        input rclk,
        input ren,
        input[8:0] raddr,
        input[31:0] wenb,
        output[31:0] d_out );

        // MODE 0:  512 x 32
        // MODE 1:  1024 x 16
        // MODE 2: 1024 x 8
        // MODE 3: 2048 x 4
        
        integer i;
        reg[31:0] ram[512:0];
        reg[31:0] internal;
        // The memory is self initialised
        
        initial begin
                for (i=0;i<=512;i=i+1)
                begin
                    ram[i] = 0;
                end
                internal = 31'b0; 
        end
        
        
        wire [31:0] WMASK;

        assign d_out = internal;
        assign WMASK = wenb;

        always @(posedge wclk) begin
                if(!wen) begin
                        if (WMASK[ 0]) ram[waddr][ 0] <= data_in[ 0];
                        if (WMASK[ 1]) ram[waddr][ 1] <= data_in[ 1];
                        if (WMASK[ 2]) ram[waddr][ 2] <= data_in[ 2];
                        if (WMASK[ 3]) ram[waddr][ 3] <= data_in[ 3];
                        if (WMASK[ 4]) ram[waddr][ 4] <= data_in[ 4];
                        if (WMASK[ 5]) ram[waddr][ 5] <= data_in[ 5];
                        if (WMASK[ 6]) ram[waddr][ 6] <= data_in[ 6];
                        if (WMASK[ 7]) ram[waddr][ 7] <= data_in[ 7];
                        if (WMASK[ 8]) ram[waddr][ 8] <= data_in[ 8];
                        if (WMASK[ 9]) ram[waddr][ 9] <= data_in[ 9];
                        if (WMASK[10]) ram[waddr][10] <= data_in[10];
                        if (WMASK[11]) ram[waddr][11] <= data_in[11];
                        if (WMASK[12]) ram[waddr][12] <= data_in[12];
                        if (WMASK[13]) ram[waddr][13] <= data_in[13];
                        if (WMASK[14]) ram[waddr][14] <= data_in[14];
                        if (WMASK[15]) ram[waddr][15] <= data_in[15];
                        if (WMASK[16]) ram[waddr][16] <= data_in[16];
                        if (WMASK[17]) ram[waddr][17] <= data_in[17];
                        if (WMASK[18]) ram[waddr][18] <= data_in[18];
                        if (WMASK[19]) ram[waddr][19] <= data_in[19];
                        if (WMASK[20]) ram[waddr][20] <= data_in[20];
                        if (WMASK[21]) ram[waddr][21] <= data_in[21];
                        if (WMASK[22]) ram[waddr][22] <= data_in[22];
                        if (WMASK[23]) ram[waddr][23] <= data_in[23];
                        if (WMASK[24]) ram[waddr][24] <= data_in[24];
                        if (WMASK[25]) ram[waddr][25] <= data_in[25];
                        if (WMASK[26]) ram[waddr][26] <= data_in[26];
                        if (WMASK[27]) ram[waddr][27] <= data_in[27];
                        if (WMASK[28]) ram[waddr][28] <= data_in[28];
                        if (WMASK[29]) ram[waddr][29] <= data_in[29];
                        if (WMASK[30]) ram[waddr][30] <= data_in[30];
                        if (WMASK[31]) ram[waddr][31] <= data_in[31];
                end
        end

        always @(posedge rclk) begin
                if(!ren) begin
                        internal <= ram[raddr];
                end
        end

endmodule
