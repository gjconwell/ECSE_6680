module gzip(input logic clk, reset,
				input  logic [119:0] x,
				output logic [10:0] y [31:0]);

	logic [13:0] lz [31:0];
	lz77 lz77(clk, reset, x, lz);
	huffman huffman(clk, reset, lz, y);
endmodule

module lz77(input logic clk, reset,
				input  logic [119:0] x,
				output logic [13:0] dict [31:0]);

	int o; //offset iterator
	int io; //offset tracker
	int c; //copy iterator
	int s; //shifting operator
	
	logic append;
	logic [7:0] charend;
	logic [2:0] length [3:0];
	logic [2:0] offset [3:0]; 
	
	//14(112) size, with 6 (48) look ahead buffer
	logic [7:0] window[13:0];
	logic [119:0] temp; //temp input (x)
	//dictionary holds 31 letters (3 offset, 3 length, 8 letter)
	int dictFilled; //tracks what values are filled in dict
	
	always @(posedge clk) begin
		
		dictFilled = 0;
		
		//shifting temp values to leftside
		temp = x;
		while (temp[119:112] == 8'b00000000) begin //shift to left side
			temp = temp << 8;
		end 
		$display("temp: %b ", temp);
		
		//loading values into window
		c = 5;
		while (c >= 0) begin;
			window[c] = temp[119:112];
			temp = temp << 8;
			c = c - 1;
		end
		
		charend = 8'b00000001;
		while (charend != 0) begin
			length = '{default:3'b000};
			offset = '{default:3'b000};
			
			$display("start: %b", window[5]);
			
			//check for duplicates in window
			o = 6;
			io = 0;
			while (o != 14) begin
				if (window[o] == window[5]) begin
					$display("offsetrecord: %b", window[o]);
					o = o - 5;
					offset[io] = o[2:0];
					o = o + 5;
					io = io + 1;
				end
				o = o + 1;
			end
			
			//dictionary repetitions
			if (offset[0] != 3'b000) begin 
				for(int j = 0; j < io; j++) begin
					$display("j:%d io:%d", j, io);
					
					append = 1;
					while (append == 1) begin
						length[j] = length[j] + 1;
						append = 0;
						
						//compare in lookahead adder
						if (window[offset[j] + 5 - length[j]] == window[5 - length[j]]) begin
							append = 1;
						end
					end
				end
				
				//find longest repetition
				dict[dictFilled][13:11] = offset[0];
				dict[dictFilled][10:8] = length[0];
				dict[dictFilled][7:0] = window[5 - length[0]];
				for(int j = 0; j < 4; j++) begin
					if (length[j] > dict[dictFilled][10:8]) begin
						dict[dictFilled][13:11] = offset[j];
						dict[dictFilled][10:8] = length[j];
						dict[dictFilled][7:0] = window[5 - length[j]];
					end
				end
				
				$display("character: %b", window[5 - dict[dictFilled][10:8]]);
				charend = window[5 - dict[dictFilled][10:8]];
				$display("offset: %b length: %b", dict[dictFilled][13:11], dict[dictFilled][10:8]);
				
				dictFilled = dictFilled + 1;
			end else begin //letter is not found in window (add new dict)
				$display("nodict: %b", window[5]); //TODO: not always going to be window 5 will adjust for length
				dict[dictFilled][15:8] = 8'b0000000;
				dict[dictFilled][7:0] = window[5];
				dictFilled = dictFilled + 1;
			end
		
			//shifting the window
			for(int t = 0; t < (dict[dictFilled - 1][10:8] + 1); t++) begin
				$display("windowfirst: %b, windowsecond: %b", window[5], window[4]);
				$display("tripped");
				s = 13;
				while (s > 0) begin
					$display("%d %b <- %b", s, window[s], window[s-1]);
					window[s] = window[s-1];
					s = s - 1;
				end
				$display("%d %b", 0, window[0]);
				window[0] = temp[119:112];
				temp = temp << 8;
				
			end
			
		end
		
		for(int i = 0; i < 32; i++) begin
			$display("output %b", dict[i]);
		end
	end
endmodule

module huffman(input logic clk, reset,
					input  logic [13:0] x [31:0],
					output logic [10:0] y [31:0]);
					
	always @(negedge clk) 
		for(int j = 0; j < 32; j++) begin
			y[j][10:5] = x[j][13:8];
			
			//most frequent letters are on the top (faster access time)
			case(x[j][7:0])
				8'b00000000: y[j][4:0] = 5'b11111; // "
				8'b01100101: y[j][4:0] = 5'b00001; // e
				8'b01110011: y[j][4:0] = 5'b00010; // s
				8'b01101001: y[j][4:0] = 5'b00011; // i
				8'b01100001: y[j][4:0] = 5'b00100; // a
				8'b01110010: y[j][4:0] = 5'b00101; // r
				8'b01101110: y[j][4:0] = 5'b00110; // n
				8'b01110100: y[j][4:0] = 5'b00111; // t
				8'b01101111: y[j][4:0] = 5'b01000; // o
				8'b01101100: y[j][4:0] = 5'b01001; // l 
				8'b01100011: y[j][4:0] = 5'b01010; // c
				8'b01100100: y[j][4:0] = 5'b01011; // d
				8'b01110101: y[j][4:0] = 5'b01100; // u
				8'b01100111: y[j][4:0] = 5'b01101; // g 
				8'b01110000: y[j][4:0] = 5'b01110; // p
				8'b01101101: y[j][4:0] = 5'b01111; // m
				8'b01101000: y[j][4:0] = 5'b10000; // h
				8'b01100010: y[j][4:0] = 5'b10001; // b 
				8'b01111001: y[j][4:0] = 5'b10010; // y
				8'b01100110: y[j][4:0] = 5'b10011; // f
				8'b01110110: y[j][4:0] = 5'b10100; // v
				8'b01101011: y[j][4:0] = 5'b10101; // k 
				8'b01110111: y[j][4:0] = 5'b10110; // w
				8'b01111010: y[j][4:0] = 5'b10111; // z
				8'b01111000: y[j][4:0] = 5'b11000; // x
				8'b01101010: y[j][4:0] = 5'b11001; // j 
				8'b01110001: y[j][4:0] = 5'b11010; // q
			endcase
			
			$display("yah %b %b", y[j], x[j]);
		end 

endmodule