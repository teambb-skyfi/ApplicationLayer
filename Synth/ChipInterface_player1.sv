`default_nettype none

module ChipInterface_player1(
	input  logic        CLOCK_50,
	input  logic [ 9:0] SW,
	input  logic [ 2:0] KEY,
	output logic [35:0] GPIO_0,
	input  logic [35:0] GPIO_1,
	output logic [ 9:0] LEDR,
	output logic [ 6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);


	logic rst_n;
 	assign rst_n = KEY[0];
  
	logic clk;
	assign clk = CLOCK_50;

  	localparam PULSE_CT = 20;
  	localparam N_MOD = 2;
  	localparam L = 60;
  	localparam PRE_CT = 2;
	localparam N_PKT = 8;
	localparam DELTA = 15;
	localparam HISTORY_SIZE = 5;
	localparam TIMEOUT = ( (((2**N_MOD)*L)*(PRE_CT+(N_PKT/N_MOD))) + 5*HISTORY_SIZE);

	logic [N_PKT-1:0] data2send_p1;
	logic [N_PKT-1:0] data_expected_p1;
	logic expected_data_received_p1;
	logic twoCycle_p1;

	twoCycleEnable tc1(.clk, .rst_n, .en(expected_data_received_p1),
		.twoCycle(twoCycle_p1));

	LFSR_next #(.WIDTH(N_PKT)) datasend1(.clk, .rst_n, 
		.enable(twoCycle_p1), .data1(data2send_p1), .data2(data_expected_p1));

	logic start_ENC_p1;
	logic avail_ENC_p1;
	logic [N_PKT-1:0] data_ENC_p1;

	logic [N_PKT-1:0] data_DEC_p1;
	logic avail_DEC_p1;
	logic error_DEC_p1;
	logic read_DEC_p1;  

	player1 #(N_PKT, TIMEOUT) p1 (.data2send(data2send_p1),.data_expected(data_expected_p1), 
		.start_ENC(start_ENC_p1), .avail_ENC(avail_ENC_p1), .data_ENC(data_ENC_p1), 
		.data_DEC(data_DEC_p1), .avail_DEC(avail_DEC_p1), .error_DEC(error_DEC_p1), 
		.read_DEC(read_DEC_p1), .expected_data_received(expected_data_received_p1), .*);


	logic enc_p1_pulse, enc_p2_pulse;

	assign GPIO_0[5] = enc_p1_pulse; //output from encoder
	assign enc_p2_pulse = GPIO_1[6]; //input to decoder

	
	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_p1 (.clk, .rst_n, .data(data_ENC_p1), .start(start_ENC_p1), 
			.avail(avail_ENC_p1), .pulse(enc_p1_pulse));

	logic enc_p2_filter_pulse;
	digitalFilter #(HISTORY_SIZE) f1 (.clk, .rst_n, .pulse(enc_p2_pulse),
		.filteredPulse(enc_p2_filter_pulse));

	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_p1(.clk, .rst_n, .data(data_DEC_p1), .pulse(enc_p2_filter_pulse),
			.read(read_DEC_p1), .avail(avail_DEC_p1), .error(error_DEC_p1));

	logic [39:0] clk_count, received_count, goodput;
	always_ff @(posedge CLOCK_50 or negedge rst_n) begin : proc_statCollection
		if(~rst_n) begin
			speed <= 0;
			received_count <= 0;
			clk_count <= 0;
		end else begin
			clk_count <= clk_count+1;
			received_count <= expected_data_received_p2 ? received_count+1:received_count;
			goodput <= (received_count*(8*50*1000_000))/clk_count;
		end
	end

endmodule: ChipInterface_player1


