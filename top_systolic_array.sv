module top_systolic_array #(
  parameter int W_A = 16,
  parameter int W_P = 32
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  
  // Matrices de entrada
  input  logic signed [W_A-1:0] matrix_a [0:3][0:3],
  input  logic signed [W_A-1:0] matrix_b [0:3][0:3],
  
  output logic busy,
  output logic done,
  output logic signed [W_P-1:0] result [0:3][0:3]
);

  logic signed [W_A-1:0] injectA[0:3];
  logic signed [W_A-1:0] injectB[0:3];

  // Controlador - AHORA RECIBE LAS MATRICES
  SystolicController #(
    .W_A(W_A),
    .W_P(W_P)
  ) controller (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .matrix_a(matrix_a),
    .matrix_b(matrix_b),
    .busy(busy),
    .done(done),
    .injectA(injectA),
    .injectB(injectB),
    .result(result)
  );

  // Arreglo sistólico
  SystolicArray4x4 #(
    .W_A(W_A),
    .W_P(W_P)
  ) array4x4 (
    .clk(clk),
    .rst_n(rst_n),
    .injectA(injectA),
    .injectB(injectB),
    .result(result)
  );

endmodule
