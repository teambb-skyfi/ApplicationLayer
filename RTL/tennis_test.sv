`default_nettype none

module tennis_test_one_packet;

	logic clk;
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
	end
	logic rst_n;

  	localparam PULSE_CT = 20;
  	localparam N_MOD = 2;
  	localparam L = 60;
  	localparam PRE_CT = 2;
	localparam N_PKT = 8;
	localparam DELTA = 15;
	localparam HISTORY_SIZE = 20;
	localparam TIMEOUT = ( (((2**N_MOD)*L)*(PRE_CT+(N_PKT/N_MOD))) + 5*HISTORY_SIZE);
	
	logic [N_PKT-1:0] data2send_p1, data2send_p2;
	logic [N_PKT-1:0] data_expected_p1, data_expected_p2;
	logic expected_data_received_p1, expected_data_received_p2;

	assign data2send_p1 = 8'h42;
	assign data2send_p2 = 8'h8f;

	assign data_expected_p1 = 8'h8f;
	assign data_expected_p2 = 8'h42;
	
	
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


	logic [N_PKT-1:0] data_recv;
	logic start_p2, avail_p2;
	logic [1:0] err_code_p2;

	logic start_ENC_p2;
	logic avail_ENC_p2;
	logic [N_PKT-1:0] data_ENC_p2;

	logic [N_PKT-1:0] data_DEC_p2;
	logic avail_DEC_p2;
	logic error_DEC_p2;
	logic read_DEC_p2;  

	player2 #(N_PKT,TIMEOUT) p2 (.data2send(data2send_p2),.data_expected(data_expected_p2), 
		.start_ENC(start_ENC_p2), .avail_ENC(avail_ENC_p2), .data_ENC(data_ENC_p2), 
		.data_DEC(data_DEC_p2), .avail_DEC(avail_DEC_p2), .error_DEC(error_DEC_p2), 
		.read_DEC(read_DEC_p2),.expected_data_received(expected_data_received_p2), .*);


	logic enc_p1_pulse;
	logic enc_p2_pulse;

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_p1 (.clk, .rst_n, .data(data_ENC_p1), .start(start_ENC_p1), 
			.avail(avail_ENC_p1), .pulse(enc_p1_pulse));

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_p2 (.clk, .rst_n, .data(data_ENC_p2), .start(start_ENC_p2), 
			.avail(avail_ENC_p2), .pulse(enc_p2_pulse));

	//receives pulse from p2's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_p1(.clk, .rst_n, .data(data_DEC_p1), .pulse(enc_p2_pulse),
			.read(read_DEC_p1), .avail(avail_DEC_p1), .error(error_DEC_p1));

	//receives pulse from p1's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_p2(.clk, .rst_n, .data(data_DEC_p2), .pulse(enc_p1_pulse),
			.read(read_DEC_p2), .avail(avail_DEC_p2), .error(error_DEC_p2));

	initial begin
		rst_n = 0;

		@(posedge clk);
		rst_n = 1;
		@(posedge clk);
		
		
		
		#100000;
		
		$finish;
	end

endmodule: tennis_test_one_packet



module tennis_test_LFSR;

	logic clk;
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
	end
	logic rst_n;

  	localparam PULSE_CT = 20;
  	localparam N_MOD = 2;
  	localparam L = 60;
  	localparam PRE_CT = 2;
	localparam N_PKT = 8;
	localparam DELTA = 15;
	localparam HISTORY_SIZE = 20;
	localparam TIMEOUT = ( (((2**N_MOD)*L)*(PRE_CT+(N_PKT/N_MOD))) + 5*HISTORY_SIZE);
	
	logic [N_PKT-1:0] data2send_p1, data2send_p2;
	logic [N_PKT-1:0] data_expected_p1, data_expected_p2;
	logic expected_data_received_p1, expected_data_received_p2;
	logic twoCycle_p1, twoCycle_p2;

	twoCycleEnable tc1(.clk, .rst_n, .en(expected_data_received_p1),
		.twoCycle(twoCycle_p1));

	twoCycleEnable tc2(.clk, .rst_n, .en(expected_data_received_p2),
		.twoCycle(twoCycle_p2));

	//node1
	LFSR_next #(.WIDTH(N_PKT)) datasend1(.clk, .rst_n, 
		.enable(twoCycle_p1), .data1(data2send_p1), .data2(data_expected_p1));

	//node2
	LFSR_next #(.SEED(32'h02468AF), .WIDTH(N_PKT)) datasend2 (.clk, .rst_n,
		.enable(twoCycle_p2), .data1(data2send_p2), .data2(data_expected_p2) ); 

	
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


	logic [N_PKT-1:0] data_recv;
	logic start_p2, avail_p2;
	logic [1:0] err_code_p2;

	logic start_ENC_p2;
	logic avail_ENC_p2;
	logic [N_PKT-1:0] data_ENC_p2;

	logic [N_PKT-1:0] data_DEC_p2;
	logic avail_DEC_p2;
	logic error_DEC_p2;
	logic read_DEC_p2;  

	player2 #(N_PKT,TIMEOUT) p2 (.data2send(data2send_p2),.data_expected(data_expected_p2), 
		.start_ENC(start_ENC_p2), .avail_ENC(avail_ENC_p2), .data_ENC(data_ENC_p2), 
		.data_DEC(data_DEC_p2), .avail_DEC(avail_DEC_p2), .error_DEC(error_DEC_p2), 
		.read_DEC(read_DEC_p2),.expected_data_received(expected_data_received_p2), .*);


	logic enc_p1_pulse;
	logic enc_p2_pulse;

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_p1 (.clk, .rst_n, .data(data_ENC_p1), .start(start_ENC_p1), 
			.avail(avail_ENC_p1), .pulse(enc_p1_pulse));

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_p2 (.clk, .rst_n, .data(data_ENC_p2), .start(start_ENC_p2), 
			.avail(avail_ENC_p2), .pulse(enc_p2_pulse));

	//receives pulse from p2's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_p1(.clk, .rst_n, .data(data_DEC_p1), .pulse(enc_p2_pulse),
			.read(read_DEC_p1), .avail(avail_DEC_p1), .error(error_DEC_p1));

	//receives pulse from p1's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_p2(.clk, .rst_n, .data(data_DEC_p2), .pulse(enc_p1_pulse),
			.read(read_DEC_p2), .avail(avail_DEC_p2), .error(error_DEC_p2));

	initial begin
		rst_n = 0;

		@(posedge clk);
		rst_n = 1;
		@(posedge clk);
		
		
		
		#1000000;
		
		$finish;
	end

endmodule: tennis_test_LFSR
