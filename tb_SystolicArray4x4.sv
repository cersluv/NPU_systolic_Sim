// tb_SystolicArray4x4.sv
`timescale 1ns/1ps

module tb_SystolicArray4x4;

  // Parameters
  localparam int N            = 4;
  localparam int W_A          = 16;
  localparam int W_P          = 32;
  localparam int TOTAL_CYCLES = 3*N - 2;

  // Clock & reset
  logic clk;
  logic rst_n;

  // Memories for A, B and expected C
  logic signed [W_A-1:0] A_mem [0:N-1][0:N-1];
  logic signed [W_A-1:0] B_mem [0:N-1][0:N-1];
  logic signed [W_P-1:0] C_expected [0:N-1][0:N-1];

  // DUT interfaces
  logic signed [W_A-1:0] injectA [0:N-1];
  logic signed [W_A-1:0] injectB [0:N-1];
  logic signed [W_P-1:0] result  [0:N-1][0:N-1];

  // Instantiate the 4×4 systolic array
  SystolicArray4x4 #(
    .W_A(W_A), .W_P(W_P)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .injectA  (injectA),
    .injectB  (injectB),
    .result   (result)
  );

  // Clock generation: 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Initialize memories and expected result
  initial begin
    // Matrix A
    A_mem[0] = '{16'sd  1, 16'sd  2, 16'sd  3, 16'sd  4};
    A_mem[1] = '{16'sd  5, 16'sd  6, 16'sd  7, 16'sd  8};
    A_mem[2] = '{16'sd  9, 16'sd 10, 16'sd 11, 16'sd 12};
    A_mem[3] = '{16'sd 13, 16'sd 14, 16'sd 15, 16'sd 16};
    // Matrix B
    B_mem[0] = '{16'sd16, 16'sd15, 16'sd14, 16'sd13};
    B_mem[1] = '{16'sd12, 16'sd11, 16'sd10, 16'sd 9};
    B_mem[2] = '{16'sd 8, 16'sd 7, 16'sd 6, 16'sd 5};
    B_mem[3] = '{16'sd 4, 16'sd 3, 16'sd 2, 16'sd 1};
    // Expected C = A×B
    C_expected[0] = '{32'sd  80, 32'sd  70, 32'sd  60, 32'sd  50};
    C_expected[1] = '{32'sd 240, 32'sd 214, 32'sd 188, 32'sd 162};
    C_expected[2] = '{32'sd 400, 32'sd 358, 32'sd 316, 32'sd 274};
    C_expected[3] = '{32'sd 560, 32'sd 502, 32'sd 444, 32'sd 386};
  end

  // Stimulus: reset, then drive injectA/injectB for TOTAL_CYCLES
  initial begin
    integer t, i, j, k;
    // Apply reset
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] Released reset", $time);

    // Cycle through t = 0 .. TOTAL_CYCLES-1
    for (t = 0; t < TOTAL_CYCLES; t++) begin
      // Build injectA[i] = (0<=t-i<N)? A_mem[i][t-i] : 0
      for (i = 0; i < N; i++) begin
        k = t - i;
        injectA[i] = (k >= 0 && k < N) ? A_mem[i][k] : '0;
      end
      // Build injectB[j] = (0<=t-j<N)? B_mem[k][j] : 0
      for (j = 0; j < N; j++) begin
        k = t - j;
        injectB[j] = (k >= 0 && k < N) ? B_mem[k][j] : '0;
      end
      @(posedge clk);
    end

    // After feeding all cycles, wait one more cycle for final accumulation
    @(posedge clk);
	 @(posedge clk);

    // Check results
    for (i = 0; i < N; i++) begin
      for (j = 0; j < N; j++) begin
        assert(result[i][j] === C_expected[i][j])
          else $error("Mismatch at [%0d,%0d]: got %0d, expected %0d",
                      i, j, result[i][j], C_expected[i][j]);
      end
    end

    $display("SystolicArray4x4 test PASSED: all results match expected AxB.");
    $finish;
  end

endmodule
