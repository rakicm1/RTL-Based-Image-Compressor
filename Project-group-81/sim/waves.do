# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}

add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data
add wave -hex UUT/VGA_enable

add wave -divider -height 10 {FS signals}
add wave -hex UUT/M2_unit/state
add wave -hex UUT/M2_unit/write_data_a\[0\]
add wave -hex UUT/M2_unit/read_data_a32\[0\]
add wave -hex UUT/M2_unit/read_data_b32\[0\]
add wave -hex UUT/M2_unit/address_a\[0\]
add wave -hex UUT/M2_unit/address_b\[0\]

add wave -divider -height 10 {CT signals}
add wave -hex UUT/M2_unit/write_enable_a\[2\]
add wave -hex UUT/M2_unit/write_data_a\[2\]
add wave -hex UUT/M2_unit/address_a\[2\]

add wave -hex UUT/M2_unit/write_enable_a\[3\]
add wave -hex UUT/M2_unit/write_data_a\[3\]
add wave -hex UUT/M2_unit/address_a\[3\]

add wave -hex UUT/M2_unit/read_data_a32\[1\]

add wave -hex UUT/M2_unit/op1_1
add wave -hex UUT/M2_unit/op2_1
add wave -hex UUT/M2_unit/op1_2
add wave -hex UUT/M2_unit/op2_2
add wave -hex UUT/M2_unit/op1_3
add wave -hex UUT/M2_unit/op2_3


add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

