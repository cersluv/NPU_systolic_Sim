`timescale 1ns/1ps

module tb_top_systolic_array;

  localparam int W_A = 16;
  localparam int W_P = 32;

  logic clk;
  logic rst_n;
  logic start;
  logic busy;
  logic done;
  logic signed [W_P-1:0] result [0:3][0:3];

  // Matrices esperadas (copiar de SystolicController)
	logic signed [W_A-1:0] A[0:3][0:3] = '{
	  '{2, 1, 3, 0},
	  '{1, 2, 0, 1},
	  '{0, 1, 2, 3},
	  '{3, 0, 1, 2}
	};
	logic signed [W_A-1:0] B[0:3][0:3] = '{
	  '{1, 2, 1, 3},
	  '{2, 1, 3, 0},
	  '{1, 3, 0, 2},
	  '{0, 1, 2, 1}
	};

  logic signed [W_P-1:0] expected [0:3][0:3];

  // DUT instantiation
  top_systolic_array #(.W_A(W_A), .W_P(W_P)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .busy(busy),
    .done(done),
    .result(result)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // Precalcular resultados esperados en software
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++) begin
        expected[i][j] = 0;
        for (int k = 0; k < 4; k++)
          expected[i][j] += A[i][k] * B[k][j];
      end

    // Reset
    rst_n = 0;
    start = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] Reset liberado", $time);

    // Enviar pulso de inicio
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // Esperar finalización
    wait(done);
    $display("[%0t] DONE asserted\n", $time);

    // Verificación
    $display("--- Verificación final ---\n");
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        if (result[i][j] !== expected[i][j])
          $display("❌ ERROR en [%0d][%0d]: esperado=%0d, obtenido=%0d", i, j, expected[i][j], result[i][j]);
        else
          $display("✅ OK    en [%0d][%0d]: %0d", i, j, result[i][j]);
      end
    end

    $display("\n✅ Simulación finalizada.");
    $finish;
  end

endmodule
