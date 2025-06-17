
module sdram (
	clk_clk,
	reset_reset_n,
	sdram_address,
	sdram_byteenable_n,
	sdram_chipselect,
	sdram_writedata,
	sdram_read_n,
	sdram_write_n,
	sdram_readdata,
	sdram_readdatavalid,
	sdram_waitrequest,
	wire_addr,
	wire_ba,
	wire_cas_n,
	wire_cke,
	wire_cs_n,
	wire_dq,
	wire_dqm,
	wire_ras_n,
	wire_we_n,
	jtag_uart_0_chipselect,
	jtag_uart_0_address,
	jtag_uart_0_read_n,
	jtag_uart_0_readdata,
	jtag_uart_0_write_n,
	jtag_uart_0_writedata,
	jtag_uart_0_waitrequest);	

	input		clk_clk;
	input		reset_reset_n;
	input	[24:0]	sdram_address;
	input	[1:0]	sdram_byteenable_n;
	input		sdram_chipselect;
	input	[15:0]	sdram_writedata;
	input		sdram_read_n;
	input		sdram_write_n;
	output	[15:0]	sdram_readdata;
	output		sdram_readdatavalid;
	output		sdram_waitrequest;
	output	[12:0]	wire_addr;
	output	[1:0]	wire_ba;
	output		wire_cas_n;
	output		wire_cke;
	output		wire_cs_n;
	inout	[15:0]	wire_dq;
	output	[1:0]	wire_dqm;
	output		wire_ras_n;
	output		wire_we_n;
	input		jtag_uart_0_chipselect;
	input		jtag_uart_0_address;
	input		jtag_uart_0_read_n;
	output	[31:0]	jtag_uart_0_readdata;
	input		jtag_uart_0_write_n;
	input	[31:0]	jtag_uart_0_writedata;
	output		jtag_uart_0_waitrequest;
endmodule
