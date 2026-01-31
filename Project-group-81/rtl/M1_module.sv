
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_M1_state.h"

module M1_module (
   input  logic        Clock,
   input  logic        Resetn,
   input  logic        Start,
   output logic        Done,

   input  logic [15:0] SRAM_read_data,
   output logic [17:0] SRAM_address,
   output logic [15:0] SRAM_write_data,
   output logic        SRAM_we_n
);

M1_state_type state;

logic [7:0] U_regs [9:0];
logic [7:0] V_regs [9:0];
logic [7:0] Y_even, Y_odd;
logic signed [31:0] U_acc, V_acc;
logic [7:0] U_buff, V_buff; 

logic signed[31:0] R_even, G_even, B_even, R_odd, G_odd, B_odd;

logic signed [31:0] op1_1, op2_1, op1_2, op2_2, op1_3, op2_3, op1_4, op2_4;



logic signed [31:0] mult1, mult2, mult3, mult4;
logic signed [63:0] mult1Long, mult2Long, mult3Long, mult4Long;


logic [13:0] counter;
logic [13:0] line_threshold;
logic lof;
logic [2:0] locounter;

localparam Y_BASE   = 18'd0;
localparam U_BASE   = 18'd13824;
localparam V_BASE   = 18'd20736;
localparam RGB_BASE = 18'd220672;

assign mult1Long = op1_1 * op2_1;
assign mult2Long = op1_2 * op2_2;
assign mult3Long = op1_3 * op2_3;
assign mult4Long = op1_4 * op2_4;

assign mult1 = mult1Long[31:0];
assign mult2 = mult2Long[31:0];
assign mult3 = mult3Long[31:0];
assign mult4 = mult4Long[31:0];


