// RV32I 5-Stage Pipelined CPU (v1: Ideal Pipeline Structure)
// This version establishes the pipeline stages, but does not yet implement 
// full hazard detection or forwarding logic, which will be added in v2.

module riscv_pipelined #(
    parameter XLEN = 32,
    parameter IMEM_WORDS = 1024,
    parameter DMEM_WORDS = 1024
)(
    input  logic              clk,
    input  logic              rst_n,      // active low reset
    output logic [31:0]       pc_out
);

    // --- Core Memory and Register Declarations ---
    logic [31:0] imem [0:IMEM_WORDS-1];
    logic [31:0] dmem [0:DMEM_WORDS-1];
    logic [31:0] regs [0:31];
    
    // --- Global Signals ---
    logic [31:0] pc, next_pc;
    assign pc_out = pc;

    // --- Pipeline Register Definitions ---
    // IF/ID Register
    logic [31:0] if_id_instr;
    logic [31:0] if_id_pc;
    
    // ID/EX Register
    logic [31:0] id_ex_instr;
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_rdata1;
    logic [31:0] id_ex_rdata2;
    logic [31:0] id_ex_imm;
    logic [3:0]  id_ex_alu_op;
    logic id_ex_reg_we;
    // Add control signals needed in EX/MEM stages (Load/Store/Branch flags, Funct3, etc.)
    logic id_ex_is_load, id_ex_is_store; 
    logic id_ex_is_branch, id_ex_is_jal, id_ex_is_jalr; 
    logic id_ex_is_rtype, id_ex_is_itype_alu;
    
    // EX/MEM Register
    logic [31:0] ex_mem_pc_plus_4; 
    logic [31:0] ex_mem_alu_out;
    logic [31:0] ex_mem_wdata; // data to be stored (rdata2 or zero)
    logic [4:0]  ex_mem_rd; // Destination register address
    logic ex_mem_reg_we;
    // Control signals for MEM stage
    logic ex_mem_mem_we; // Write enable for Data Memory (from is_store)
    logic ex_mem_is_load;
    // Control signals for WB stage (to determine wb_data source)
    logic ex_mem_is_jal; 
    
    // MEM/WB Register
    logic [31:0] mem_wb_alu_out;
    logic [31:0] mem_wb_mem_rdata;
    logic [31:0] mem_wb_pc_plus_4;
    logic [4:0]  mem_wb_rd;
    logic mem_wb_reg_we;
    logic mem_wb_is_load;
    logic mem_wb_is_jal;
    
    // Write-back data source selector signals
    logic mem_wb_wb_sel_mem;
    logic mem_wb_wb_sel_pc4;


    // =========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // =========================================================================
    
    // PC Update Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc <= 32'd0;
        else pc <= next_pc;
    end
    
    // Instruction Read (Combinational)
    wire [31:0] instr_if = imem[pc[31:2]];

    // IF/ID Register Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_instr <= 32'b0;
            if_id_pc    <= 32'b0;
        end else begin
            // Placeholder: Hazard stall/flush logic will be added here later
            if_id_instr <= instr_if;
            if_id_pc    <= pc;
        end
    end
    
    // Default Next PC (Sequential path)
    assign next_pc = pc + 4; // This will be overridden by jump/branch logic later

    // =========================================================================
    // STAGE 2: INSTRUCTION DECODE / REGISTER FETCH (ID)
    // =========================================================================
    
    // Instruction Fields from IF/ID Register
    wire [6:0]  id_opcode = if_id_instr[6:0];
    wire [4:0]  id_rd     = if_id_instr[11:7];
    wire [2:0]  id_funct3 = if_id_instr[14:12];
    wire [4:0]  id_rs1    = if_id_instr[19:15];
    wire [4:0]  id_rs2    = if_id_instr[24:20];
    wire [6:0]  id_funct7 = if_id_instr[31:25];
    
    // Register File Read
    wire [31:0] id_rdata1 = (id_rs1 == 0) ? 32'b0 : regs[id_rs1];
    wire [31:0] id_rdata2 = (id_rs2 == 0) ? 32'b0 : regs[id_rs2];

    // Immediate Generation (Combinational)
    wire [31:0] id_imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    wire [31:0] id_imm_s = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    wire [31:0] id_imm_u_shifted = {if_id_instr[31:12], 12'b0};

    // Control Unit (Combinational)
    logic id_reg_we;
    logic id_is_load, id_is_store, id_is_branch, id_is_jal, id_is_jalr;
    logic id_is_rtype, id_is_itype_alu;
    logic [3:0] id_alu_op;
    
    always_comb begin
        id_reg_we = 1'b0;
        id_is_load = 1'b0; id_is_store = 1'b0; id_is_branch = 1'b0; id_is_jal = 1'b0; id_is_jalr = 1'b0;
        id_is_rtype = 1'b0; id_is_itype_alu = 1'b0;
        id_alu_op = 4'h0;

        unique case (id_opcode)
            7'b0110011: begin // R-type
                id_is_rtype = 1; id_reg_we = 1; 
                // Placeholder: Full control logic from single-cycle needs to be integrated here
                case ({id_funct7,id_funct3})
                    {7'b0000000,3'b000}: id_alu_op = 4'h0; // ADD
                    {7'b0100000,3'b000}: id_alu_op = 4'h1; // SUB
                    default: id_alu_op = 4'hF;
                endcase
            end
            7'b0010011: begin // I-type ALU
                id_is_itype_alu = 1; id_reg_we = 1; 
                case (id_funct3)
                    3'b000: id_alu_op = 4'h0; // ADDI
                    default: id_alu_op = 4'hF;
                endcase
            end
            7'b0000011: begin // Load
                id_is_load = 1; id_reg_we = 1; id_alu_op = 4'h0; // Address calc
            end
            7'b0100011: begin // Store
                id_is_store = 1; id_alu_op = 4'h0; // Address calc
            end
            7'b1100011: begin // Branch
                id_is_branch = 1; // Branch condition evaluation
            end
            7'b1101111: begin // JAL
                id_is_jal = 1; id_reg_we = 1; // PC+4 to RD
            end
            7'b1100111: begin // JALR
                id_is_jalr = 1; id_reg_we = 1; id_alu_op = 4'h0; // Target calc
            end
            7'b0110111: begin // LUI
                id_reg_we = 1; id_alu_op = 4'h0; // LUI/AUIPC always use ADD
            end
            7'b0010111: begin // AUIPC
                id_reg_we = 1; id_alu_op = 4'h0;
            end
            default: ; // NOP
        endcase
    end
    
    // ID/EX Register Update (Registers are loaded at the rising edge)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_instr    <= 32'b0;
            id_ex_pc       <= 32'b0;
            id_ex_rdata1   <= 32'b0;
            id_ex_rdata2   <= 32'b0;
            id_ex_imm      <= 32'b0;
            id_ex_alu_op   <= 4'b0;
            id_ex_reg_we   <= 1'b0;
            id_ex_is_load  <= 1'b0;
            id_ex_is_store <= 1'b0;
            id_ex_is_branch <= 1'b0;
            id_ex_is_jal   <= 1'b0;
            id_ex_is_jalr  <= 1'b0;
            id_ex_is_rtype <= 1'b0;
            id_ex_is_itype_alu <= 1'b0;
        end else begin
            // Placeholder: Stall logic will freeze this stage register later
            id_ex_instr    <= if_id_instr;
            id_ex_pc       <= if_id_pc;
            id_ex_rdata1   <= id_rdata1; 
            id_ex_rdata2   <= id_rdata2; 
            
            // Immediate selector logic
            if (id_is_store) id_ex_imm <= id_imm_s;
            else if (id_opcode == 7'b0110111 || id_opcode == 7'b0010111) id_ex_imm <= id_imm_u_shifted; // LUI/AUIPC
            else id_ex_imm <= id_imm_i;
            
            // Control
            id_ex_alu_op   <= id_alu_op;
            id_ex_reg_we   <= id_reg_we;
            id_ex_is_load  <= id_is_load;
            id_ex_is_store <= id_is_store;
            id_ex_is_branch <= id_is_branch;
            id_ex_is_jal   <= id_is_jal;
            id_ex_is_jalr  <= id_is_jalr;
            id_ex_is_rtype <= id_is_rtype;
            id_ex_is_itype_alu <= id_is_itype_alu;
        end
    end

    // =========================================================================
    // STAGE 3: EXECUTE (EX)
    // =========================================================================
    
    // ALU Input Selection (Combinational)
    logic [31:0] ex_alu_a, ex_alu_b;
    always_comb begin
        // Default ALU inputs
        ex_alu_a = id_ex_rdata1; 
        ex_alu_b = id_ex_rdata2;

        if (id_ex_is_itype_alu || id_ex_is_load || id_ex_is_store || id_ex_is_jalr) begin
            // I/S/JALR-type instructions use immediate as second operand
            ex_alu_b = id_ex_imm;
        end else if (id_ex_is_rtype) begin
            ex_alu_b = id_ex_rdata2;
        end
        
        // Special case for AUIPC/LUI
        if (id_ex_instr[6:0] == 7'b0010111) begin // AUIPC
            ex_alu_a = id_ex_pc;
            ex_alu_b = id_ex_imm;
        end else if (id_ex_instr[6:0] == 7'b0110111) begin // LUI
            ex_alu_a = 32'b0;
            ex_alu_b = id_ex_imm;
        end
        
        // Placeholder: Forwarding logic will adjust ex_alu_a and ex_alu_b here
    end
    
    // ALU Execution (Combinational)
    logic [31:0] ex_alu_out;
    always_comb begin
        // Only implementing ADD/SUB/AND for structural completeness.
        unique case (id_ex_alu_op)
            4'h0: ex_alu_out = ex_alu_a + ex_alu_b; 
            4'h1: ex_alu_out = ex_alu_a - ex_alu_b; 
            4'h2: ex_alu_out = ex_alu_a & ex_alu_b; 
            // ... more ALU ops will be added here
            default: ex_alu_out = 32'hX;
        endcase
    end
    
    // EX/MEM Register Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_out <= 32'b0;
            ex_mem_wdata   <= 32'b0;
            ex_mem_rd      <= 5'b0;
            ex_mem_reg_we  <= 1'b0;
            ex_mem_mem_we  <= 1'b0;
            ex_mem_is_load <= 1'b0;
            ex_mem_is_jal  <= 1'b0;
            ex_mem_pc_plus_4 <= 32'b0;
        end else begin
            // ALU result is stored (used for Load/Store address, or ALU write-back data)
            ex_mem_alu_out <= ex_alu_out;
            
            // Write data for Store instructions (rs2 data)
            ex_mem_wdata   <= id_ex_rdata2;
            
            // Destination register address
            ex_mem_rd      <= id_ex_instr[11:7];

            // Control signals carry forward
            ex_mem_reg_we  <= id_ex_reg_we;
            ex_mem_mem_we  <= id_ex_is_store; 
            ex_mem_is_load <= id_ex_is_load;
            ex_mem_is_jal  <= id_ex_is_jal | id_ex_is_jalr;
            ex_mem_pc_plus_4 <= id_ex_pc + 4; // PC+4 always calculated
        end
    end

    // =========================================================================
    // STAGE 4: MEMORY ACCESS (MEM)
    // =========================================================================
    
    // Data Memory Read (Combinational)
    wire [31:0] mem_dmem_rdata = dmem[ex_mem_alu_out[31:2]];

    // Data Memory Write (Synchronous)
    always_ff @(posedge clk) begin
        if (ex_mem_mem_we) begin
            // Placeholder: Only word store (SW) is implemented. SB/SH need masking.
            dmem[ex_mem_alu_out[31:2]] <= ex_mem_wdata;
        end
    end
    
    // MEM/WB Register Update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_alu_out   <= 32'b0;
            mem_wb_mem_rdata <= 32'b0;
            mem_wb_pc_plus_4 <= 32'b0;
            mem_wb_rd        <= 5'b0;
            mem_wb_reg_we    <= 1'b0;
            mem_wb_is_load   <= 1'b0;
            mem_wb_is_jal    <= 1'b0;
        end else begin
            mem_wb_alu_out   <= ex_mem_alu_out;
            mem_wb_mem_rdata <= mem_dmem_rdata;
            mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
            mem_wb_rd        <= ex_mem_rd;
            mem_wb_reg_we    <= ex_mem_reg_we;
            mem_wb_is_load   <= ex_mem_is_load;
            mem_wb_is_jal    <= ex_mem_is_jal;
        end
    end

    // =========================================================================
    // STAGE 5: WRITE BACK (WB)
    // =========================================================================
    
    // WB Data Selection (Combinational)
    wire [31:0] wb_data;
    assign wb_data = (mem_wb_is_load) ? mem_wb_mem_rdata :  // Load instructions
                     (mem_wb_is_jal)  ? mem_wb_pc_plus_4 :  // JAL/JALR return address
                                        mem_wb_alu_out;     // ALU/LUI/AUIPC result

    // Register File Write (Synchronous)
    always_ff @(posedge clk) begin
        if (mem_wb_reg_we && (mem_wb_rd != 5'b0)) begin
            regs[mem_wb_rd] <= wb_data;
        end
        regs[0] <= 32'b0; // Ensure x0 remains 0
    end
    
    // --- Instruction Memory Initialization ---
    initial begin
        integer i;
        for (i = 0; i < IMEM_WORDS; i = i+1) imem[i] = 32'h00000013; // NOP (addi x0,x0,0)
    end

endmodule