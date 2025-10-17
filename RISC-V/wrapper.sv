`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2025 10:19:26 AM
// Design Name: 
// Module Name: wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//===========================================================
// Dual-Port BRAM Wrapper for blk_mem_gen_0
// Port A: Instruction Memory (read-only)
// Port B: Data Memory (read/write)
//===========================================================
`timescale 1ns/1ps
module blk_mem_gen_0_wrapper (
    // Port A (Instruction Memory)
    input  wire         clka,
    input  wire         ena,
    input  wire         wea,
    input  wire [9:0]   addra,   // 1024 words → 10-bit address
    input  wire [31:0]  dina,
    output wire [31:0]  douta,

    // Port B (Data Memory)
    input  wire         clkb,
    input  wire         enb,
    input  wire         web,
    input  wire [9:0]   addrb,
    input  wire [31:0]  dinb,
    output wire [31:0]  doutb
);

    //=======================================================
    // Instantiate the Xilinx Block Memory Generator IP
    //=======================================================
    blk_mem_gen_0 u_bram (
        // Port A
        .clka(clka),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta),

        // Port B
        .clkb(clkb),
        .enb(enb),
        .web(web),
        .addrb(addrb),
        .dinb(dinb),
        .doutb(doutb)
    );

endmodule

