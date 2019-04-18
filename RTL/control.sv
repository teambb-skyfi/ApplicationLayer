`default_nettype none

// crc11(2d2d) = 0x66
`define TIMEOUT_TICKS 32'h00ff_ffff
`define READY_PACKET 48'h1f_1f1f_1f1f_99
`define ACK_PACKET 48'h2d_2d2d_2d2d_66
`define NAK_PACKET 48'ha5_a5a5_a5a5_12
`define ERRORS_ALLOWED 8
// DATAPACKET  48'h3c_data_data_crc8(data)

//8 bits of PID + 32 bits of data + 8 bits of CRC8

//errcodes are 
//2'b00 -> success
//2'b01 -> 	UNDEFINED
//2'b10 -> failure
//2'b11 -> default

module transmitter
#(parameter N_PKT = 48)
(
	input logic clk, 
	input logic rst_n,
	
	//signals between  testbench/OS
	input logic [N_PKT-1:0] data2send,//data from file
	input logic start, //start transmission
	output logic avail, //free to perform transmission
	output logic [1:0] err_code, //successfully transmitted

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

	enum logic [3:0] { INIT, W0, W1, WAIT} state, next_state;
	
	logic incr_err_count;
	logic clear_err_count;
	logic [31:0] err_count;

	logic incr_time_count;
	logic clear_time_count;
	logic [31:0] time_count;
	
    logic ack_recv;
    logic nak_recv;
    logic ready_recv;

	always_comb begin : proc_nextStateGen
		clear_time_count = 1'b0;
		clear_err_count = 1'b0;
		incr_time_count = 1'b0;
		incr_err_count = 1'b0;
		avail = 1'b0;
		err_code= 2'b11;

		start_ENC = 1'b0;
		data_ENC = data2send;
		read_DEC = 1'b0;

		case(state)
			WAIT: begin //wait for ready and encoder avail signals
				clear_err_count = 1'b1;
				clear_time_count = 1'b1;
				next_state = (ready_recv & avail_ENC) ? INIT : WAIT;
			end

			INIT: begin
				avail = 1'b1;
				read_DEC = 1'b1;
				clear_err_count = 1'b1;
				clear_time_count = 1'b1;
				next_state = start ? W0 : INIT;
			end

			W0: begin
				start_ENC = 1'b1;
				next_state = W1;
				clear_time_count = 1'b1;
			end

			W1: begin
				incr_time_count = 1'b1;

				if(err_count > `ERRORS_ALLOWED) begin
					next_state = WAIT;
					err_code = 2'b10;
				end
				else if(time_count > `TIMEOUT_TICKS) begin
					incr_err_count = 1'b1;
					next_state = W0;
				end
				else if(nak_recv) begin
					incr_err_count = 1'b1;
					next_state = W0;
					read_DEC = 1'b1;
				end
				else if (ack_recv) begin
					next_state = WAIT;
					read_DEC =1'b1;
					err_code = 2'b00;
				end
				else begin
					next_state = W1;
				end

			end

		endcase
	
	end

	always_ff @(posedge clk or negedge rst_n) begin
    	if(~rst_n) begin
      		state <= WAIT;
    	end else begin
      		state <= next_state;
    	end
	end

    assign ready_recv = (data_DEC == `READY_PACKET)&& avail_DEC;
    assign ack_recv = (data_DEC == `ACK_PACKET) && avail_DEC;
	assign nak_recv = (data_DEC == `NAK_PACKET) && avail_DEC;

	Counter #(.WIDTH(32)) Err_Counter (.load(clear_err_count), .D(0), .up(incr_err_count), .Q(err_count), .*);
	Counter #(.WIDTH(32)) Time_Counter (.load(clear_time_count), .D(0), .up(incr_time_count), .Q(time_count), .*);
    
endmodule: transmitter


module receiver
#(parameter N_PKT = 48)
(
	input logic clk,
	input logic rst_n,

	//signals between receiver and testbench/OS
	output logic [N_PKT-1:0] data_recv,//data from file
	input logic start, //start process to recv 1 packet
	output logic avail, //receiver is available
	output logic [1:0] err_code, //successfully transmitted

	//signals between oppm encoder and receiver
	output logic start_ENC,
	input logic avail_ENC,
	output logic [N_PKT-1:0] data_ENC,

	//signals between oppm decoder and receiver
	input logic [N_PKT-1:0] data_DEC,
	input logic avail_DEC,
	input logic error_DEC,
	output logic read_DEC  
);

	logic incr_err_count;
	logic clear_err_count;
	logic [31:0] err_count;

	logic incr_time_count;
	logic clear_time_count;
	logic [31:0] time_count;
	
	enum logic [3:0] { INIT, SEND_ACK, SEND_NAK, SEND_READY, WAIT, R0} state, next_state;
	
	//TODO: fix this
	function logic checkCRC8(input logic [N_PKT-1:0] data);
    	return  (data[7:0] == 8'h0)? 1'b0 : 1'b1;  
  	endfunction

	always_comb begin : proc_nextStateGen
		
		clear_time_count = 1'b0;
		clear_err_count = 1'b0;
		incr_time_count = 1'b0;
		incr_err_count = 1'b0;
		avail = 1'b0;
		err_code= 2'b11;

		start_ENC = 1'b0;
		data_ENC = 0;
		read_DEC = 1'b0;
		data_recv = 0;

		case (state)
			WAIT: begin
				clear_time_count = 1'b1;
				clear_err_count = 1'b1;
				next_state = (avail_ENC) ? INIT : WAIT;

			end

			INIT: begin
				clear_time_count = 1'b1;
				clear_err_count = 1'b1;
				avail = 1'b1;
				next_state = (start) ? SEND_READY : INIT;				
			end

			SEND_READY: begin
				data_ENC = `READY_PACKET;
				start_ENC = 1'b1;
				next_state = R0;
			end

			R0: begin
				if(~avail_ENC) begin 
					next_state = R0;
					data_ENC = `READY_PACKET;
				end
				else if(err_count > `ERRORS_ALLOWED) begin
					next_state = WAIT;
					err_code = 2'b10;
				end
				else if(time_count > `TIMEOUT_TICKS) begin
					incr_err_count = 1'b1;
					next_state = SEND_READY;
					clear_time_count = 1'b1;
				end
				
				else if(avail_DEC && data_DEC[N_PKT-1:N_PKT-1-7]==8'h3c) begin
					clear_time_count = 1'b1;
					if(checkCRC8(data_DEC)) begin
						next_state = SEND_ACK;
						read_DEC = 1'b1;
					end
					else begin
						next_state = SEND_NAK;
						incr_err_count = 1'b1;
						read_DEC = 1'b1;
					end
				end
				else begin
					next_state = R0;
					incr_time_count = 1'b1;
				end

			end

			SEND_ACK: begin
				data_ENC = `ACK_PACKET;
				start_ENC = 1'b1;
				next_state = WAIT;
				err_code = 2'b00;
				data_recv=data_DEC;
			end

			SEND_NAK: begin
				next_state = R0;
				data_ENC = `NAK_PACKET;
				start_ENC = 1'b1;
			end

		endcase
	
	end

	always_ff @(posedge clk or negedge rst_n) begin
    	if(~rst_n) begin
      		state <= WAIT;
    	end else begin
      		state <= next_state;
    	end
	end

	Counter #(.WIDTH(32)) Err_Counter (.load(clear_err_count), .D(0), .up(incr_err_count), .Q(err_count), .*);
	Counter #(.WIDTH(32)) Time_Counter (.load(clear_time_count), .D(0), .up(incr_time_count), .Q(time_count), .*);
   
endmodule: receiver	



