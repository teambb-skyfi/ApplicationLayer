`default_nettype none

`define ERRORS_ALLOWED 8
`define TIMEOUT 

//errcodes are 
//2'b00 -> success
//2'b01 -> 	UNDEFINED
//2'b10 -> failure
//2'b11 -> default

module player1
#(parameter N_PKT = 48, TIMEOUT=50)
(
	input logic clk, 
	input logic rst_n,
	
	//signals between testbench/OS
	input logic [N_PKT-1:0] data2send,//data from file
	input logic [N_PKT-1:0] data_expected,//data from file
	output logic expected_data_received,
	
	//signals between transceiver and oppm encoder
	output logic start_ENC,
	input logic avail_ENC,
	output logic [N_PKT-1:0] data_ENC,

	//signals between transceiver and oppm decoder
	input logic [N_PKT-1:0] data_DEC,
	input logic avail_DEC,
	input logic error_DEC,
	output logic read_DEC  
);
	logic clear_time_count, incr_time_count;
	logic [31:0] time_count;

	enum logic [3:0] { INIT,WAIT, A, B, C} state, next_state;
	
	always_comb begin
		data_ENC = data2send;
		incr_time_count = 1'b0;
		clear_time_count = 1'b0;
		read_DEC = 1'b0;
		start_ENC = 1'b0;

		expected_data_received = 1'b0;

		unique case(state)
			INIT: begin
				clear_time_count = 1'b1;
				next_state = WAIT;
			end
			WAIT: begin
				clear_time_count = 1'b1;
				next_state = WAIT;
				if(avail_ENC)
					next_state = A;
			end

			A: begin
				clear_time_count = 1'b1;
				start_ENC = 1'b1;
				next_state = B;

			end

			B: begin
				incr_time_count = 1'b1;
				next_state = B;
				if(avail_DEC && data_DEC==data_expected) begin
					read_DEC = 1'b1;
					expected_data_received = 1'b1;
					next_state = WAIT;
				end
				else if(~avail_ENC) begin
					incr_time_count = 1'b0;
					next_state = B;	
				end

				else if(avail_ENC && time_count<=TIMEOUT) begin
					incr_time_count = 1'b1;
					next_state = B;
				end
				else begin
					next_state = A;
				end
			end


		endcase
	end

	Counter #(.WIDTH(32)) Time_Counter (.load(clear_time_count), .D(0), .up(incr_time_count), .Q(time_count), .*);

	always_ff @(posedge clk or negedge rst_n) begin
    	if(~rst_n) begin
      		state <= INIT;
    	end else begin
      		state <= next_state;
    	end
	end


endmodule: player1

module player2
#(parameter N_PKT = 48, TIMEOUT=50)
(
	input logic clk, 
	input logic rst_n,
	
	//signals between testbench/OS
	input logic [N_PKT-1:0] data2send,//data from file
	input logic [N_PKT-1:0] data_expected,//data from file
	output logic expected_data_received,
	
	//signals between transceiver and oppm encoder
	output logic start_ENC,
	input logic avail_ENC,
	output logic [N_PKT-1:0] data_ENC,

	//signals between transceiver and oppm decoder
	input logic [N_PKT-1:0] data_DEC,
	input logic avail_DEC,
	input logic error_DEC,
	output logic read_DEC  
);
	logic clear_time_count, incr_time_count;
	logic [31:0] time_count;

	enum logic [3:0] { INIT,WAIT,WAIT0, A, B, C} state, next_state;
	
	always_comb begin
		data_ENC = data2send;
		incr_time_count = 1'b0;
		clear_time_count = 1'b0;
		read_DEC = 1'b0;
		expected_data_received = 1'b0;
		start_ENC = 1'b0;

		unique case(state)
			INIT: begin
				clear_time_count = 1'b1;
				next_state = WAIT0;
			end
			WAIT0: begin
				clear_time_count = 1'b1;
				if(avail_DEC && data_DEC==data_expected) begin
					read_DEC = 1'b1;
					expected_data_received = 1'b1;
					next_state = WAIT;
				end
			end

			WAIT: begin
				clear_time_count = 1'b1;
				next_state = WAIT;
				if(avail_ENC)
					next_state = A;
			end

			A: begin
				clear_time_count = 1'b1;
				start_ENC = 1'b1;
				next_state = B;

			end

			B: begin
				incr_time_count = 1'b1;
				next_state = B;
				if(avail_DEC && data_DEC==data_expected) begin
					read_DEC = 1'b1;
					expected_data_received = 1'b1;
					next_state = WAIT;
				end
				else if(~avail_ENC) begin
					incr_time_count = 1'b0;
					next_state=B;
				end
				else if(avail_ENC && time_count<=TIMEOUT) begin
					incr_time_count = 1'b1;
					next_state = B;
				end
				else begin
				 	next_state = A;
				end
			end


		endcase
	end

	Counter #(.WIDTH(32)) Time_Counter (.load(clear_time_count), .D(0), .up(incr_time_count), .Q(time_count), .*);

	always_ff @(posedge clk or negedge rst_n) begin
    	if(~rst_n) begin
      		state <= INIT;
    	end else begin
      		state <= next_state;
    	end
	end


endmodule: player2