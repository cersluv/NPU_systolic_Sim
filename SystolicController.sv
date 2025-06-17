// SystolicController.sv - VERSIÓN CORREGIDA
// Controlador para arreglo sistólico 4x4 que recibe matrices como entrada

module SystolicController #(
  parameter int W_A = 16,
  parameter int W_P = 32
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  
  // NUEVO: Matrices de entrada desde el módulo principal
  input  logic signed [W_A-1:0] matrix_a [0:3][0:3],
  input  logic signed [W_A-1:0] matrix_b [0:3][0:3],
  
  output logic busy,
  output logic done,
  output logic signed [W_A-1:0] injectA[0:3],
  output logic signed [W_A-1:0] injectB[0:3],
  input  logic signed [W_P-1:0] result[0:3][0:3]
);
  // Registros internos para las matrices
  logic signed [W_A-1:0] A[0:3][0:3];
  logic signed [W_A-1:0] B[0:3][0:3];
  
  logic [3:0] t;
  
  // CORREGIDO: Cambiar de logic [1:0] a logic [2:0] para 5 estados
  typedef enum logic [2:0] {
    IDLE, LOAD_MATRICES, INJECT, WAIT, DONE
  } state_t;
  
  state_t state, next_state;
  logic start_d1, start_d2;
  
  // Sincronización del start
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
  // Máquina de estados principal
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      t <= 0;
      // Resetear matrices
      for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
          A[i][j] <= '0;
          B[i][j] <= '0;
        end
      end
    end else begin
      state <= next_state;
      
      case (state)
        LOAD_MATRICES: begin
          // Copiar matrices de entrada a registros internos
          for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
              A[i][j] <= matrix_a[i][j];
              B[i][j] <= matrix_b[i][j];
            end
          end
        end
        
        INJECT, WAIT: begin
          t <= t + 1;
        end
        
        IDLE: begin
          t <= 0;  // Reset counter when in IDLE
        end
      endcase
    end
  end
  // Lógica de transición de estados
  always_comb begin
    next_state = state;
    busy = 0;
    done = 0;
    
    case (state)
      IDLE: begin
        if (start_sync) 
          next_state = LOAD_MATRICES;
      end
      
      LOAD_MATRICES: begin
        busy = 1;
        next_state = INJECT;
      end
      
      INJECT: begin
        busy = 1;
        if (t == 6) 
          next_state = WAIT;
      end
      
      WAIT: begin
        busy = 1;
        if (t == 12) 
          next_state = DONE;
      end
      
      DONE: begin
        done = 1;
        next_state = IDLE;  // Regresar a IDLE después de DONE
      end
    endcase
  end
  // Lógica de inyección
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      // Solo inyectar datos válidos durante INJECT y primeros ciclos de WAIT
      if ((state == INJECT || state == WAIT) && t >= i && t - i < 4) begin
        injectA[i] = A[i][t - i];
        injectB[i] = B[t - i][i];
      end else begin
        injectA[i] = 0;
        injectB[i] = 0;
      end
    end
  end
  // Debug outputs (solo para simulación)
  `ifdef SIMULATION
  always @(posedge clk) begin
    if (state == LOAD_MATRICES) begin
      $display("LOADING MATRICES:");
      for (int i = 0; i < 4; i++) begin
        $display("A[%0d]: %0d %0d %0d %0d", i, A[i][0], A[i][1], A[i][2], A[i][3]);
        $display("B[%0d]: %0d %0d %0d %0d", i, B[i][0], B[i][1], B[i][2], B[i][3]);
      end
    end
    
    if (state == INJECT || state == WAIT) begin
      $display("t=%0d: injectA={%0d,%0d,%0d,%0d}, injectB={%0d,%0d,%0d,%0d}", 
               t, injectA[0], injectA[1], injectA[2], injectA[3],
               injectB[0], injectB[1], injectB[2], injectB[3]);
    end
  end
  `endif
endmodule