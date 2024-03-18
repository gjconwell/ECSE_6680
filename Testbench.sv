module testbench();

	logic        clk;
	logic 		reset;
	int fd;
	
   logic [15:0] in;
	logic [15:0] out;
	
	logic [31:0] vectornum, errors;
	logic [16:0] testvectors[399:0]; //400 clock cycles for impluse

	// instantiate device to be tested
	FirLowpass dut(clk, reset, in, out);

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
		fd = $fopen("Output.txt", "a"); //write results to output file
		$fwrite(fd, "%f", (real'(out)*0.000030517578125)-1); //convert quantized back to floating point
		$fwrite(fd, "\n"); 
		$fclose(fd);
	end
	
endmodule
