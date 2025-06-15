// tb_PE.sv
`timescale 1ns/1ps

module tb_PE;

  // Parameters must match PE.sv
  localparam int W_A = 16;
  localparam int W_P = 32;

  // DUT signals
  logic                   clk;
  logic                   rst_n;
  logic signed [W_A-1:0]  in_a;
  logic signed [W_A-1:0]  in_b;
  logic                   load_a;
  logic                   load_b;
  logic signed [W_A-1:0]  shift_a_in;
  logic signed [W_A-1:0]  shift_b_in;
  logic signed [W_A-1:0]  shift_a_out;
  logic signed [W_A-1:0]  shift_b_out;
  logic signed [W_P-1:0]  psum_out;

  // Clock: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Instantiate the PE
  PE #(
    .W_A(W_A),
    .W_P(W_P)
  ) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .in_a       (in_a),
    .in_b       (in_b),
    .load_a     (load_a),
    .load_b     (load_b),
    .shift_a_in (shift_a_in),
    .shift_b_in (shift_b_in),
    .shift_a_out(shift_a_out),
    .shift_b_out(shift_b_out),
    .psum_out   (psum_out)
  );

  initial begin
    // Reset sequence
    rst_n       = 0;
    in_a        = '0;
    in_b        = '0;
    load_a      = 0;
    load_b      = 0;
    shift_a_in  = '0;
    shift_b_in  = '0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    $display("[%0t] Released reset", $time);

    // --------------------------------------------------------
    // Test 1: Injection of A=5, B=4 on cycle 1
    // --------------------------------------------------------
    in_a       = 16'sd5;
    in_b       = 16'sd4;
    load_a     = 1;
    load_b     = 1;
    shift_a_in = 16'sd0;
    shift_b_in = 16'sd0;
    @(posedge clk);
    // Deassert loads after injection
    load_a = 0;
    load_b = 0;
    
    // Wait one more cycle for shift outputs to propagate
    @(posedge clk);
    
    // Check shift outputs (available now) and store them
    assert(shift_a_out == 16'sd5)
      else $error("Test1: shift_a_out expected 5, got %0d", shift_a_out);
    assert(shift_b_out == 16'sd4)
      else $error("Test1: shift_b_out expected 4, got %0d", shift_b_out);
    $display("[%0t] Test1 Shift check: shiftA=%0d, shiftB=%0d", $time, shift_a_out, shift_b_out);
    
    // Wait one more cycle for psum to propagate
    @(posedge clk);
    
    // Check psum (available with additional delay)
    assert(psum_out == 32'sd20)
      else $error("Test1: psum_out expected 20, got %0d", psum_out);
    $display("[%0t] Test1 PASS: psum=%0d", $time, psum_out);

    // --------------------------------------------------------
    // Test 2: Injection of A=-3, B=7 on cycle 2
    // --------------------------------------------------------
    in_a   = -16'sd3;
    in_b   =  16'sd7;
    load_a = 1;
    load_b = 1;
    @(posedge clk);
    // Deassert loads
    load_a = 0;
    load_b = 0;
    
    // Wait one more cycle for shift outputs to propagate
    @(posedge clk);
    
    // Check shift outputs
    assert(shift_a_out == -16'sd3)
      else $error("Test2: shift_a_out expected -3, got %0d", shift_a_out);
    assert(shift_b_out == 16'sd7)
      else $error("Test2: shift_b_out expected 7, got %0d", shift_b_out);
    $display("[%0t] Test2 Shift check: shiftA=%0d, shiftB=%0d", $time, shift_a_out, shift_b_out);
    
    // Wait one more cycle for psum to propagate
    @(posedge clk);
    
    // Check accumulation: 20 + (-3*7) = -1
    assert(psum_out == (32'sd20 + -21))
      else $error("Test2: psum_out expected -1, got %0d", psum_out);
    $display("[%0t] Test2 PASS: psum=%0d", $time, psum_out);

    // --------------------------------------------------------
    // Test 3: Shift-only (no injection) on cycle 3
    // --------------------------------------------------------
    in_a       = 16'sd0;
    in_b       = 16'sd0;
    // ensure no injection
    load_a     = 0;
    load_b     = 0;
    // drive shift inputs
    shift_a_in = 16'sd8;
    shift_b_in = 16'sd2;
    @(posedge clk);
    
    // Wait one more cycle for shift outputs to propagate
    @(posedge clk);
    
    // Check shift outputs
    assert(shift_a_out == 16'sd8)
      else $error("Test3: shift_a_out expected 8, got %0d", shift_a_out);
    assert(shift_b_out == 16'sd2)
      else $error("Test3: shift_b_out expected 2, got %0d", shift_b_out);
    $display("[%0t] Test3 Shift check: shiftA=%0d, shiftB=%0d", $time, shift_a_out, shift_b_out);
    
    // Wait one more cycle for psum to propagate
    @(posedge clk);
    
    // Check: -1 + (8*2) = 15
    assert(psum_out == 32'sd15)
      else $error("Test3: psum_out expected 15, got %0d", psum_out);
    $display("[%0t] Test3 PASS: psum=%0d", $time, psum_out);

    $display("All PE tests passed.");
    $finish;
  end

endmodule