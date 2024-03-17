
module FirLowpass(input  logic clk, reset,
						input  logic [15:0] x,
						output shortreal y);
	
	int fd;
	real data;
	
	shortreal h[4:0]; // Coefficients (175)
	logic [15:0] temp = 0;
	logic [15:0] cnt = 0;
	
	initial begin
		 fd = $fopen("Testing.txt", "r");
		 while (! $feof(fd)) begin
			  void'($fscanf(fd, "%f\n", data));
			  h[cnt] = shortreal'(data); //need to convert from binary to floating binary
			  cnt = cnt + 2'h01;
		 end
		 $fclose(fd);
	end
  
	logic delay[7:0] = '{default:8'b00000000}; //will need 174 delays, 8 bits allows this
	logic stageOut[7:0] = '{default:1'b0}; //will need 175 stages //pipeline stages
	shortreal sumOut[7:0] = '{default:8'b00000000}; //will need 174 sums
	logic [2:0] n = 0; //tap number
	int ini = 2;
	int hold = 0;
	int shift;
	
	always_ff @(posedge clk) begin //control cycles
		//$display("top%0b%0b", stageOut[n], delay[n]);
		if (ini > 0) begin
			sumOut[0] = h[0] * x;
			ini = ini - 1;
			hold = 1;
		end else begin
			if (stageOut[n] == 1) begin
				shift = 4;
				while (shift != 0) begin
					sumOut[shift] = sumOut[shift - 1];
					shift = shift - 1; 
				end
			end else if (delay[n] == 1) begin
				sumOut[n + 1] <= (delay[n] * h[n+1]);
				shift = 4;
				while (shift != 0) begin
					sumOut[shift] = sumOut[shift - 1];
					shift = shift - 1; 
				end
			end
			
			if (delay[n] == 1) begin //flipflop delay/stage //could use delay as normal no need for 2D arrays
				stageOut[n] <= delay[n];
				delay[n] <= stageOut[n - 1];
			end else if (stageOut[n] == 1) begin
				delay[n + 1] <= stageOut[n];
				stageOut[n] <= delay[n];
				n = n + 1;
			end
			
			if (hold == 1) begin
				delay[0] <= 1;
				sumOut[1] <= sumOut[0];
				sumOut[0] = h[0] * x;
				hold = 0;
			end else begin
				delay[0] <= x;
				sumOut[0] = h[0] * x;
			end
			assign y = sumOut[4];
		end
	end
	
	
	
endmodule