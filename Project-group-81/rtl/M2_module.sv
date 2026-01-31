/*
Work by Matthew Rakic & James Cameron
Aspiring Computer Engineers
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_M2_state.h"

module M2_module (
    input  logic        Clock,
    input  logic        Resetn,
    input  logic        Start,
    output logic        Done,

    // External SRAM interface
    input  logic [15:0] SRAM_read_data,
    output logic [17:0] SRAM_address,
    output logic [15:0] SRAM_write_data,
    output logic        SRAM_we_n
);

M2_state_type state, next_state;

logic [7:0] address_a[3:0];
logic [7:0] address_b[3:0];

logic [31:0] write_data_a[3:0];
logic [31:0] write_data_b;

logic write_enable_a[3:0];
logic write_enable_b;

logic [31:0] read_data_a32[3:0];
logic [31:0] read_data_b32[3:0];

// fetch S registers/////./////////

localparam BASE_Y = 18'd27648;

logic [3:0] Ri;  
logic [3:0] Ci;

logic [3:0] Rb;  
logic [3:0] Cb;

logic signed [15:0] sprime_even_buf;  //bufffer for storing even and odd values together.
logic sprime_is_even;
logic [6:0]  sprime_index;         // for incrementing the Ram0 addressing
logic first_run;

typedef enum logic [2:0] {
    FS_0,      
    FS_1,       
    FS_RUN,    
    FS_L1,      
    FS_L2,
	 FS_L3,
	 FS_DONE
} state_fs_s;
state_fs_s state_fs;


// compute T registers //////

// compute T registers //////

typedef enum logic [1:0] {
    S_CTL,
    S_CT1,
    S_CT2,
    S_CT3
} state_ct_t;

state_ct_t state_ct;

logic [31:0] ct_acc;     
logic [31:0] ct_acc_buf;
logic [3:0] ct_counter;
logic [3:0] accum_counter;

logic [3:0] ct_i, ct_j;
logic [3:0] ct_ibuf, ct_jbuf;

logic signed [16:0] op1_1, op2_1, op1_2, op2_2, op1_3, op2_3;

logic signed [31:0] mult1, mult2, mult3;

assign mult1 = op1_1 * op2_1;
assign mult2 = op1_2 * op2_2;
assign mult3 = op1_3 * op2_3;

// compute S registers //////

typedef enum logic [1:0] {
    S_CSL,
    S_CS1,
    S_CS2,
    S_CS3
} state_cs_t;

state_cs_t state_cs;

logic [31:0] cs_acc;   
logic [31:0] cs_acc_buf;
logic [3:0] cs_counter;
logic [3:0] accum_counter2;
logic [7:0] s_address;
logic y_values;
logic [31:0] prev_value;

logic [3:0] cs_i, cs_j;
logic [3:0] cs_ibuf, cs_jbuf;


/// WS registers ////

typedef enum logic [1:0] {
    WS_LOAD,
	 WS_WRITE
} state_ws_s;

state_ws_s state_ws;

logic [7:0] ws_ram_addr;       
logic [7:0] ws_ram_addr_next;   
logic [15:0] ws_data_buf;      
logic ws_first_cycle;   
logic [14:0] write_counter; 


dual_port_RAM0 RAM_inst0 (
    .address_a (address_a[0]),
    .address_b (address_b[0]),
    .clock     (Clock),
    .data_a    (write_data_a[0]),
    .data_b    (write_data_b),
    .wren_a    (write_enable_a[0]),
    .wren_b    (write_enable_b),
    .q_a       (read_data_a32[0]),
    .q_b       (read_data_b32[0])
);

dual_port_RAM1 RAM_inst1 (
    .address_a (address_a[1]),
    .address_b (address_b[1]),
    .clock     (Clock),
    .data_a    (32'd0),
    .data_b    (32'd0),
    .wren_a    (1'b0),
    .wren_b    (1'b0),
    .q_a       (read_data_a32[1]),
    .q_b       (read_data_b32[1])
);

dual_port_RAM2 RAM_inst2 (
    .address_a (address_a[2]),
    .address_b (address_b[2]),
    .clock     (Clock),
    .data_a    (write_data_a[2]),
    .data_b    (32'd0),
    .wren_a    (write_enable_a[2]),
    .wren_b    (1'b0),
    .q_a       (read_data_a32[2]),
    .q_b       (read_data_b32[2])
);

dual_port_RAM3 RAM_inst3 (
    .address_a (address_a[3]),
    .address_b (address_b[3]),
    .clock     (Clock),
    .data_a    (write_data_a[3]),
    .data_b    (32'd0),
    .wren_a    (write_enable_a[3]),
    .wren_b    (1'b0),
    .q_a       (read_data_a32[3]),
    .q_b       (read_data_b32[3])
);

always_ff @(posedge Clock or negedge Resetn) begin
    if (!Resetn) begin
        state <= S_IDLE_M2;
        
		  // FS// 
		  
		  Ri <= 4'b0;
        Ci <= 4'b0;
        Rb <= 4'b0;
        Cb <= 4'b0;
        sprime_index <= 7'b0;
		  sprime_is_even <= 1'b1;
		  sprime_even_buf <= 16'b0;
		  write_enable_b  <= 1'd0;
		  first_run <= 1'b0;
		  state_fs <= FS_0;
		  
		  // CT // 
		  
		  ct_counter <= 3'b0;
		  accum_counter <= 3'b0;
		  ct_i <= 4'd0;
		  ct_j <= 4'd0;
		  ct_ibuf <= 4'd0;
		  ct_jbuf <= 4'd0;
		  ct_acc <= 32'd0;
		  ct_acc_buf <= 32'd0;
		  state_ct <= S_CTL;


		  // CS  // 
		  cs_counter <= 3'b0;
		  accum_counter2 <= 3'b0;
		  cs_i <= 4'd0;
		  cs_j <= 4'd0;
		  cs_ibuf <= 4'd0;
		  cs_jbuf <= 4'd0;
		  s_address <= 8'd0;
		  
		  
		  //WS//
		  state_ws       <= WS_LOAD;
        ws_ram_addr    <= 8'd129;
        ws_ram_addr_next <= 8'd130;
        ws_data_buf    <= 16'd0;
        write_counter  <= 15'd0;
        ws_first_cycle <= 1'b1;
        SRAM_we_n      <= 1'b1;
		  
		  //last_Megastate <= 1'b0;
		  
		  
    end else begin
        case (state)
            S_IDLE_M2: begin
                if (Start) state <= S_FS;
            end

            S_FS: begin
				
				 case (state_fs)

					  FS_0: begin
							Ci <= 4'd1;
							state_fs <= FS_1;
					  end

					  FS_1: begin
							Ci <= 4'd2;
							sprime_is_even <= 1'b1;
							state_fs <= FS_RUN;
							first_run <= 1'b1;
					  end

					  FS_RUN: begin
							if (sprime_is_even) begin
								 sprime_even_buf <= SRAM_read_data;
								 sprime_is_even  <= 1'd0;
								 write_enable_a[0]  <= 1'd0;
							end else begin 
								 write_enable_a[0]  <= 1'd1;
								 write_data_a[0]    <= {sprime_even_buf, SRAM_read_data};
								 sprime_is_even  <= 1'd1;
								 if(Ci == 4'd3 && first_run) begin
									sprime_index <= sprime_index;
									first_run <= 1'b0;
								 end else begin
									sprime_index <= sprime_index + 7'd1;
								 end
							end		

							if (Ci == 4'd15) begin
								 Ci <= 4'd0;
								 Ri <= Ri + 4'd1;
							end else begin
								 Ci <= Ci + 4'd1;
							end
							
							if (Ri == 4'd15 && Ci == 4'd15)
								 state_fs <= FS_L1;
					  end
					  FS_L1: begin
					  
							sprime_even_buf <= SRAM_read_data;
							sprime_is_even  <= 1'd0;
							write_enable_a[0]  <= 1'd0;

							state_fs <= FS_L2;
					  end
					  FS_L2: begin
							
							write_enable_a[0] <= 1'd1;
							
							write_data_a[0]   <= {sprime_even_buf, SRAM_read_data};
				
							sprime_index <= sprime_index + 1'd1;
							
							state_fs <= FS_L3;
					
					  end
					  FS_L3: begin
							write_enable_a[0] <= 1'd0;
							state_fs <= FS_0;
							Ri <= 4'b0;
							Ci <= 4'b0;
							Rb <= 4'b0;
							Cb <= 4'b1;
							sprime_index <= 7'd0;
							state  <= S_CT;
						end

				 endcase

				end // S_FS

				S_CT: begin
					state_ct <= S_CTL;
			
					case (state_ct)
						S_CTL: begin
							ct_counter <= ct_counter + 1'b1;
							
							state_ct <= S_CT1;
						end
						
						S_CT1: begin
							write_enable_a[2] <= 1'b0;
							write_enable_a[3] <= 1'b0;
							if (ct_counter == 3'd5) begin
								ct_counter <= 3'd0;
								if (ct_j == 4'd15) begin
									ct_jbuf <= ct_j;
									ct_ibuf <= ct_i;
									ct_j <= 4'd0;
									ct_i <= ct_i + 1;
								end else begin
									ct_jbuf <= ct_j;
									ct_ibuf <= ct_i;
									ct_j <= ct_j + 1;
								end
							end else begin
								ct_counter <= ct_counter + 1'b1;
							end
						
							ct_acc <= ct_acc + mult1 + mult2 + mult3;
							accum_counter <= accum_counter + 1'b1;
							ct_acc_buf <= ct_acc;
							
							state_ct <= S_CT2;
							
						end
						
						S_CT2: begin
							if (accum_counter == 3'd5) begin
								ct_acc <= 32'd0 + mult1 + mult2 + mult3;
								if (ct_ibuf[0] <= 1'b0) begin
									write_enable_a[2] <= 1'b1;
									write_data_a[2] <= (ct_acc_buf >> 5);
									
								end else if (ct_ibuf[0] <= 1'b1) begin
									write_enable_a[3] <= 1'b1;
									write_data_a[3] <= (ct_acc_buf >> 5);
									
								end
								accum_counter <= 1'b0;
							end else begin
								accum_counter <= accum_counter + 1'b1;
								ct_acc <= ct_acc + mult1 + mult2 + mult3;
							end
							
							ct_counter <= ct_counter + 1'b1;
							
							if(ct_ibuf == 4'd15 && ct_jbuf == 4'd15) begin
								state_ct <= S_CT3;
								
							end else begin
								state_ct <= S_CT1;
							end
						end
						
						S_CT3: begin
							write_enable_a[3] <= 1'b0;
							write_enable_a[2] <= 1'b0;
							write_data_a[3] <= 32'b0;
							write_data_a[2] <= 32'b0;
							state <= S_MA;
							state_ct <=S_CTL;
						end
						
					endcase
					
				end

				S_MA: begin 
				
					state_fs <= FS_0;
					state_cs <= S_CSL;
					///////////////////////////////////////////
					 // ---------- FS STATE MACHINE ----------
					 ///////////////////////////////////////////
					 case (state_fs)

						  FS_0: begin
								Ci <= 4'd1;
								state_fs <= FS_1;
						  end
						  
						  FS_1: begin
								Ci <= 4'd2;
								sprime_is_even <= 1'b1;
								first_run <= 1'b1;
								state_fs <= FS_RUN;
						  end
						  
						  FS_RUN: begin
								if (sprime_is_even) begin
									 sprime_even_buf <= SRAM_read_data;
									 sprime_is_even <= 1'd0;
									 write_enable_a[0] <= 1'd0;
								end else begin
									 write_enable_a[0] <= 1'd1;
									 write_data_a[0] <= {sprime_even_buf, SRAM_read_data};
									 sprime_is_even <= 1'd1;

									 if (Ci == 4'd3 && first_run)
										  first_run <= 1'b0;
									 else
										  sprime_index <= sprime_index + 7'd1;
								end

								if (Ci == 4'd15) begin
									 Ci <= 4'd0;
									 Ri <= Ri + 4'd1;
								end else begin
									 Ci <= Ci + 4'd1;
								end

								if (Ri == 4'd15 && Ci == 4'd15)
									 state_fs <= FS_L1;
						  end

						  FS_L1: begin
								sprime_even_buf <= SRAM_read_data;
								sprime_is_even <= 1'd0;
								write_enable_a[0] <= 1'd0;
								state_fs <= FS_L2;
						  end

						  FS_L2: begin
								write_enable_a[0] <= 1'b1;
								write_data_a[0] <= {sprime_even_buf, SRAM_read_data};
								sprime_index <= sprime_index + 1'b1;
								state_fs <= FS_L3;
						  end

						  FS_L3: begin
								write_enable_a[0] <= 1'b0;
								// finished FS
								state_fs <= FS_DONE;
								// reset FS counters
								Ri <= 4'd0;
								Ci <= 4'd0;
								sprime_index <= 7'd0;
						  end

						  FS_DONE: begin
								// idle permanently
						  end

					 endcase



					 ///////////////////////////////////////////
					 // ---------- CS STATE MACHINE ----------
					 ///////////////////////////////////////////
					 case (state_cs)

						  S_CSL: begin
								cs_counter <= cs_counter + 1'b1;
								state_cs <= S_CS1;
						  end
						  
						  S_CS1: begin
								write_enable_b <= 1'b0;
								
								if (cs_counter == 3'd5) begin
									 cs_counter <= 3'd0;
									 if (ct_j == 4'd15) begin
										  cs_jbuf <= cs_j;
										  cs_ibuf <= cs_i;
										  cs_j <= 4'd0;
										  cs_i <= cs_i + 1;
									 end else begin
										  cs_jbuf <= cs_j;
										  cs_ibuf <= cs_i;
										  cs_j <= cs_j + 1;
									 end
								end else begin
									 cs_counter <= cs_counter + 1'b1;
								end
								
								cs_acc <= cs_acc + mult1 + mult2 + mult3;
								accum_counter2 <= accum_counter2 + 1'd1;
								cs_acc_buf <= cs_acc;

								state_cs <= S_CS2;
						  end
						  
						  S_CS2: begin
								if (accum_counter2 == 3'd5) begin
									 ct_acc <= mult1 + mult2 + mult3;

									 if (y_values) begin
										  write_enable_b <= 1'b1;
										  write_data_b[0] <= {prev_value, cs_acc_buf};
										  y_values <= 1'b0;
										  s_address <= s_address + 1'b1;
									 end else begin
										  prev_value <= cs_acc_buf;
										  y_values <= 1'b1;
									 end

									 accum_counter2 <= 1'b0;
								end else begin
									 accum_counter2 <= accum_counter2 + 1'b1;
									 cs_acc <= cs_acc + mult1 + mult2 + mult3;
								end

								cs_counter <= cs_counter + 1'b1;

								if (cs_ibuf == 4'd15 && cs_jbuf == 4'd15)
									 state_cs <= S_CS3;
								else
									 state_cs <= S_CS1;
						  end
						  
						  S_CS3: begin
								write_enable_b <= 1'b0;
								write_data_b[0] <= 32'd0;

								// CS finished → leave mega state
								state <= S_WS;
						  end

					 endcase
				end
				S_MB: begin end
					
					/*
					if(last_Megastate) begin
						state <= S_CT; 
					end else begin
						state <= S_MA;
						*/
						
				S_CS: begin 
					
					state_cs <= S_CSL;
					s_address <= 8'd129;
				
					case (state_cs)
						S_CSL: begin
							cs_counter <= cs_counter + 1'b1;
							
							state_cs <= S_CS1;
						end
						
						S_CS1: begin
							write_enable_b <= 1'b0;
							if (cs_counter == 3'd5) begin
								cs_counter <= 3'd0;
								if (ct_j == 4'd15) begin
									cs_jbuf <= cs_j;
									cs_ibuf <= cs_i;
									cs_j <= 4'd0;
									cs_i <= cs_i + 1;
								end else begin
									cs_jbuf <= cs_j;
									cs_ibuf <= cs_i;
									cs_j <= cs_j + 1;
								end
							end else begin
								cs_counter <= cs_counter + 1'b1;
							end
						
							cs_acc <= cs_acc + mult1 + mult2 + mult3;
							accum_counter2 <= accum_counter2 + 1'b1;
							cs_acc_buf <= cs_acc;
							
							state_cs <= S_CS2;
							
						end
						
						S_CS2: begin
							if (accum_counter2 == 3'd5) begin
								ct_acc <= 32'd0 + mult1 + mult2 + mult3;
								if (y_values == 1'b1) begin
									write_enable_b <= 1'b1;
									write_data_b[0] <= {prev_value, cs_acc_buf};
									y_values<= 1'b0;
									s_address <= s_address + 1'b1;
								end else begin
									prev_value <= cs_acc_buf;
									y_values <= 1'b1;
								end
								accum_counter2 <= 1'b0;
							end else begin
								accum_counter2 <= accum_counter2 + 1'b1;
								cs_acc <= cs_acc + mult1 + mult2 + mult3;
							end
							
							cs_counter <= cs_counter + 1'b1;
							
							if(cs_ibuf == 4'd15 && cs_jbuf == 4'd15) begin
								state_cs <= S_CS3;
							end else begin
								state_cs <= S_CS1;
							end
						end
						
						S_CS3: begin
							write_enable_b <= 1'b0;
							state <= S_WS;
							state_cs <=S_CSL;
							write_data_b[0] <= 32'b0;
						end
						
					endcase
				end
				
				S_WS: begin
					case (state_ws)
						WS_LOAD: begin
							 SRAM_we_n <= 1'b1;  
							
							 
							 state_ws <= WS_WRITE;
						end
						WS_WRITE: begin
							 if (!ws_first_cycle) begin
								  SRAM_we_n       <= 1'b0;
								  SRAM_write_data <= ws_data_buf;
								  write_counter   <= write_counter + 15'd1;
							 end
							 else begin
								  ws_first_cycle <= 1'b0;
								  SRAM_we_n <= 1'b1;
							 end
							 ws_data_buf <= read_data_b32[0][15:0];  
							 ws_ram_addr     <= ws_ram_addr_next;
							 ws_ram_addr_next <= ws_ram_addr_next + 8'd1;
							 if (ws_ram_addr == 8'd255) begin
								  state    <= S_IDLE_M2;
								  state_ws <= WS_LOAD;
							 end
						end
				   endcase
			
				end
		endcase
	end
end

always_comb begin
	 
	 SRAM_address = 18'd0;
	 
	 
	 op1_1 = 32'sd0;  op2_1 = 32'sd0;
    op1_2 = 32'sd0;  op2_2 = 32'sd0;
    op1_3 = 32'sd0;  op2_3 = 32'sd0;
	
    
	 case(state)

        S_IDLE_M2: begin
          
        end

        S_FS: begin
            
            SRAM_address = BASE_Y + ({Rb, Ri} << 7) + ({Rb, Ri} << 6) + {Cb,Ci};
				address_a[0] = sprime_index;
				
        end

        S_CT: begin
			
			case (state_ct)
				S_CTL: begin
					address_a[0] = ct_counter + ((ct_i << 2) + (ct_i << 1));
					address_b[0] = ct_counter + ((ct_i << 2) + (ct_i << 1)) + 1'b1;
					address_a[1] = ct_counter + ((ct_j << 2) + (ct_j << 1));
				end
				S_CT1: begin
					address_a[0] = ct_counter + ((ct_i << 2) + (ct_i << 1));
					address_b[0] = ct_counter + ((ct_i << 2) + (ct_i << 1)) + 1'b1;
					address_a[1] = ct_counter + ((ct_j << 2) + (ct_j << 1));
					
					address_a[2] = (ct_ibuf >> 1) + (ct_jbuf << 4) ;
					address_a[3] = (ct_ibuf >> 1) + (ct_jbuf << 4) ; 
				end
				S_CT2: begin
					address_a[0] = ct_counter + ((ct_i << 2) + (ct_i << 1));
					address_b[0] = ct_counter + ((ct_i << 2) + (ct_i << 1)) + 1'b1;
					address_a[1] = ct_counter + ((ct_j << 2) + (ct_j << 1));
				end
				S_CT3: begin
					address_a[2] = (ct_ibuf >> 1) + (ct_jbuf << 4) ;
					address_a[3] = (ct_ibuf >> 1) + (ct_jbuf << 4) ; 
				end
			endcase
			
			case (state_ct)
				S_CT1: begin
					op1_1 = $signed(read_data_a32[0][31:16]);
					op2_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});
					
					op1_2 = $signed(read_data_a32[0][15:0]);
					op2_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});

					op1_3 = $signed(read_data_b32[0][31:16]);
					op2_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
				end
				S_CT2: begin
					op1_1 = $signed(read_data_a32[0][15:0]);
					op2_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});

					op1_2 = $signed(read_data_b32[0][31:16]);
					op2_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});

					op1_3 = $signed(read_data_b32[0][15:0]);
					op2_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
				end
			endcase
				
        end
		  
		  S_MA: begin 
				SRAM_address = BASE_Y + ({Rb, Ri} << 7) + ({Rb, Ri} << 6) + {Cb,Ci};
                address_a[0] = sprime_index;
					 
				case (state_cs)
				S_CSL: begin
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_b[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
				end
				S_CS1: begin
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_b[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
					
					address_b[0] = s_address;
				end
				S_CS2: begin
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_b[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
				end
				S_CS3: begin
					address_b[0] = (ct_ibuf >> 1) + (ct_jbuf << 4) ;
					 
				end
			endcase
			
			case (state_cs)
				S_CS1: begin
					op1_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});
					op2_1 = $signed(read_data_a32[2]);
					
					op1_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});
					op2_2 = $signed(read_data_a32[3]);

					op1_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
					op2_3 = $signed(read_data_b32[2]);
				end
				S_CS2: begin
					op1_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});
					op2_1 = $signed(read_data_a32[3]);

					op1_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});
					op2_2 = $signed(read_data_a32[2]);

					op1_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
					op2_3 = $signed(read_data_b32[3]);
				end
			endcase
		  end
				 
		  S_MB: begin 
		  
		  end

        S_CS: begin
           
			  case (state_cs)
				S_CSL: begin
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_b[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
				end
				S_CS1: begin
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_b[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
					
					address_b[0] = s_address;
				end
				S_CS2: begin
					address_a[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_a[3] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1));
					address_b[2] = (cs_counter << 1) + ((cs_i << 2) + (cs_i << 1)) + 1'b1;
					address_a[1] = (cs_counter << 1) + ((cs_j << 2) + (cs_j << 1));
				end
				S_CS3: begin
					address_b[0] = (ct_ibuf >> 1) + (ct_jbuf << 4) ;
					 
				end
			endcase
			
			case (state_cs)
				S_CS1: begin
					op1_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});
					op2_1 = $signed(read_data_a32[2]);
					
					op1_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});
					op2_2 = $signed(read_data_a32[3]);

					op1_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
					op2_3 = $signed(read_data_b32[2]);
				end
				S_CS2: begin
					op1_1 = $signed({(read_data_a32[1][26] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][26:18]});
					op2_1 = $signed(read_data_a32[3]);

					op1_2 = $signed({(read_data_a32[1][17] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][17:9]});
					op2_2 = $signed(read_data_a32[2]);

					op1_3 = $signed({(read_data_a32[1][8] == 1'b1 ? 7'b1111111 : 7'b0), read_data_a32[1][8:0]});
					op2_3 = $signed(read_data_b32[3]);
				end
			endcase
			  
        end

        S_WS: begin
			 SRAM_address = write_counter;
			 case (state_ws)
						WS_LOAD: begin
							
							address_b[0] <= ws_ram_addr_next;
						end
						WS_WRITE: begin
							 address_b[0] <= ws_ram_addr;       
						end
			 endcase
		  end
		  default: begin
				SRAM_address = 18'd0;
				
		  end

    endcase
end

	 

endmodule
