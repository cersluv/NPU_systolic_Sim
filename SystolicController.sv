// SystolicController.sv
// Controlador para arreglo sistólico 4x4 con datos internos

module SystolicController #(
  parameter int W_A = 16,
  parameter int W_P = 32
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  output logic busy,
  output logic done,

  output logic signed [W_A-1:0] injectA[0:3],
  output logic signed [W_A-1:0] injectB[0:3],
  input  logic signed [W_P-1:0] result[0:3][0:3]
);

  logic signed [W_A-1:0] A[0:3][0:3];
  logic signed [W_A-1:0] B[0:3][0:3];

  logic [3:0] t;

  typedef enum logic [1:0] {
    IDLE, INJECT, WAIT, DONE
  } state_t;
  state_t state, next_state;

  logic start_d1, start_d2;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_d1 <= 0;
      start_d2 <= 0;
    end else begin
      start_d1 <= start;
      start_d2 <= start_d1;
    end
  end
  wire start_sync = start_d1 & ~start_d2;

	initial begin
	  A[0] = '{2, 1, 3, 0};
	  A[1] = '{1, 2, 0, 1};
	  A[2] = '{0, 1, 2, 3};
	  A[3] = '{3, 0, 1, 2};

	  B[0] = '{1, 2, 1, 3};
	  B[1] = '{2, 1, 3, 0};
	  B[2] = '{1, 3, 0, 2};
	  B[3] = '{0, 1, 2, 1};
	end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      t <= 0;
    end else begin
      state <= next_state;
      if (state == INJECT || state == WAIT)
        t <= t + 1;
      else if (state == IDLE)
        t <= 0;  // Reset counter when in IDLE
    end
  end

  always_comb begin
    next_state = state;
    busy = 0;
    done = 0;

    case (state)
      IDLE:
        if (start_sync) next_state = INJECT;
      INJECT: begin
        busy = 1;
        if (t == 6) next_state = WAIT;  // Cambio: era 7, ahora 6
      end
      WAIT: begin
        busy = 1;
        if (t == 12) next_state = DONE;
      end
      DONE:
        done = 1;
    endcase
  end

  always_comb begin
    for (int i = 0; i < 4; i++) begin
      // Solo inyectar datos válidos durante los primeros 7 ciclos (t=0 a t=6)
      if (state == INJECT && t >= i && t - i < 4) begin
        injectA[i] = A[i][t - i];
        injectB[i] = B[t - i][i];
      end else begin
        injectA[i] = 0;
        injectB[i] = 0;
      end
    end
  end

  // Debug outputs
  always @(posedge clk) begin
    if (state == INJECT) begin
      $display("t=%0d: injectA={%0d,%0d,%0d,%0d}, injectB={%0d,%0d,%0d,%0d}", 
               t, injectA[0], injectA[1], injectA[2], injectA[3],
               injectB[0], injectB[1], injectB[2], injectB[3]);
    end
  end

endmodule