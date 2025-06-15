// SystolicArray4x4.sv
// 4×4 systolic array: each PE performs MAC and shifts A→East, B→South
// Author: (tu nombre)
// Date: (fecha)

module SystolicArray4x4 #(
  parameter int W_A = 16,          // ancho de datos de entrada A/B
  parameter int W_P = 32           // ancho de acumulador (psum)
)(
  input  logic                   clk,
  input  logic                   rst_n,
  // Interfaces de inyección: palabra por fila/columna cada ciclo
  input  logic signed [W_A-1:0]  injectA [0:3],  // A[i][t−i] para i=0..3
  input  logic signed [W_A-1:0]  injectB [0:3],  // B[t−j][j] para j=0..3
  output logic signed [W_P-1:0]  result  [0:3][0:3]
);

  // Señales internas de shift
  logic signed [W_A-1:0] shiftA [0:3][0:3];
  logic signed [W_A-1:0] shiftB [0:3][0:3];
  logic signed [W_P-1:0] psum   [0:3][0:3];

  genvar i, j;
  generate
    for (i = 0; i < 4; i++) begin : ROW
      for (j = 0; j < 4; j++) begin : COL
        // Instancia un Processing Element
        PE #(
          .W_A(W_A),
          .W_P(W_P)
        ) pe_inst (
          .clk        (clk),
          .rst_n      (rst_n),
          // Datos de inyección en borde
          .in_a       ( injectA[i] ),      // solo válido si j==0
          .in_b       ( injectB[j] ),      // solo válido si i==0
          .load_a     ( j == 0 ),          // inyecta A solo en col 0
          .load_b     ( i == 0 ),          // inyecta B solo en row 0
          // Datos shift-in desde vecinos
          .shift_a_in ( (j > 0) ? shiftA[i][j-1] : '0 ),
          .shift_b_in ( (i > 0) ? shiftB[i-1][j] : '0 ),
          // Datos shift-out a vecinos
          .shift_a_out( shiftA[i][j] ),
          .shift_b_out( shiftB[i][j] ),
          // Suma parcial
          .psum_out   ( psum[i][j] )
        );
        // Conecta la salida final
        assign result[i][j] = psum[i][j];
      end
    end
  endgenerate

endmodule