always_comb begin

	op1_1 = 32'sd0;  op2_1 = 32'sd0;
   op1_2 = 32'sd0;  op2_2 = 32'sd0;
   op1_3 = 32'sd0;  op2_3 = 32'sd0;
   op1_4 = 32'sd0;  op2_4 = 32'sd0;

   SRAM_address = 18'd0;
	
	case (state)
		S_PL5: begin
			op1_1 = (U_regs[0]);
			op2_1 = 32'sd36;
			op1_2 =  (U_regs[1]);
			op2_2 = -32'sd98;
			op1_3 =  (U_regs[2]);
			op2_3 = -32'sd233;
			op1_4 =  (U_regs[3]);
			op2_4 = 32'sd528;
		end
		S_PL6: begin
			op1_1 =  (U_regs[4]);
			op2_1 = 32'sd1815;
			op1_2 =  (U_regs[5]);
			op2_2 = 32'sd1815;
			op1_3 =  (U_regs[6]);
			op2_3 = 32'sd528;
			op1_4 =  (U_regs[7]);
			op2_4 = -32'sd233;
		end
		S_PL7: begin
			op1_1 =  (U_regs[8]);
			op2_1 = -32'sd98;
			op1_2 =  (U_regs[9]);
			op2_2 = 32'sd36;
			//Mult3 and Mult 4 unused
		end
		S_PL8: begin
			op1_1 =  (V_regs[0]);
			op2_1 = 32'sd36;
			op1_2 =  (V_regs[1]);
			op2_2 = -32'sd98;
			op1_3 =  (V_regs[2]);
			op2_3 = -32'sd233;
			op1_4 =  (V_regs[3]);
			op2_4 = 32'sd528;
		end
		S_PL9: begin
			op1_1 =  (V_regs[4]);
			op2_1 = 32'sd1815;
			op1_2 =  (V_regs[5]);
			op2_2 = 32'sd1815;
			op1_3 =  (V_regs[6]);
			op2_3 = 32'sd528;
			op1_4 =  (V_regs[7]);
			op2_4 = -32'sd233;
		end
		S_C1: begin
			op1_1 =  (V_regs[8]);
			op2_1 = -32'sd98;
			op1_2 =  (V_regs[9]);
			op2_2 = 32'sd36;
			// FIRST EVEN COMPUTATION
			op1_3 =  (Y_even) - 32'sd16;
			op2_3 = 32'sd38142;
			op1_4 =  (V_buff) - 32'sd128;
			op2_4 = 32'sd52298;
		end
		S_C2: begin
			op1_1 =  (U_buff) - 32'sd128;
			op2_1 = -32'sd12845;
			op1_2 =  (V_buff) - 32'sd128;
			op2_2 = -32'sd26640;
			op1_3 =  (U_buff) - 32'sd128;
			op2_3 = 32'sd66093; 
			// FIRST ODD MULTIPLY
			op1_4 =  (Y_odd) - 32'sd16;
			op2_4 = 32'sd38142;
		end
		S_C3: begin
			op1_1 =  (V_acc) - 32'sd128;
			op2_1 = 32'sd52298;
			op1_2 =  (U_acc) - 32'sd128;
			op2_2 = -32'sd12845;
			op1_3 =  (V_acc) - 32'sd128;
			op2_3 = -32'sd26640;
			op1_4 =  (U_acc) - 32'sd128;
			op2_4 = 32'sd66093;
		end
		S_C4: begin
			op1_1 =  (U_regs[0]);
			op2_1 = 32'sd36;
			op1_2 =  (U_regs[1]);
			op2_2 = -32'sd98;
			op1_3 =  (U_regs[2]);
			op2_3 = -32'sd233;
			op1_4 =  (U_regs[3]);
			op2_4 = 32'sd528;
		end
		S_C5: begin
			op1_1 =  (U_regs[4]);
			op2_1 = 32'sd1815;
			op1_2 =  (U_regs[5]);
			op2_2 = 32'sd1815;
			op1_3 =  (U_regs[6]);
			op2_3 = 32'sd528;
			op1_4 =  (U_regs[7]);
			op2_4 = -32'sd233;
		end
		S_C6: begin
			op1_1 =  (U_regs[8]);
			op2_1 = -32'sd98;
			op1_2 =  (U_regs[9]);
			op2_2 = 32'sd36;
			//Mult3 and Mult 4 unused
		end
		S_C7: begin
			op1_1 =  (V_regs[0]);
			op2_1 = 32'sd36;
			op1_2 =  (V_regs[1]);
			op2_2 = -32'sd98;
			op1_3 =  (V_regs[2]);
			op2_3 = -32'sd233;
			op1_4 =  (V_regs[3]);
			op2_4 = 32'sd528;
		end
		S_C8: begin
			op1_1 =  (V_regs[4]);
			op2_1 = 32'sd1815;
			op1_2 =  (V_regs[5]);
			op2_2 = 32'sd1815;
			op1_3 =  (V_regs[6]);
			op2_3 = 32'sd528;
			op1_4 =  (V_regs[7]);
			op2_4 = -32'sd233;
		end
		S_L0: begin
			op1_1 =  (V_regs[8]);
			op2_1 = -32'sd98;
			op1_2 =  (V_regs[9]);
			op2_2 = 32'sd36;
			// FIRST EVEN COMPUTATION
			op1_3 =  (Y_even) - 32'sd16;
			op2_3 = 32'sd38142;
			op1_4 =  (V_buff) - 32'sd128;
			op2_4 = 32'sd52298;
		end
		S_L1: begin
			op1_1 =  (U_buff) - 32'sd128;
			op2_1 = -32'sd12845;
			op1_2 =  (V_buff) - 32'sd128;
			op2_2 = -32'sd26640;
			op1_3 =  (U_buff) - 32'sd128;
			op2_3 = 32'sd66093; 
			// FIRST ODD MULTIPLY
			op1_4 =  (Y_odd) - 32'sd16;
			op2_4 = 32'sd38142;
		end
		S_L2: begin
			op1_1 =  (V_acc) - 32'sd128;
			op2_1 = 32'sd52298;
			op1_2 =  (U_acc) - 32'sd128;
			op2_2 = -32'sd12845;
			op1_3 =  (V_acc) - 32'sd128;
			op2_3 = -32'sd26640;
			op1_4 =  (U_acc) - 32'sd128;
			op2_4 = 32'sd66093;
		end
		default: begin 
			op1_1 = 32'd0;
			op2_1 = 32'd0;
			op1_2 = 32'd0;
			op2_2 = 32'd0;
			op1_3 = 32'd0;
			op2_3 = 32'd0;
			op1_4 = 32'd0;
			op2_4 = 32'd0;
		end	
	endcase
	case(state)

      S_PL0: SRAM_address = counter;
      S_PL1: SRAM_address = U_BASE + (counter >> 1);
      S_PL2: SRAM_address = U_BASE + (counter >> 1) + 18'd1;
      S_PL3: SRAM_address = U_BASE + (counter >> 1) + 18'd2;

      S_PL4: SRAM_address = V_BASE + (counter >> 1);
      S_PL5: SRAM_address = V_BASE + (counter >> 1) + 18'd1;
      S_PL6: SRAM_address = V_BASE + (counter >> 1) + 18'd2;

      S_PL7: SRAM_address = U_BASE + 18'd2 + ((counter + 18'd1) >> 1);
      S_PL8: SRAM_address = V_BASE + 18'd2 + ((counter + 18'd1) >> 1);

      S_C1: SRAM_address = counter;

      S_C3: SRAM_address = RGB_BASE + ((counter - 14'd1) << 1) + (counter - 14'd1);
      S_C4: SRAM_address = RGB_BASE + (((counter - 14'd1) << 1) + (counter - 14'd1)) + 18'd1;
      S_C5: SRAM_address = RGB_BASE + (((counter - 14'd1) << 1) + (counter - 14'd1)) + 18'd2;

      S_C6: SRAM_address = U_BASE + 18'd2 + ((counter + 18'd1) >> 1);
      S_C7: SRAM_address = V_BASE + 18'd2 + ((counter + 18'd1) >> 1);
		
		S_L0: SRAM_address = counter;
		S_L2: SRAM_address = RGB_BASE + ((counter - 14'd1) << 1) + (counter - 14'd1);
      S_L3: SRAM_address = RGB_BASE + (((counter - 14'd1) << 1) + (counter - 14'd1)) + 18'd1;
      S_L4: SRAM_address = RGB_BASE + (((counter - 14'd1) << 1) + (counter - 14'd1)) + 18'd2;

      default: SRAM_address = 18'd0;
		
   endcase
	
end

always_comb begin
    // default
    SRAM_write_data = 16'd0;

    case (state)
        // first word of the 3-word write (even R,G)
        S_C3, S_L2: begin
            SRAM_write_data = { (R_even[31] ? 8'b0 : |R_even[30:23] ? 8'hFF : R_even[22:15]),
                                (G_even[31] ? 8'b0 : |G_even[30:23] ? 8'hFF : G_even[22:15]) };
        end

        // second word (even B, odd R)
        S_C4, S_L3: begin
            SRAM_write_data = { (B_even[31] ? 8'b0 : |B_even[30:23] ? 8'hFF : B_even[22:15]),
                                (R_odd[31]  ? 8'b0 : |R_odd[30:23]  ? 8'hFF : R_odd[22:15]) };
        end

        // third word (odd G,B)
        S_C5, S_L4: begin
            SRAM_write_data = { (G_odd[31] ? 8'b0 : |G_odd[30:23] ? 8'hFF : G_odd[22:15]),
                                (B_odd[31] ? 8'b0 : |B_odd[30:23] ? 8'hFF : B_odd[22:15]) };
        end

        default: SRAM_write_data = 16'd0;
    endcase
end








always_ff @(posedge Clock or negedge Resetn) begin
      if (!Resetn) begin
         state           <= S_IDLE_M1;
         SRAM_we_n       <= 1'b1;
         Done            <= 1'b0;
			R_even 			 <= 32'b0;
			G_even			 <= 32'b0;
			B_even			 <= 32'b0;
			G_odd				 <= 32'b0;
			R_odd				 <= 32'b0;
			B_odd				 <= 32'b0;
			counter			 <= 13'b0;
			line_threshold  <= 13'd91;
			lof             <= 1'b0;
			locounter       <= 3'b0;
			for (int i = 0; i < 10; i++) begin
            U_regs[i] <= 8'd0;
            V_regs[i] <= 8'd0;
         end
			Y_even			 <= 8'b0;
			Y_odd   			 <= 8'b0;
      end else begin
         case (state)
			
				// ---------------------------------------------------------
            // IDLE
            // ---------------------------------------------------------
            S_IDLE_M1: begin
               Done <= 1'b0;
               SRAM_we_n <= 1'b1;
					lof <= 1'b0;
					line_threshold <= 13'd91;
					locounter <= 3'b0;
               if (Start) begin
                  state <= S_PL0;
               end
            end

            // ---------------------------------------------------------
            // PRELOAD (PL0–PL9)
            // ---------------------------------------------------------
            S_PL0: begin
 
               state <= S_PL1;
            end

            S_PL1: begin
               
               state <= S_PL2;
            end

            S_PL2: begin
					Y_even <= SRAM_read_data[15:8];
               Y_odd  <= SRAM_read_data[7:0];
               
               state <= S_PL3;
            end

            S_PL3: begin
					U_regs[0] <= SRAM_read_data[15:8];
					U_regs[1] <= SRAM_read_data[15:8];
               U_regs[2] <= SRAM_read_data[15:8];
					U_regs[3] <= SRAM_read_data[15:8];
					U_regs[4] <= SRAM_read_data[15:8];
					U_regs[5] <= SRAM_read_data[7:0];
               
               state <= S_PL4;
					
            end

            S_PL4: begin
               U_regs[6] <= SRAM_read_data[15:8];
               U_regs[7] <= SRAM_read_data[7:0];
					
					U_acc <= 32'sd0;
					V_acc <= 32'sd0;
               
               state <= S_PL5;
            end

            S_PL5: begin
               U_regs[8] <= SRAM_read_data[15:8];
               U_regs[9] <= SRAM_read_data[7:0];
					
					U_acc <= U_acc + mult1 + mult2 + mult3 + mult4;
					
					counter <= counter + 13'b1;
               
               state <= S_PL6;
            end

            S_PL6: begin
               V_regs[0] <= SRAM_read_data[15:8];
					V_regs[1] <= SRAM_read_data[15:8];
					V_regs[2] <= SRAM_read_data[15:8];
					V_regs[3] <= SRAM_read_data[15:8];
					V_regs[4] <= SRAM_read_data[15:8];
               V_regs[5] <= SRAM_read_data[7:0];
					
					U_acc <= U_acc + mult1 + mult2 + mult3 + mult4;
					
					

               state <= S_PL7;
            end

            S_PL7: begin
               V_regs[6] <= SRAM_read_data[15:8];
               V_regs[7] <= SRAM_read_data[7:0];
               
					U_buff <= U_regs[4];
					V_buff <= V_regs[4];
					
					U_acc <= (U_acc + mult1 + mult2 + 32'sd2048) >> 12;
					
               state <= S_PL8;
            end

            S_PL8: begin
               V_regs[8] <= SRAM_read_data[15:8];
               V_regs[9] <= SRAM_read_data[7:0];
					
					V_acc <= mult1 + mult2 + mult3 + mult4;
               
               state <= S_PL9;
            end

            S_PL9: begin
               // Done preloading — go to common case loop
					U_regs[0] <= U_regs[1];
					U_regs[1] <= U_regs[2];
					U_regs[2] <= U_regs[3];
					U_regs[3] <= U_regs[4];
					U_regs[4] <= U_regs[5];
					U_regs[5] <= U_regs[6];
					U_regs[6] <= U_regs[7];
					U_regs[7] <= U_regs[8];
					U_regs[8] <= U_regs[9];
					U_regs[9] <= SRAM_read_data[15:8];
					
					V_acc <= V_acc + mult1 + mult2 + mult3 + mult4;
					
               state <= S_C1;
					
					R_even <= 32'd0;
					R_odd <= 32'd0;
					G_even <= 32'd0;
					G_odd <= 32'd0;
					B_even <= 32'd0;
					B_odd <= 32'd0;
            end

            // ---------------------------------------------------------
            // COMMON CASE (C1–C9) - continuous loop
            // ---------------------------------------------------------
             S_C1: begin
					V_regs[0] <= V_regs[1];
					V_regs[1] <= V_regs[2];
					V_regs[2] <= V_regs[3];
					V_regs[3] <= V_regs[4];
					V_regs[4] <= V_regs[5];
					V_regs[5] <= V_regs[6];
					V_regs[6] <= V_regs[7];
					V_regs[7] <= V_regs[8];
					V_regs[8] <= V_regs[9];
					if (!lof) 
						V_regs[9] <= (counter[0] == 1 ? SRAM_read_data[15:8]: SRAM_read_data[7:0]);
					  
					V_acc <= (V_acc + mult1 + mult2 + 32'sd2048) >> 12;
					R_even <= mult3 + mult4 + 32'sd16384;
					G_even <= mult3;
					B_even <= mult3;
					
					state <= S_C2;
				 end

				 S_C2: begin
					  
					  G_even <= G_even + mult1 + mult2 + 32'sd16384;
					  B_even <= B_even + mult3 + 32'sd16384;
					  
					  R_odd <= mult4;
					  G_odd <= mult4;
					  B_odd <= mult4;
					  
					  
					  SRAM_we_n <= 1'd0;
					  
					  state <= S_C3;
				 end

				 S_C3: begin
					Y_even <= SRAM_read_data[15:8];
					Y_odd <= SRAM_read_data[7:0];
					  
					R_odd <= R_odd + mult1 + 32'sd16384;
					G_odd <= G_odd + mult2+mult3+ 32'sd16384;
					B_odd <= B_odd + mult4+ 32'sd16384;
					
					
					U_acc  <= 32'sd0;
					V_acc  <= 32'sd0;
					  
					state <= S_C4;
				 end

				 S_C4: begin
				 
					U_acc <= mult1 + mult2 + mult3 + mult4;
					state <= S_C5;
					  
				 end

				 S_C5: begin
				 
					U_acc <= U_acc + mult1 + mult2 + mult3 + mult4;
					
					counter <= counter + 13'b1;
					
					SRAM_we_n <= 1'd1;

					state <= S_C6;
				 end

				 S_C6: begin
				 
						U_buff <= U_regs[4];
						V_buff <= V_regs[4];
						
						R_even <= 32'd0;
						R_odd <= 32'd0;
						G_even <= 32'd0;
						G_odd <= 32'd0;
						B_even <= 32'd0;
						B_odd <= 32'd0;
						
						U_acc <= (U_acc + mult1 + mult2 + 32'sd2048) >> 12;
						

					  state <= S_C7;
				 end

				 S_C7: begin
				 
					V_acc <= mult1 + mult2 + mult3 + mult4;
					  
					if (counter == line_threshold)
						lof <= 1'b1;
					if (lof)
						locounter <= locounter + 1'b1;
					
					state <= S_C8;
				 end

				 S_C8: begin

					U_regs[0] <= U_regs[1];
					U_regs[1] <= U_regs[2];
					U_regs[2] <= U_regs[3];
					U_regs[3] <= U_regs[4];
					U_regs[4] <= U_regs[5];
					U_regs[5] <= U_regs[6];
					U_regs[6] <= U_regs[7];
					U_regs[7] <= U_regs[8];
					U_regs[8] <= U_regs[9];
					if (!lof)
						U_regs[9] <= (counter[0] == 1 ? SRAM_read_data[15:8]: SRAM_read_data[7:0]);
	
					V_acc <= V_acc + mult1 + mult2 + mult3 + mult4;
					
					if (lof && locounter == 3'd5)begin
						state <= S_L0;
					end else begin
						state <= S_C1;	
					end
					
				 end
				
				 S_L0: begin
				 
					lof <= 1'b0;
					locounter <= 3'd0;
				 
					V_acc <= (V_acc + mult1 + mult2 + 32'sd2048) >> 12;
					R_even <= mult3 + mult4+ 32'sd16384;
					G_even <= mult3;
					B_even <= mult3;
			    
					state <= S_L1;
				 end
				 
				 S_L1: begin
				 
					G_even <= G_even + mult1 + mult2+ 32'sd16384;
					B_even <= B_even + mult3+ 32'sd16384;
					  
					R_odd <= mult4;
					G_odd <= mult4;
					B_odd <= mult4;
					
					SRAM_we_n <= 1'd0;
					  
					state <= S_L2;
				 end
				 
				 S_L2: begin
				 
					R_odd <= R_odd + mult1+ 32'sd16384;
					G_odd <= G_odd + mult2+mult3+ 32'sd16384;
					B_odd <= B_odd + mult4+ 32'sd16384;
			
		
					U_acc <= 32'sd0;
					V_acc <= 32'sd0;

					state <= S_L3;
				 
				 end
				 
				 S_L3: begin
		
					U_acc <= U_acc + mult1 + mult2 + mult3 + mult4;
					  
					state <= S_L4;
					
				 end
				 
				 S_L4: begin
			
					SRAM_we_n <= 1'd1;
					
					line_threshold <= line_threshold + 13'd96;
	
					if (counter == 14'd13824) begin
						state <= S_DONE;
						
					end else begin
						state <= S_PL0;
					end
					
				 end
				 
				 S_DONE: begin
					Done <= 1'b1;
				 end
				 
            // ---------------------------------------------------------
            default: state <= S_IDLE_M1;
         endcase
      end
   end

endmodule
