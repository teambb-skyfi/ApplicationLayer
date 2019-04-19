`default_nettype none

// `define TIMEOUT_TICKS 32'hffff
// `define READY_PACKET 48'h1f_1f1f_1f1f_99
// `define ACK_PACKET 48'h2d_2d2d_2d2d_66
// `define NAK_PACKET 48'ha5_a5a5_a5a5_12
// `define ERRORS_ALLOWED 8

module receiver_test_one_packet;

	logic clk;
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
	end
	logic rst_n;


  	localparam PULSE_CT = 7500;
  	localparam N_MOD = 2;
  	localparam L = 15000;
  	localparam PRE_CT = 4;
	localparam N_PKT = 48;
	localparam DELTA = 1;
	

	logic [N_PKT-1:0] data2send;
	assign data2send = 48'h3c_123_feed_bac;
	logic start_tx, avail_tx;
	logic [1:0] err_code_tx;

	logic start_ENC_tx;
	logic avail_ENC_tx;
	logic [N_PKT-1:0] data_ENC_tx;

	logic [N_PKT-1:0] data_DEC_tx;
	logic avail_DEC_tx;
	logic error_DEC_tx;
	logic read_DEC_tx;  

	transmitter #(.N_PKT(N_PKT)) t0 (.start(start_tx), .avail(avail_tx), 
		.err_code(err_code_tx), .start_ENC(start_ENC_tx), .avail_ENC(avail_ENC_tx),
		.data_ENC(data_ENC_tx), .data_DEC(data_DEC_tx), .avail_DEC(avail_DEC_tx), 
		.error_DEC(error_DEC_tx), .read_DEC(read_DEC_tx), .*);


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

	receiver #(.N_PKT(N_PKT)) r0 ( .data_recv, .start(start_rx), 
		.avail(avail_rx), .err_code(err_code_rx), .start_ENC(start_ENC_rx),
		.avail_ENC(avail_ENC_rx), .data_ENC(data_ENC_rx), .data_DEC(data_DEC_rx),
		.avail_DEC(avail_DEC_rx), .error_DEC(error_DEC_rx), .read_DEC(read_DEC_rx), .*);


	logic enc_tx_pulse;
	logic enc_rx_pulse;

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_tx (.clk, .rst_n, .data(data_ENC_tx), .start(start_ENC_tx), 
			.avail(avail_ENC_tx), .pulse(enc_tx_pulse));

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_rx (.clk, .rst_n, .data(data_ENC_rx), .start(start_ENC_rx), 
			.avail(avail_ENC_rx), .pulse(enc_rx_pulse));

	//receives pulse from rx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_tx(.clk, .rst_n, .data(data_DEC_tx), .pulse(enc_rx_pulse),
			.read(read_DEC_tx), .avail(avail_DEC_tx), .error(error_DEC_tx));

	//receives pulse from tx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_rx(.clk, .rst_n, .data(data_DEC_rx), .pulse(enc_tx_pulse),
			.read(read_DEC_rx), .avail(avail_DEC_rx), .error(error_DEC_rx));

	initial begin
		rst_n = 0;

		start_tx = 1'b0;
		@(posedge clk);
		rst_n = 1;
		@(posedge clk);
		
		start_rx = 1;
		@(posedge clk);
		start_rx = 0;
		
		@(posedge avail_tx);
		@(posedge clk);		
		start_tx = 1;
		@(posedge clk);
		start_tx = 0;
		
		@(posedge (err_code_tx==2'b00))
		#100
		
		$finish;
	end

endmodule: receiver_test_one_packet

module multi_packet_test;
	logic clk;
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
	end
	logic rst_n;


  	localparam PULSE_CT = 7500;
  	localparam N_MOD = 2;
  	localparam L = 15000;
  	localparam PRE_CT = 4;
	localparam N_PKT = 48;
	localparam DELTA = 1;
	

	logic [N_PKT-1:0] data2send;
	// assign data2send = 48'h3c_123_feed_bac;
	logic start_tx, avail_tx;
	logic [1:0] err_code_tx;

	logic start_ENC_tx;
	logic avail_ENC_tx;
	logic [N_PKT-1:0] data_ENC_tx;

	logic [N_PKT-1:0] data_DEC_tx;
	logic avail_DEC_tx;
	logic error_DEC_tx;
	logic read_DEC_tx;  

	transmitter #(.N_PKT(N_PKT)) t0 (.start(start_tx), .avail(avail_tx), 
		.err_code(err_code_tx), .start_ENC(start_ENC_tx), .avail_ENC(avail_ENC_tx),
		.data_ENC(data_ENC_tx), .data_DEC(data_DEC_tx), .avail_DEC(avail_DEC_tx), 
		.error_DEC(error_DEC_tx), .read_DEC(read_DEC_tx), .*);


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

	receiver #(.N_PKT(N_PKT)) r0 ( .data_recv, .start(start_rx), 
		.avail(avail_rx), .err_code(err_code_rx), .start_ENC(start_ENC_rx),
		.avail_ENC(avail_ENC_rx), .data_ENC(data_ENC_rx), .data_DEC(data_DEC_rx),
		.avail_DEC(avail_DEC_rx), .error_DEC(error_DEC_rx), .read_DEC(read_DEC_rx), .*);


	logic enc_tx_pulse;
	logic enc_rx_pulse;

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_tx (.clk, .rst_n, .data(data_ENC_tx), .start(start_ENC_tx), 
			.avail(avail_ENC_tx), .pulse(enc_tx_pulse));

	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_rx (.clk, .rst_n, .data(data_ENC_rx), .start(start_ENC_rx), 
			.avail(avail_ENC_rx), .pulse(enc_rx_pulse));

	//receives pulse from rx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_tx(.clk, .rst_n, .data(data_DEC_tx), .pulse(enc_rx_pulse),
			.read(read_DEC_tx), .avail(avail_DEC_tx), .error(error_DEC_tx));

	//receives pulse from tx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_rx(.clk, .rst_n, .data(data_DEC_rx), .pulse(enc_tx_pulse),
			.read(read_DEC_rx), .avail(avail_DEC_rx), .error(error_DEC_rx));


	task transfer_one_packet(logic [31:0] data, logic [7:0] crc8);
		start_rx = 1;
		@(posedge clk);
		start_rx = 0;
		@(posedge avail_tx);
		@(posedge clk);		
		data2send = {8'h3c, data, crc8};
		start_tx = 1;
		@(posedge clk);
		start_tx = 0;
		@(posedge (err_code_tx==2'b00));
		// assert()
	endtask: transfer_one_packet

	task transfer_one_packet_bad_crc(logic [31:0] data, logic [7:0] crc8);
		start_rx = 1;
		@(posedge clk);
		start_rx = 0;
		@(posedge avail_tx);
		@(posedge clk);		
		data2send = {8'h3c, data, 8'h00};
		start_tx = 1;
		@(posedge clk);
		start_tx = 0;
		@(posedge (err_code_tx!=2'b11));
		// assert()
	endtask: transfer_one_packet_bad_crc	


	initial begin
		$monitor("err_code=%b",err_code_rx);
	end

	initial begin
		

		rst_n = 0;
		start_tx = 1'b0;
		start_rx = 1'b0;
		
		@(posedge clk);
		rst_n = 1;
		@(posedge clk);
		


		transfer_one_packet(32'h12345678, crc8(32'h12345678));		
		#100;
		
		transfer_one_packet(32'h0feedbac, crc8(32'h0feedbac));	
		#100;
		
		transfer_one_packet(32'h0feedbac, crc8(32'h0feedbac));
		#100;
		
		$finish;
	end
endmodule: multi_packet_test



module multi_node_random_test;
	logic clk;
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
	end
	logic rst_n;

  	localparam PULSE_CT = 7500;
  	localparam N_MOD = 2;
  	localparam L = 15000;
  	localparam PRE_CT = 4;
	localparam N_PKT = 48;
	localparam DELTA = 1;
	

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

	//node 1
	//transmitter is always ready to send
	transmitter #(.N_PKT(N_PKT)) t0 (.start(1'b1), .avail(avail_tx), 
		.err_code(err_code_tx), .start_ENC(start_ENC_tx), .avail_ENC(avail_ENC_tx),
		.data_ENC(data_ENC_tx), .data_DEC(data_DEC_tx), .avail_DEC(avail_DEC_tx), 
		.error_DEC(error_DEC_tx), .read_DEC(read_DEC_tx), .*);


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

	logic enc_tx_pulse;
	logic enc_rx_pulse;

	//node 1
	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_tx (.clk, .rst_n, .data(data_ENC_tx), .start(start_ENC_tx), 
			.avail(avail_ENC_tx), .pulse(enc_tx_pulse));

	//node 2
	Encoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT))
		enc_rx (.clk, .rst_n, .data(data_ENC_rx), .start(start_ENC_rx), 
			.avail(avail_ENC_rx), .pulse(enc_rx_pulse));

	//node 1
	//receives pulse from rx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_tx(.clk, .rst_n, .data(data_DEC_tx), .pulse(enc_rx_pulse),
			.read(read_DEC_tx), .avail(avail_DEC_tx), .error(error_DEC_tx));

	//node 2
	//receives pulse from tx's encoder
	Decoder #(.PULSE_CT(PULSE_CT), .N_MOD(N_MOD), .L(L), .N_PKT(N_PKT), .PRE_CT(PRE_CT), .DELTA(DELTA))
		dec_rx(.clk, .rst_n, .data(data_DEC_rx), .pulse(enc_tx_pulse),
			.read(read_DEC_rx), .avail(avail_DEC_rx), .error(error_DEC_rx));

	logic en_lfsr_rx,en_lfsr_tx;
	logic [31:0] data_expected_rx;
	logic [31:0] data_expected_tx;
	
	LFSR_32 data_gen_tx (.clk, .rst_n, .enable(en_lfsr_tx), .data(data_expected_tx));
	LFSR_32 data_gen_rx (.clk, .rst_n, .enable(en_lfsr_rx), .data(data_expected_rx));

	task transfer_one_packet(logic [31:0] data, logic [7:0] crc8);
		start_rx = 1;
		@(posedge clk);
		start_rx = 0;
		@(posedge avail_tx);
		@(posedge clk);		
		data2send = {8'h3c, data, crc8};
		start_tx = 1;
		@(posedge clk);
		start_tx = 0;
		@(posedge (err_code_tx==2'b00));
		correctness_check: assert(data_DEC_rx[39:8] == data_expected_rx) begin
			$display("packet correctly received");
		end else begin
			$display("packet incorrectly received");
		end
		en_lfsr_rx = 1'b1;
		en_lfsr_tx = 1'b1;
		@(posedge clk);
		en_lfsr_rx = 1'b0;
		en_lfsr_tx = 1'b0;
		
		// assert()
	endtask: transfer_one_packet

	initial begin
		rst_n = 0;
		start_rx = 1'b0;
		en_lfsr_rx = 1'b0;
		en_lfsr_tx = 1'b0;
		
		@(posedge clk);
		rst_n = 1;
		@(posedge clk);
	
		for (int i=0; i<20; i+=1) begin
			transfer_one_packet(data_expected_tx, crc8(data_expected_tx));		
			#100;
		end
		// transfer_one_packet(data_expected_tx, crc8(data_expected_tx));		
		// #100;
		// transfer_one_packet(data_expected_tx, crc8(data_expected_tx));		
		// #100;
		$finish;

	end



endmodule: multi_node_random_test



