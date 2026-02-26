# /fpga

FPGA integration command: HDL generation, synthesis, programming, MCU interface.

## Trigger

`/fpga <action> [options]`

## Actions

### `design`
Generate a Verilog module for a specified function.

```
/fpga design --module axi-lite-slave --regs 8 --data-width 32
/fpga design --module spi-slave --mode 0 --bits 8
/fpga design --module pwm --channels 4 --resolution 16
/fpga design --module uart --baud 115200 --clk 100MHz
```

### `synthesize`
Generate synthesis Tcl script for Vivado or Quartus.

```
/fpga synthesize --tool vivado --part xc7a35tcpg236-1 --top my_top
/fpga synthesize --tool quartus --device 5CEBA4F23C7 --top my_top
```

### `program`
Generate programming commands.

```
/fpga program --tool vivado --interface jtag --bitfile my_top.bit
/fpga program --tool openocd --interface jlink --bitfile my_top.svf
/fpga program --tool quartus-pgm --interface usb-blaster
```

### `interface`
Generate MCU-side driver code for the FPGA interface.

```
/fpga interface --type spi --mcu stm32f407 --fpga-regs 8
/fpga interface --type axi-lite --mcu zynq --base-addr 0x43C00000
```

## Process

1. Define register map (address, name, R/W, reset value) before writing HDL.
2. Write Verilog with non-blocking assignments in clocked always blocks.
3. Write a testbench and simulate with Icarus Verilog or Vivado Simulator.
4. Add timing constraints for all clocks and CDC paths.
5. Run implementation, check timing report (worst negative slack must be positive).

## Output Examples

### Register map definition
```
Offset | Name       | Access | Bits  | Description
0x00   | CTRL       | R/W    | [0]   | Enable (1=on)
                              [1]   | Reset (self-clearing)
0x04   | PERIOD     | R/W    | [15:0]| PWM period in clock cycles
0x08   | DUTY       | R/W    | [15:0]| PWM duty cycle count
0x0C   | STATUS     | RO     | [0]   | Output active
                              [7:4] | Error flags
```

### Icarus Verilog simulation
```bash
# Compile
iverilog -o sim.vvp tb_spi_slave.v spi_slave.v

# Run
vvp sim.vvp

# Waveform (requires GTKWave)
vvp sim.vvp -lxt2
gtkwave sim.lxt
```

### Vivado one-liner build
```tcl
# From Vivado Tcl console:
source create_project.tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
```

## Error Handling

- "Timing not met: slack = -2.5 ns" — reduce clock frequency, add pipeline register, or restructure critical path logic
- "MMCM lock timeout" — input clock not present or wrong frequency; verify board oscillator
- "CDC violation" — missing synchronizer; add 2FF synchronizer between clock domains
- "SPI byte off by one" — bit_cnt not reset on CS deassertion; check cs_n edge handling in FSM
