// Copyright 2024 Takashi Toyoshima <toyoshim@gmail.com>.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

module PSA(i_nRST, i_CLK, i_PON, i_nIORQ, i_nRD, i_nWR, i_ZA, i_ZD, i_FA, i_DIPSW, o_nSYSTEM_RD, o_nTIMER_CS, o_TIMER_GATE, o_nRAM_CS, o_nRAM_WR, o_nROM_CS, o_CA, o_CD, o_nLED);
	// from Z80
	input i_nRST;
	input i_CLK;
	input i_PON;
	input i_nIORQ;
	input i_nRD;
	input i_nWR;
	input [7:0] i_ZA;
	input [7:0] i_ZD;
	
	// from ROM Socket
	input [10:0] i_FA;
	
	// from DIPSW
	input [3:0] i_DIPSW;

	// to Z80 Socket
	output o_nSYSTEM_RD;

	// to 8253
	output o_nTIMER_CS;
	output [2:0] o_TIMER_GATE;
	
	// to RAM
	output o_nRAM_CS;
	output o_nRAM_WR;

	// to ROM
	output o_nROM_CS;

	// to CBUS
	output [10:0] o_CA;
	output [7:0] o_CD;
	
	// to LED
	output [1:0] o_nLED;
	
	reg r_STROBE;
	reg [7:0] r_REG2_CTRL;
	reg [7:0] r_REG1_ADDR;
	reg [7:0] r_REG0_DATA;
	reg [2:0] r_MODE;

	wire w_ADDR_0X;
	wire w_TIMER_IORQ;
	wire w_REGS_IORQ_WR;
	wire [2:0] w_REG_IORQ_WR;
	wire w_COPY;
	wire w_STROBE;
	wire w_MOVE;
	wire w_ENABLE_PCG;
	wire w_MODE_256;
	wire w_RAM_SELECT;

	assign w_ADDR_0X = i_ZA[7:4] == 4'b0000;
	assign w_TIMER_IORQ = w_ADDR_0X & (i_ZA[3:2] == 2'b11) & !i_nIORQ;
	assign w_REGS_IORQ_WR = w_ADDR_0X & (i_ZA[3:2] == 2'b00) & !i_nIORQ & !i_nWR;
	assign w_REG_IORQ_WR = {
		w_REGS_IORQ_WR & (i_ZA[1:0] == 2'b10),
		w_REGS_IORQ_WR & (i_ZA[1:0] == 2'b01),
		w_REGS_IORQ_WR & (i_ZA[1:0] == 2'b00)
	};
	assign w_COPY = r_REG2_CTRL[5];
	assign w_STROBE = r_REG2_CTRL[4];
	assign w_MOVE = !w_COPY & w_STROBE;

	assign w_ENABLE_PCG = !r_MODE[0];
	assign w_MODE_256 = r_MODE[2];
	assign w_RAM_SELECT = w_ENABLE_PCG & (w_MODE_256 | i_FA[10]) & !w_COPY & !w_STROBE;

	assign o_nSYSTEM_RD = i_nRD | w_TIMER_IORQ;
	
	assign o_nTIMER_CS = !w_TIMER_IORQ;
	assign o_TIMER_GATE = { r_REG2_CTRL[7:6], r_REG2_CTRL[3] };

	assign o_nRAM_CS = o_nRAM_WR & !w_RAM_SELECT;
	assign o_nRAM_WR = !w_STROBE | r_STROBE;
	
	assign o_nROM_CS = w_MOVE | w_RAM_SELECT;
	
	assign o_CA = w_STROBE ? { w_MODE_256 ? r_REG2_CTRL[2] : 1'b1, r_REG2_CTRL[1:0], r_REG1_ADDR } : i_FA;

	assign o_CD = (w_MOVE & !o_nRAM_WR) ? r_REG0_DATA : 8'bzzzzzzzz;
	
	assign o_nLED = { !r_MODE[2], !r_MODE[1] };

	always @(negedge i_nRST) begin
		if (!i_PON)
			r_MODE <= 3'b001;
		else case (r_MODE)
			3'b001: r_MODE <= 3'b010;
			3'b010: r_MODE <= 3'b100;
			default: r_MODE <= 3'b001;
		endcase
	end

	always @(posedge i_CLK) begin
		r_STROBE <= w_STROBE;
	end
	
	// GATE2, GATE1, COPY/MOVE, STROBE, GATE0, N/A(CA10), CA9, CA8
	always @(posedge i_CLK or negedge i_nRST) begin
		if (!i_nRST)
			r_REG2_CTRL <= 8'h00;
		else if (w_REG_IORQ_WR[2])
			r_REG2_CTRL <= i_ZD;
	end

	always @(posedge i_CLK or negedge i_nRST) begin
		if (!i_nRST)
			r_REG1_ADDR <= 8'h00;
		else if (w_REG_IORQ_WR[1])
			r_REG1_ADDR <= i_ZD;
	end

	always @(posedge i_CLK or negedge i_nRST) begin
		if (!i_nRST)
			r_REG0_DATA <= 8'h00;
		else if (w_REG_IORQ_WR[0])
			r_REG0_DATA <= i_ZD;
	end
	
endmodule
