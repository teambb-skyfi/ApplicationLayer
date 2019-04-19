`default_nettype none

module ChipInterface_rx(
	input  logic        CLOCK_50,
	input  logic [ 9:0] SW,
	input  logic [ 2:0] KEY,
	output logic [35:0] GPIO_0,
	input  logic [35:0] GPIO_1,
	output logic [ 9:0] LEDR,
	output logic [ 6:0] HEX5, HEX4, HEX1, HEX0);

	logic rst_n;
 	assign rst_n = KEY[0];
  
	logic clk;
	assign clk = CLOCK_50;

	localparam PULSE_CT = 7500;
	localparam N_MOD = 2;
	localparam L = 15000;
	localparam N_PKT = 8;
	localparam PRE_CT = 4;
	localparam DELTA = 4000; //TODO Could be reduced; likely not issue anyway


	logic [N_PKT-1:0] data_recv;
	logic start_rx, avail_rx;
	logic [1:0] err_code_rx;

	logic start_ENC_rx;
	logic avail_ENC_rx;
	logic [N_PKT-1:0] data_ENC_rx;

	logic [N_PKT-1:0] data_DEC_rx;
	logic avail_DEC_rx;
	logic error_DEC_rx;
	logic read_DEC_rx;  

	//node2
	receiver #(.N_PKT(N_PKT)) r0 ( .data_recv, .start(start_rx), 
		.avail(avail_rx), .err_code(err_code_rx), .start_ENC(start_ENC_rx),
		.avail_ENC(avail_ENC_rx), .data_ENC(data_ENC_rx), .data_DEC(data_DEC_rx),
		.avail_DEC(avail_DEC_rx), .error_DEC(error_DEC_rx), .read_DEC(read_DEC_rx), .*);

	logic enc_tx_pulse; //input
	logic enc_rx_pulse; //output
	assign GPIO_0[5] = enc_rx_pulse;
	assign enc_tx_pulse = GPIO_1[6];

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
	enc_rx (.clk, .rst_n, .data(data_ENC_rx), .start(start_ENC_rx), 
		.avail(avail_ENC_rx), .pulse(enc_rx_pulse));

	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
	dec_rx(.clk, .rst_n, .data(data_DEC_rx), .pulse(enc_tx_pulse),
		.read(read_DEC_rx), .avail(avail_DEC_rx), .error(error_DEC_rx));

	logic en_lfsr_rx;
	logic [31:0] data_expected_rx;
	
	LFSR_32 data_gen_rx (.clk, .rst_n, .enable(en_lfsr_rx), .data(data_expected_rx));
	assign en_lfsr_tx = 1'b0; //TODO: update this to send "real" data

endmodule: ChipInterface_rx