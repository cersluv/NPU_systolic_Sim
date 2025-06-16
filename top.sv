module top (
	input logic            clk_clk,
   input logic            reset_reset_n,
	
	output logic [12:0]    wire_addr,
   output logic [1:0]     wire_ba,
   output logic           wire_cas_n,
   output logic           wire_cke,
   output logic           wire_cs_n,
   inout  logic [15:0]    wire_dq,
   output logic [1:0]     wire_dqm,
   output logic           wire_ras_n,
   output logic           wire_we_n);
	
   // Parámetros del tamaño de los registros y el acumulador.
   parameter DATA = 16;
   parameter ACC = 32;
	
	// Señales del controlador SDRAM
   logic [24:0] sdram_address;
   logic [1:0]  sdram_byteenable_n;
   logic        sdram_chipselect;
   logic [15:0] sdram_writedata;
   logic        sdram_read_n;
   logic        sdram_write_n;
   logic [15:0] sdram_readdata;
   logic        sdram_readdatavalid;
   logic        sdram_waitrequest;
	
	// Señales de la interfaz SDRAM
   logic        start_write;
   logic        start_read;
   logic [24:0] address;
   logic [15:0] write_data;
   logic [15:0] read_data;
   logic        operation_done;
   logic        busy;
	
	// Matrices
	logic signed [15:0] matrixA [0:7][0:7];
   logic signed [15:0] matrixB [0:7][0:7];
   logic signed [31:0] columnResults [0:7];

	// Controlador SDRAM
	sdram sdram_controller (
        .clk_clk(clk_clk),
        .reset_reset_n(reset_reset_n),
        .sdram_address(sdram_address),
        .sdram_byteenable_n(sdram_byteenable_n),
        .sdram_chipselect(sdram_chipselect),
        .sdram_writedata(sdram_writedata),
        .sdram_read_n(sdram_read_n),
        .sdram_write_n(sdram_write_n),
        .sdram_readdata(sdram_readdata),
        .sdram_readdatavalid(sdram_readdatavalid),
        .sdram_waitrequest(sdram_waitrequest),
        .wire_addr(wire_addr),
        .wire_ba(wire_ba),
        .wire_cas_n(wire_cas_n),
        .wire_cke(wire_cke),
        .wire_cs_n(wire_cs_n),
        .wire_dq(wire_dq),
        .wire_dqm(wire_dqm),
        .wire_ras_n(wire_ras_n),
        .wire_we_n(wire_we_n)
    );
	 
	 // Instanciación de la interfaz SDRAM
    sdram_SM sdramIf (
        .clk(clk_clk),
        .reset_n(reset_reset_n),
        .start_write(start_write),
        .start_read(start_read),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .operation_done(operation_done),
        .busy(busy),
        .sdram_address(sdram_address),
        .sdram_byteenable_n(sdram_byteenable_n),
        .sdram_chipselect(sdram_chipselect),
        .sdram_writedata(sdram_writedata),
        .sdram_read_n(sdram_read_n),
        .sdram_write_n(sdram_write_n),
        .sdram_readdata(sdram_readdata),
        .sdram_readdatavalid(sdram_readdatavalid),
        .sdram_waitrequest(sdram_waitrequest)
    );


endmodule
