
module FirLowpass(input  logic clk, reset,
						input  logic [15:0] x,
						output logic [15:0] y);
	
	int fd;
	real data;
	
	logic [15:0] h[174:0] = '{default:1'b0}; // Coefficients (175)
	logic [31:0] temp;
	logic [11:0] cnt = 0;
	int val;
	
	initial begin
		 fd = $fopen("Coefficient.txt", "r");
		 while (! $feof(fd)) begin
			  void'($fscanf(fd, "%f\n", data));				
			  val = $rtoi((data + 1)/0.000030517578125); //convert float to quantized integer from 2^16-1 to 0
			  h[cnt] = 16'(val ^ h[cnt]); //convert quantized integer to bits
			  cnt = cnt + 2'h01;
		 end
		 $fclose(fd);
	end
  
	logic delay[174:0] = '{default:1'b0}; //174 delays
	logic stageOut[175:0] = '{default:1'b0}; //175 pipeline stages
	logic [15:0] sumOut[174:0] = '{default:1'b0}; //174 sums
	logic [7:0] n = 0; //tap number
	int ini = 2;
	int hold = 0;
	int shift;
	
	always_ff @(posedge clk) begin //control cycles
		if (ini > 0) begin
			sumOut[0] = h[0] * x;
			ini = ini - 1;
			hold = 1;
		end else begin
			if (stageOut[n] == 1) begin //shifts values, and adds sums
				shift = 174; //173 sums must shift
				while (shift != 0) begin
					sumOut[shift] = sumOut[shift - 1];
					shift = shift - 1; 
				end
			end else if (delay[n] == 1) begin
				sumOut[n + 1] <= (delay[n] * h[n+1]);
				shift = 174; //173 sums must shift
				while (shift != 0) begin
					sumOut[shift] = sumOut[shift - 1];
					shift = shift - 1; 
				end
			end
			
			if (delay[n] == 1) begin //flipflop delay/stageOut
				stageOut[n] <= delay[n];
				delay[n] <= stageOut[n - 1];
			end else if (stageOut[n] == 1) begin
				delay[n + 1] <= stageOut[n];
				stageOut[n] <= delay[n];
				n = n + 1;
			end
			
			if (hold == 1) begin //initialization logic
				delay[0] <= 1;
				sumOut[1] <= sumOut[0];
				sumOut[0] = h[0] * x;
				hold = 0;
			end else begin
				delay[0] <= x;
				sumOut[0] = h[0] * x;
			end
			assign y = sumOut[174];
		end
	end
	
	
	
endmodule