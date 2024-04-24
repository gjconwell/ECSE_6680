module testbench();

	logic        clk;
	logic 		reset;
	
	
	
	int fd;	//coefficients
	int fd2; //quantizedcoefficients
	int fd3; //approxcoefficients
	real data;
	int val;
	
   logic [15:0] in;
	logic [15:0] out;
	
	logic [31:0] vectornum, errors;
	logic [16:0] testvectors[399:0]; //400 clock cycles for impluse
	
	logic [15:0] temp = 16'b0000000000000000;
	
	initial begin
		fd = $fopen("Coefficient.txt", "r");
		fd2 = $fopen("QuantizedCoefficient.txt", "a");
		while (! $feof(fd)) begin
			$fscanf(fd, "%f\n", data);				
			val = $rtoi((data + 1)/0.000030517578125); //convert float to quantized integer from 2^16-1 to 0
			$fwrite(fd2, "%16b", 16'(val^temp)); //convert quantized back to floating point
			$fwrite(fd2, "\n");
		end
		$fclose(fd);
		$fclose(fd2);
	end
	
	
	// instantiate device to be tested
	LowpassFilter dut(clk, reset, in, out);

	// generate clock
	always
	begin
		clk=1; #5; clk=0; #5;
	end

	// at start of test, load vectors and pulse reset
	initial
	begin
		$readmemb("Impulse.tv", testvectors);
		vectornum = 0; errors = 0;
		reset = 1; # 10; reset <= 0;
	end

	// apply test vectors on rising edge of clk
	always @(posedge clk)
	begin
		#10; {reset, in} = testvectors[vectornum];
	end

	// check results on falling edge of clk
	always @(negedge clk)
	begin
		#6; vectornum = vectornum + 1;
		fd3 = $fopen("Output.txt", "a"); //write results to output file
		$fwrite(fd3, "%f", (real'(out)*0.000030517578125)-1); //convert quantized back to floating point
		$fwrite(fd3, "\n"); 
		$fclose(fd3);
	end
	
endmodule
