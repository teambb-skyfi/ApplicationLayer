`default_nettype none

//---- Counter
// Register with count-up capability
module Counter
  #(parameter WIDTH = 4, DEFVAL = 0, INCR = 1)
  (input  logic [WIDTH-1:0] D,
   input  logic             load, up, clk, rst_n,
   output logic [WIDTH-1:0] Q);
  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) Q <= DEFVAL;
    else if (load)
        Q <= D;
    else if (up)
      Q <= Q + INCR;
  end
endmodule: Counter

//---- Register
// Stores a value in memory
module Register
  #(parameter WIDTH = 4, DEFVAL = 0)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, clk, rst_n,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) Q <= DEFVAL;
    else if (clear) Q <= DEFVAL;
    else if (en) Q <= D;
  end

endmodule : Register

//---- Shift Out Register
// Stores a value in memory that can be "shifted out" (MSB first)
// When shift is asserted, the stored value will be shifted by the width of the
// output so that the new bits can be outputted.
module ShiftOutRegister
  #(parameter INWIDTH = 32, OUTWIDTH = 8, DEFVAL = 0)
  (input  logic [INWIDTH-1:0]  D,
   input  logic                reload, shift, clk, rst_n,
   output logic [OUTWIDTH-1:0] Q);

  logic [INWIDTH-1:0] Q_internal;

  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) Q_internal <= DEFVAL;
    else if (reload) Q_internal <= D;
    else if (shift) Q_internal <= (Q_internal << OUTWIDTH);
  end

  assign Q = Q_internal[INWIDTH-1:INWIDTH-OUTWIDTH];

endmodule : ShiftOutRegister

//---- EdgeDetector
// True if a rise edge occurs
module EdgeDetector
  (input  logic data,
   input  logic clk, rst_n,
   output logic is_edge);
  logic data_last;
  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) data_last <= 1'b0;
    else data_last <= data;
  end
  assign is_edge = (data == 1'b1) && (data_last == 1'b0);
endmodule : EdgeDetector

//---- Shift In Register
// Stores a value in memory that can be shifted.
// When shift is asserted, the stored value will be shifted by the width of the
// input so that the new bits can be stored. There is no "overflow" checking.
module ShiftInRegister
  #(parameter INWIDTH = 8, OUTWIDTH = 32, DEFVAL = 0)
  (input  logic [INWIDTH-1:0]  D,
   input  logic                reload, shift, clk, rst_n,
   output logic [OUTWIDTH-1:0] Q);

  always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) Q <= DEFVAL;
    else if (reload) Q <= {{OUTWIDTH-INWIDTH{1'b0}}, D};
    else if (shift) Q <= (Q << INWIDTH) | D;
  end

endmodule : ShiftInRegister

// // the width must be 32 bits!!!!!
// crc8-dvbs2 polynomial 0xd5, initial value 0x00
function logic [7:0] crc8 (input logic [31:0] data);
	static logic  [0:255][7:0] crc8xtable = 
	{	8'h00, 8'hD5, 8'h7F, 8'hAA, 8'hFE, 8'h2B, 8'h81, 8'h54, 8'h29, 8'hFC, 8'h56, 8'h83, 8'hD7, 8'h02, 8'hA8, 8'h7D, 
		8'h52, 8'h87, 8'h2D, 8'hF8, 8'hAC, 8'h79, 8'hD3, 8'h06, 8'h7B, 8'hAE, 8'h04, 8'hD1, 8'h85, 8'h50, 8'hFA, 8'h2F, 
		8'hA4, 8'h71, 8'hDB, 8'h0E, 8'h5A, 8'h8F, 8'h25, 8'hF0, 8'h8D, 8'h58, 8'hF2, 8'h27, 8'h73, 8'hA6, 8'h0C, 8'hD9, 
		8'hF6, 8'h23, 8'h89, 8'h5C, 8'h08, 8'hDD, 8'h77, 8'hA2, 8'hDF, 8'h0A, 8'hA0, 8'h75, 8'h21, 8'hF4, 8'h5E, 8'h8B, 
		8'h9D, 8'h48, 8'hE2, 8'h37, 8'h63, 8'hB6, 8'h1C, 8'hC9, 8'hB4, 8'h61, 8'hCB, 8'h1E, 8'h4A, 8'h9F, 8'h35, 8'hE0, 
		8'hCF, 8'h1A, 8'hB0, 8'h65, 8'h31, 8'hE4, 8'h4E, 8'h9B, 8'hE6, 8'h33, 8'h99, 8'h4C, 8'h18, 8'hCD, 8'h67, 8'hB2, 
		8'h39, 8'hEC, 8'h46, 8'h93, 8'hC7, 8'h12, 8'hB8, 8'h6D, 8'h10, 8'hC5, 8'h6F, 8'hBA, 8'hEE, 8'h3B, 8'h91, 8'h44, 
		8'h6B, 8'hBE, 8'h14, 8'hC1, 8'h95, 8'h40, 8'hEA, 8'h3F, 8'h42, 8'h97, 8'h3D, 8'hE8, 8'hBC, 8'h69, 8'hC3, 8'h16, 
		8'hEF, 8'h3A, 8'h90, 8'h45, 8'h11, 8'hC4, 8'h6E, 8'hBB, 8'hC6, 8'h13, 8'hB9, 8'h6C, 8'h38, 8'hED, 8'h47, 8'h92, 
		8'hBD, 8'h68, 8'hC2, 8'h17, 8'h43, 8'h96, 8'h3C, 8'hE9, 8'h94, 8'h41, 8'hEB, 8'h3E, 8'h6A, 8'hBF, 8'h15, 8'hC0, 
		8'h4B, 8'h9E, 8'h34, 8'hE1, 8'hB5, 8'h60, 8'hCA, 8'h1F, 8'h62, 8'hB7, 8'h1D, 8'hC8, 8'h9C, 8'h49, 8'hE3, 8'h36, 
		8'h19, 8'hCC, 8'h66, 8'hB3, 8'hE7, 8'h32, 8'h98, 8'h4D, 8'h30, 8'hE5, 8'h4F, 8'h9A, 8'hCE, 8'h1B, 8'hB1, 8'h64, 
		8'h72, 8'hA7, 8'h0D, 8'hD8, 8'h8C, 8'h59, 8'hF3, 8'h26, 8'h5B, 8'h8E, 8'h24, 8'hF1, 8'hA5, 8'h70, 8'hDA, 8'h0F, 
		8'h20, 8'hF5, 8'h5F, 8'h8A, 8'hDE, 8'h0B, 8'hA1, 8'h74, 8'h09, 8'hDC, 8'h76, 8'hA3, 8'hF7, 8'h22, 8'h88, 8'h5D, 
		8'hD6, 8'h03, 8'hA9, 8'h7C, 8'h28, 8'hFD, 8'h57, 8'h82, 8'hFF, 8'h2A, 8'h80, 8'h55, 8'h01, 8'hD4, 8'h7E, 8'hAB, 
		8'h84, 8'h51, 8'hFB, 8'h2E, 8'h7A, 8'hAF, 8'h05, 8'hD0, 8'hAD, 8'h78, 8'hD2, 8'h07, 8'h53, 8'h86, 8'h2C, 8'hF9};
	
	logic [7:0] data_byte;
	logic [7:0] crc;
	crc = 8'h00;
	
	 data_byte = data[31:24] ^ crc;
	 crc = crc8xtable[data_byte] ^ 8'h0;

	 data_byte = data[23:16] ^ crc;
	 crc = crc8xtable[data_byte] ^ 8'h0;

	 data_byte = data[15:8] ^ crc;
	 crc = crc8xtable[data_byte] ^ 8'h0;

	 data_byte = data[7:0] ^ crc;
	 crc = crc8xtable[data_byte] ^ 8'h0;
	 return crc;
endfunction: crc8

function logic check_crc8(input logic [31:0] data, input logic [7:0] crc);
	return (crc8(data)==crc);
endfunction: check_crc8



module twoCycleEnable(input logic clk, rst_n, en,
	output logic twoCycle);
	
	enum {IDLE, S0} s, ns;

	always_ff @(posedge clk, negedge rst_n) begin
	if (~rst_n)
		s <= IDLE;
	else
		s <= ns;
	end

	always_comb begin
		twoCycle = 1'b0;
		case (s)
			IDLE: begin
				ns = IDLE;
				if(en) begin
					ns = S0;
					twoCycle = 1'b1;
				end
			
			end
			S0 : begin
				ns = IDLE;
				twoCycle = 1'b1;
			end

		endcase
	
	end



endmodule: twoCycleEnable


module LFSR_next
#(parameter SEED = 32'h8012_3457, WIDTH=32) 
	(input logic clk, rst_n, enable, 
	output logic [WIDTH-1:0] data1, data2);

	logic [31:0] tempData, tempData2;
	logic newBit, newBit2;      //31          //28           //1
	assign newBit = ((tempData>>1) ^ (tempData>>4) ) & 1'b1;

	always_ff @(posedge clk or negedge rst_n) begin
	  	if(~rst_n) begin
	  		tempData <= SEED;
	  	end else begin
	  		if(enable) 
	  			tempData <= {newBit, tempData[31:1]};
	  	end
  	end
  	assign data1 = tempData[WIDTH-1:0];

  	always_comb begin
  		tempData2 = {newBit, tempData[31:1]};
  		data2 = tempData2[WIDTH-1:0];
  	end
  	
endmodule: LFSR_next
// 32-bit LFSR with 
// feedback polynomial X31 + X28 + 1 
module LFSR
	#(parameter SEED = 32'h8012_3457, WIDTH=32) 
	(input logic clk, rst_n, enable, 
	output logic [WIDTH-1:0] data);

	logic [31:0] tempData;
	logic newBit;      //31          //28           //1
	assign newBit = ((tempData>>1) ^ (tempData>>4) ) & 1'b1;
	always_ff @(posedge clk or negedge rst_n) begin
	  	if(~rst_n) begin
	  		tempData <= SEED;
	  	end else begin
	  		if(enable) 
	  			tempData <= {newBit, tempData[31:1]};
	  	end
  	end
  	assign data = tempData[WIDTH-1:0];

endmodule: LFSR

module lfsr_test;
	logic clk, rst_n, enable;
	logic [31:0] data;

	LFSR_32 l0(.*);
	
	initial begin
	    clk = 1'b1;
	    forever #5 clk = ~clk;
  	end

  	assign enable = 1'b1;
  	// assign rst_n = 1'b1;
  	
  	initial begin
  		$monitor("data = %x", data);
  	end
  	initial begin
  		rst_n = 1'b0;
  		#3;
  		rst_n=1'b1;
  		#1000;
  		$finish;;
  	end

endmodule: lfsr_test

//---- HextoSevenSegment
module HextoSevenSegment
  (input  logic [3:0] hex,
   output logic [6:0] segment);

  always_comb begin
    case (hex)
      4'h0:    segment = 7'b1000000;
      4'h1:    segment = 7'b1111001;
      4'h2:    segment = 7'b0100100;
      4'h3:    segment = 7'b0110000;
      4'h4:    segment = 7'b0011001;
      4'h5:    segment = 7'b0010010;
      4'h6:    segment = 7'b0000010;
      4'h7:    segment = 7'b1111000;
      4'h8:    segment = 7'b0000000;
      4'h9:    segment = 7'b0011000;
      4'hA:    segment = 7'b0001000;
      4'hB:    segment = 7'b0000011;
      4'hC:    segment = 7'b1000110;
      4'hD:    segment = 7'b0100001;
      4'hE:    segment = 7'b0000110;
      4'hF:    segment = 7'b0001110;
      default: segment = 7'b1111111;
    endcase
  end
endmodule : HextoSevenSegment