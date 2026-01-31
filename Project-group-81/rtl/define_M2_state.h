`ifndef DEFINE_M2_STATE

typedef enum logic [2:0] {
   S_IDLE_M2,
	S_FS,
	S_CT,
	S_MA,
	S_MB,
	S_CS,
	S_WS,
   S_M2_DONE       
} M2_state_type;


`define DEFINE_M2_STATE 1
`endif