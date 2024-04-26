module testbench();

	logic        clk;
	logic 		reset;
	
	
	int i;
	int fd;	//input
	int fdout; //output
	logic [119:0] data;
	
   logic [119:0] in;
	logic [10:0] out [31:0] ;
	
	logic [31:0] vectornum;
	logic [119:0] testvectors[399:0]; //400 clock cycles for impluse
	
	initial begin
		
		fd = $fopen("input.txt", "r");
		i = 0;
		while (! $feof(fd)) begin
			$fscanf(fd, "%b\n", data);		
		   $display("%b ", data[7:0]);
			testvectors[i] = data;
			i = i + 1;
		end
		$fclose(fd);
	end
	
	
	// instantiate device to be tested
	gzip dut(clk, reset, in, out);

	// generate clock
	always
	begin
		clk=1; #5; clk=0; #5;
	end

	// at start of test, load vectors and pulse reset
	initial
	begin
		vectornum = 0;
		reset = 1; # 10; reset <= 0;
	end

	// apply test vectors on rising edge of clk
	always @(posedge clk)
	begin
		#10; in = testvectors[vectornum];
	end

	// check results on falling edge of clk
	always @(negedge clk)
	begin
		#6; vectornum = vectornum + 1;
		fdout = $fopen("output.txt", "a"); //write results to output file
		i = 0;
		while (out[i] != 5'b11111) begin
			$fwrite(fdout, "%b ", out[i]); //convert quantized back to floating point
			$fwrite(fdout, "\n"); 
			i = i + 1;
		end 
		$fclose(fdout);
	end
	
endmodule
