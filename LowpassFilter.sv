module LowpassFilter(input  logic clk, reset,
						input  logic [15:0] x,
						output logic [15:0] y);
	
	logic [15:0] h[174:0] = '{default:1'b0}; // Coefficients (175)
	
	initial begin
		$readmemb("QuantizedCoefficient.txt", h);	
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
				sumOut[n + 1] = (delay[n] * h[n+1]);
				shift = 174; //173 sums must shift
				while (shift != 0) begin
					sumOut[shift] = sumOut[shift - 1];
					shift = shift - 1; 
				end
			end
			
			if (delay[n] == 1) begin //flipflop delay/stageOut
				stageOut[n] = delay[n];
				delay[n] = stageOut[n - 1];
			end else if (stageOut[n] == 1) begin
				delay[n + 1] = stageOut[n];
				stageOut[n] = delay[n];
				n = n + 8'b0000001;
			end
			
			if (hold == 1) begin //initialization logic
				delay[0] = 1;
				sumOut[1] = sumOut[0];
				sumOut[0] = h[0] * x;
				hold = 0;
			end else begin
				delay[0] = x[0];
				sumOut[0] = h[0] * x;
			end
			y = sumOut[174];
		end
	end
	
	
	
endmodule