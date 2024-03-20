// Copyright 2024 Takashi Toyoshima <toyoshim@gmail.com>.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

`timescale 1 ps/ 1 ps

module PSA_cgen();
	reg r_nRST;
	reg r_CLK;
	reg r_PON;
	reg r_nIORQ;
	reg r_nRD;
	reg r_nWR;
	reg [7:0] r_ZA;
	reg [7:0] r_ZD;
	reg [10:0] r_FA;
	reg [3:0] r_DIPSW;

	wire w_nSYSTEM_RD;
	wire w_nTIMER_CS;
	wire [2:0]  w_TIMER_GATE;
	wire w_nRAM_CS;
	wire w_nRAM_WR;
  wire w_nROM_CS;
	wire [10:0]  w_CA;
	wire [7:0]  w_CD;
	wire [1:0]  w_nLED;

	PSA dut (
		.i_nRST(r_nRST),
		.i_CLK(r_CLK),
		.i_PON(r_PON),
		.i_nIORQ(r_nIORQ),
		.i_nRD(r_nRD),
		.i_nWR(r_nWR),
		.i_ZA(r_ZA),
		.i_ZD(r_ZD),
		.i_FA(r_FA),
		.i_DIPSW(r_DIPSW),

		.o_nSYSTEM_RD(w_nSYSTEM_RD),
		.o_nTIMER_CS(w_nTIMER_CS),
		.o_TIMER_GATE(w_TIMER_GATE),
		.o_nRAM_CS(w_nRAM_CS),
		.o_nRAM_WR(w_nRAM_WR),
    .o_nROM_CS(w_nROM_CS),
		.o_CA(w_CA),
		.o_CD(w_CD),
		.o_nLED(w_nLED));

	task read_reg;
		input [7:0] addr;

		begin
			#10
			r_ZA <= addr;
			r_nIORQ <= 1'b0;
			r_nRD <= 1'b0;
			#1
			if (8'h0c <= addr && addr <= 8'h0f) begin
				if (w_nSYSTEM_RD != 1'b1)
					$display("nSYSTEM_RD: error");
				if (w_nTIMER_CS != 1'b0)
					$display("TIMER_CS: error");
			end else begin
				if (w_nSYSTEM_RD != 1'b0)
					$display("nSYSTEM_RD: error");
				if (w_nTIMER_CS != 1'b1)
					$display("TIMER_CS: error");
			end
			#9
			r_nIORQ <= 1'b1;
			r_nRD <= 1'b1;
		end
	endtask

	task write_reg;
		input [7:0] addr;
		input [7:0] value;

		begin
			#10
			r_ZA <= addr;
			r_ZD <= value;
			r_nIORQ <= 1'b0;
			r_nWR <= 1'b0;
			#10
			r_nIORQ <= 1'b1;
			r_nWR <= 1'b1;
		end
	endtask

	task reset;
		begin
			#10
			r_nRST <= 1'b0;
			#10
			r_nRST <= 1'b1;
		end
	endtask

	task test;
		begin
  		write_reg(8'h00, 8'hcd);
	  	write_reg(8'h01, 8'had);
			write_reg(8'h02, 8'h17);
			#5
			if (w_nROM_CS != 1'b1)
				$display("nROM_CS should be 1");
			if (w_nRAM_CS != 1'b0)
				$display("nRAM_CS should be 0");
			if (w_nRAM_WR != 1'b0)
				$display("nRAM_WR should be 0");
			if (w_CA != 11'h7ad)
				$display("wrong address selecrt");
			if (w_CD != 8'hcd)
				$display("wrong data selecrt");
			#15
			if (w_nROM_CS != 1'b1)
				$display("nROM_CS should be 1");
			if (w_nRAM_CS != 1'b1)
				$display("nRAM_CS should be back to 1");
			if (w_nRAM_WR != 1'b1)
				$display("nRAM_WR should be back to 1");
			if (w_CA != 11'h7ad)
				$display("wrong address selecrt");
			if (w_CD != 8'hcd)
				$display("wrong data selecrt");
		end
	endtask

	always #5 r_CLK = !r_CLK;

	initial begin
		$dumpfile("PSA_move.vcd");
		$dumpvars(0, dut);
		r_nRST <= 1'b0;
		r_PON <= 1'b0;
		r_CLK <= 1'b0;
		r_nRD <= 1'b1;
		r_ZA <= 8'h00;
		r_ZD <= 8'h00;
		r_FA <= 11'h000;
		r_DIPSW <= 4'h0;
		r_nIORQ <= 1'b1;
		r_nWR <= 1'b1;
		r_nRD <= 1'b1;
		#3
		r_PON <= 1'b1;
		#3
		r_nRST <= 1'b1;
		#10

		r_FA <= 11'h000;

		test();
		reset();
		test();
		reset();
		test();
	
		$finish;
	end                                                    
endmodule