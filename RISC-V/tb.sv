`timescale 1ns/1ps

module tb;

    // Parameters
    parameter XLEN = 32;

    // Signals
    logic clk;
    logic rst_n;
    logic [31:0] pc_out;

    // Instantiate CPU
    riscv_pipelined #(
        .XLEN(XLEN),
        .IMEM_WORDS(1024),
        .DMEM_WORDS(1024)
    ) cpu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock (10ns period)

    // Reset Generation
    initial begin
        rst_n = 0;
        #20;       // Hold reset low for 20ns
        rst_n = 1; // Release reset
    end

    // Monitor PC and Registers
    initial begin
        $display("Time(ns)\tPC\t\tRegs[1]\tRegs[2]\tRegs[3]");
        $monitor("%0t\t%h\t%h\t%h\t%h", 
                 $time, pc_out, cpu_inst.regs[1], cpu_inst.regs[2], cpu_inst.regs[3]);
    end

    // Simulation Time Limit
    initial begin
        #1000; // Run simulation for 1000ns
        $display("Simulation finished.");
        $stop;
    end

    // Optional: Dump waveform for GTKWave
    initial begin
        $dumpfile("riscv.vcd");
        $dumpvars(0, tb);
    end

endmodule
