`timescale 1ns/1ps

module tb_SystolicController;

  localparam int W_A = 16;
  localparam int W_P = 32;

  logic clk;
  logic rst_n;
  logic start;
  logic busy;
  logic done;

  logic signed [W_A-1:0] injectA[0:3];
  logic signed [W_A-1:0] injectB[0:3];
  logic signed [W_P-1:0] result[0:3][0:3];

  // Clock: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation
  SystolicController #(.W_A(W_A), .W_P(W_P)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .busy(busy),
    .done(done),
    .injectA(injectA),
    .injectB(injectB),
    .result(result)
  );

  // Dummy matrix (not used here but needed by interface)
  initial begin
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++)
        result[i][j] = 0;
  end

  // Test sequence
  initial begin
    // Reset
    rst_n = 0;
    start = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] Reset released", $time);

    // Start pulse
    @(posedge clk); start = 1;
    @(posedge clk); start = 0;

    // Monitor injectA/B during injection and wait
    repeat (13) begin
      @(posedge clk);
      $display("t=%0t: injectA = %p, injectB = %p", $time, injectA, injectB);
    end

    wait (done);
    $display("[%0t] DONE asserted", $time);

    // Print final state
    for (int i = 0; i < 4; i++)
      $display("injectA[%0d] = %0d", i, injectA[i]);
    for (int i = 0; i < 4; i++)
      $display("injectB[%0d] = %0d", i, injectB[i]);

    $display("✅ Test completed.");
    $finish;
  end

endmodule
