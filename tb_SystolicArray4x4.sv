`timescale 1ns/1ps

module tb_SystolicArray4x4;

  parameter int W_A = 16;
  parameter int W_P = 32;

  logic                   clk;
  logic                   rst_n;
  logic signed [W_A-1:0]  injectA [0:3];
  logic signed [W_A-1:0]  injectB [0:3];
  logic signed [W_P-1:0]  result  [0:3][0:3];

  SystolicArray4x4 #(
    .W_A(W_A),
    .W_P(W_P)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .injectA(injectA),
    .injectB(injectB),
    .result(result)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  logic signed [W_A-1:0] matrixA [0:3][0:3] = '{
    '{ 1,  2,  3,  4},
    '{ 5,  6,  7,  8},
    '{ 9, 10, 11, 12},
    '{13, 14, 15, 16}
  };

  logic signed [W_A-1:0] matrixB [0:3][0:3] = '{
    '{ 1,  2,  3,  4},
    '{ 5,  6,  7,  8},
    '{ 9, 10, 11, 12},
    '{13, 14, 15, 16}
  };

  logic signed [W_P-1:0] expected [0:3][0:3];

  int total_cycles = 12; // 2N - 1 (inyección) + N (drenado) = 8 + 4

  initial begin
    rst_n = 0;
    #15;
    rst_n = 1;

    // Software: expected result
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++) begin
        expected[i][j] = 0;
        for (int k = 0; k < 4; k++)
          expected[i][j] += matrixA[i][k] * matrixB[k][j];
      end

    $display("\n--- Iniciando simulación ciclo a ciclo ---\n");

    for (int t = 0; t < total_cycles; t++) begin
      // Inject A[i][t - i]
      for (int i = 0; i < 4; i++)
        injectA[i] = (t - i >= 0 && t - i < 4) ? matrixA[i][t - i] : 0;

      // Inject B[t - j][j]
      for (int j = 0; j < 4; j++)
        injectB[j] = (t - j >= 0 && t - j < 4) ? matrixB[t - j][j] : 0;

      @(posedge clk); // avanzar al flanco positivo
      $display("Ciclo %0d:", t);
      $display("  injectA: %p", injectA);
      $display("  injectB: %p", injectB);

      // Mostrar resultados parciales (aunque estén incompletos)
      for (int i = 0; i < 4; i++) begin
        $write("  result[%0d]: ", i);
        for (int j = 0; j < 4; j++) begin
          $write("%0d ", result[i][j]);
        end
        $write("\n");
      end
      $display("");
    end

    $display("\n--- Verificación final contra resultado esperado ---\n");

    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        if (result[i][j] !== expected[i][j])
          $display("❌ ERROR en [%0d][%0d]: esperado=%0d, obtenido=%0d", i, j, expected[i][j], result[i][j]);
        else
          $display("✅ OK    en [%0d][%0d]: valor correcto = %0d", i, j, result[i][j]);
      end
    end

    $finish;
  end

endmodule
