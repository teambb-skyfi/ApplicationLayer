`default_nettype none

module ChipInterface_tx(
	input  logic        CLOCK_50,
	input  logic [ 9:0] SW,
	input  logic [ 2:0] KEY,
	output logic [35:0] GPIO_0,
	input  logic [35:0] GPIO_1,
	output logic [ 9:0] LEDR,
	output logic [ 6:0] HEX5, HEX4,HEX3, HEX2, HEX1, HEX0);

	logic rst_n;
 	assign rst_n = KEY[0];
  
	logic clk;
	assign clk = CLOCK_50;

  	localparam PULSE_CT = 7500;
  	localparam N_MOD = 2;
  	localparam L = 15000;
  	localparam PRE_CT = 2;
	localparam N_PKT = 8;
	localparam DELTA = 4000;
	
	logic [N_PKT-1:0] data2send;
	
	logic start_tx, avail_tx;
	logic [1:0] err_code_tx;

	logic start_ENC_tx;
	logic avail_ENC_tx;
	logic [N_PKT-1:0] data_ENC_tx;

	logic [N_PKT-1:0] data_DEC_tx;
	logic avail_DEC_tx;
	logic error_DEC_tx;
	logic read_DEC_tx;  

	transmitter #(.N_PKT(N_PKT)) t0 (.start(1'b1), .avail(avail_tx), 
		.err_code(err_code_tx), .start_ENC(start_ENC_tx), .avail_ENC(avail_ENC_tx),
		.data_ENC(data_ENC_tx), .data_DEC(data_DEC_tx), .avail_DEC(avail_DEC_tx), 
		.error_DEC(error_DEC_tx), .read_DEC(read_DEC_tx), .*);

	//sent to receiver node
	logic enc_tx_pulse;
	assign GPIO_0[5] = enc_tx_pulse;

  	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_tx (.clk, .rst_n, .data(data_ENC_tx), .start(start_ENC_tx), 
			.avail(avail_ENC_tx), .pulse(enc_tx_pulse));

	//from receiver node
	logic enc_rx_pulse;
	assign enc_rx_pulse = GPIO_1[6];

	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_tx(.clk, .rst_n, .data(data_DEC_tx), .pulse(enc_rx_pulse),
			.read(read_DEC_tx), .avail(avail_DEC_tx), .error(error_DEC_tx));

	logic en_lfsr_tx;
	logic [31:0] data_expected_tx;
	LFSR_32 data_gen_tx (.clk, .rst_n, .enable(en_lfsr_tx), .data(data_expected_tx));

	// assign en_lfsr_tx = 1'b0; //TODO: update this to send "real" data
	assign en_lfsr_tx = ~KEY[2];
	assign data2send = data_expected_tx[7:0];
	
	logic [7:0] data_received;
	logic [7:0] data_received_DEC;	

	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			data_received_DEC <= 8'hff;
		else if(avail_DEC_tx)
			data_received_DEC <= data_DEC_tx;
	end

	always_comb begin : proc_display
		case({SW[2],SW[1],SW[0]})
			3'b000: data_received = data_received_DEC; //data_DEX_tx
			3'b001: data_received = data_expected_tx[7:0]; //value from lfsr 
			default: data_received = 8'hff;
			// 3'b010: data_received =/
		endcase
	end
		
	
	HextoSevenSegment h0 (data_received[3:0],HEX0);
	HextoSevenSegment h1 (data_received[7:4],HEX1);
endmodule: ChipInterface_tx


