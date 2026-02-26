# fpga-patterns

## Knowledge Base

Synthesizable Verilog patterns for FPGA-MCU integration. Targeting Xilinx Artix-7 and Intel Cyclone V.

---

## Pattern 1: Register Bank with Read/Write Strobe

Simpler than AXI-Lite for SPI-connected FPGAs:

```verilog
/* 8 x 32-bit register file with address/data/write-enable interface */
module reg_bank (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  addr,
    input  wire [31:0] wdata,
    input  wire        wen,
    output reg  [31:0] rdata,
    /* Application outputs */
    output wire [31:0] reg0_out,
    output wire [31:0] reg1_out,
    input  wire [31:0] reg4_in,   /* Read-back from hardware */
    input  wire [31:0] reg5_in
);
    reg [31:0] regs [0:7];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= 32'h0; regs[1] <= 32'h0;
            regs[2] <= 32'h0; regs[3] <= 32'h0;
        end else if (wen) begin
            regs[addr] <= wdata;
        end
    end

    /* Read: hardware status registers override software writes */
    always @(*) begin
        case (addr)
            3'd4:    rdata = reg4_in;
            3'd5:    rdata = reg5_in;
            default: rdata = regs[addr];
        endcase
    end

    assign reg0_out = regs[0];
    assign reg1_out = regs[1];
endmodule
```

---

## Pattern 2: Clock Domain Crossing — 2FF Synchronizer

Signals crossing from one clock domain to another must be synchronized to avoid metastability.

```verilog
/* 2-flipflop synchronizer for a single control bit */
module sync_2ff (
    input  wire dst_clk,
    input  wire rst_n,
    input  wire sig_in,      /* Asynchronous input */
    output reg  sig_out      /* Synchronized output */
);
    reg ff1;

    (* ASYNC_REG = "TRUE" *) reg sync_ff1;   /* Vivado: keep close in placement */
    (* ASYNC_REG = "TRUE" *) reg sync_ff2;

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 0; sync_ff2 <= 0;
        end else begin
            sync_ff1 <= sig_in;
            sync_ff2 <= sync_ff1;
        end
    end
    assign sig_out = sync_ff2;
endmodule
```

For multi-bit data: use a dual-clock FIFO or handshaking with acknowledgment.

---

## Pattern 3: Pulse Width Modulation (PWM) Generator

```verilog
module pwm_gen #(
    parameter integer CNT_WIDTH = 16    /* 100MHz / 65536 ≈ 1.5kHz */
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [CNT_WIDTH-1:0]  duty,  /* 0=0%, 65535=100% */
    output reg                   pwm_out
);
    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 0;
            pwm_out <= 0;
        end else begin
            cnt     <= cnt + 1;
            pwm_out <= (cnt < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule
```

MCU sets `duty` register via SPI/AXI. Frequency = clk / (2^CNT_WIDTH).

---

## Pattern 4: Xilinx Block Design Tcl Automation

```tcl
# Create Vivado project from Tcl (for version control of block design)
create_project myproject ./myproject -part xc7a100tcsg324-1

# Add HDL sources
add_files -norecurse {src/spi_slave.v src/reg_bank.v}

# Create block design with Zynq PS
create_bd_design "system"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Apply Zynq preset (board-specific)
set_property CONFIG.preset {ZedBoard} [get_bd_cells ps7]

# Connect AXI-Lite custom IP
create_bd_cell -type module -reference axi_lite_regs axi_regs_0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/ps7/M_AXI_GP0" Clk "Auto"} [get_bd_intf_pins axi_regs_0/S_AXI]

# Save and generate
save_bd_design
generate_target all [get_files system.bd]
```

---

## Pattern 5: SignalTap / ILA In-Logic Analyzer

Add debug capture to synthesized netlist (no external pins needed):

```tcl
# Vivado: create ILA debug core via Tcl
create_debug_core u_ila ila
set_property C_DATA_DEPTH  1024 [get_debug_cores u_ila]
set_property C_TRIGIN_EN  false [get_debug_cores u_ila]

# Connect signals to probe
set_property port_width 8 [get_debug_ports u_ila/probe0]
connect_debug_port u_ila/probe0 [get_nets spi_rx_byte]

set_property port_width 1 [get_debug_ports u_ila/probe1]
connect_debug_port u_ila/probe1 [get_nets spi_rx_valid]

implement_debug_core
```

Or instantiate directly in Verilog:
```verilog
ila_0 u_ila (
    .clk    (clk),
    .probe0 (spi_rx_byte),   /* 8 bits */
    .probe1 (spi_rx_valid)   /* 1 bit  */
);
```

---

## Anti-Patterns

- **Combinational loops**: any feedback path without a register causes simulation mismatch and synthesis failure. Add a register.
- **Missing `(* ASYNC_REG = "TRUE" *)` on CDC synchronizers**: Vivado placement optimizer separates the two FFs, increasing metastability risk.
- **Inferring RAM with `initial` blocks**: synthesis ignores `initial`; use reset logic or external initialization.
- **Blocking assignments in sequential blocks**: use non-blocking (`<=`) for clocked logic. Mixing causes simulation/synthesis mismatch.

## References

- Xilinx UG901: Vivado Design Suite User Guide - Synthesis
- Xilinx PG209: AXI4-Lite Interface
- Intel AN 433: Constraining and Analyzing Source Synchronous Interfaces (Quartus)
- Cummings, "Simulation and Synthesis Techniques for Asynchronous FIFO Design" (SNUG 2002)
