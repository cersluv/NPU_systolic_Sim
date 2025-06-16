//------------------------------------------------------------------------------
// Module: matrix_multiplication_system_4x4
// Descripción: Sistema con arreglo sistólico 4x4 e interfaz SDRAM
// VERSIÓN CORREGIDA - Pasa matrices correctamente al arreglo sistólico
//------------------------------------------------------------------------------

module prueba (
    input  logic           clk_clk,
    input  logic           reset_reset_n,
    input  logic           btn2,
    
    // Pines físicos hacia la SDRAM
    output logic [12:0]    wire_addr,
    output logic [1:0]     wire_ba,
    output logic           wire_cas_n,
    output logic           wire_cke,
    output logic           wire_cs_n,
    inout  logic [15:0]    wire_dq,
    output logic [1:0]     wire_dqm,
    output logic           wire_ras_n,
    output logic           wire_we_n,
    
    // Display de 7 segmentos
    output logic [6:0]     hex0,
    output logic [6:0]     hex1,
    output logic [6:0]     hex2,
    output logic [6:0]     hex3
);

    // Parámetros del sistema
    parameter W_A = 16;
    parameter W_P = 32;
    
    // Direcciones base en SDRAM
    parameter [24:0] MATRIX_A_BASE = 25'h000000;
    parameter [24:0] MATRIX_B_BASE = 25'h000040;  // 16 elementos después
    parameter [24:0] MATRIX_C_BASE = 25'h000080;  // 16 elementos después
    
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
    
    // Señales del arreglo sistólico - CORREGIDAS
    logic signed [W_A-1:0] matrix_a_internal [0:3][0:3];
    logic signed [W_A-1:0] matrix_b_internal [0:3][0:3];
    logic signed [W_P-1:0] result_internal [0:3][0:3];
    logic        systolic_start;
    logic        systolic_busy;
    logic        systolic_done;
    
    // Estados principales
    typedef enum logic [3:0] {
        INIT,
        LOAD_MATRIX_A,
        LOAD_MATRIX_B,
        SYSTOLIC_COMPUTE,
        STORE_RESULTS,
        DISPLAY_RESULTS,
        IDLE
    } main_state_t;
    
    main_state_t current_state, next_state;
    
    // Performance counters
    logic [63:0] cycle_counter;
    logic [31:0] mem_ops_counter;
    logic [31:0] compute_cycles;
    logic [31:0] flop_counter;
    
    // Contadores auxiliares
    logic [4:0]  matrix_index;  // Para 4x4 = 16 elementos
    logic [4:0]  result_index;
    logic [3:0]  display_mode;
    
    // Matrices temporales para carga/almacenamiento
    logic signed [15:0] matrix_a [0:3][0:3];
    logic signed [15:0] matrix_b [0:3][0:3];
    logic signed [31:0] column_results [0:3];
    
    // Control del display
    logic        btn2_prev, btn2_edge;
    logic [31:0] display_value;
    logic [31:0] arithmetic_intensity;
    
    // Delay de inicialización
    logic [25:0] init_delay_counter;
    logic        init_delay_done;
    
    // Debug signals
    logic        matrices_initialized;
    
    // Instanciación del controlador SDRAM
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
    sdram_SM sdram_if (
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
    
    // Instanciación del sistema sistólico 4x4 - CORREGIDA
    top_systolic_array #(
        .W_A(W_A),
        .W_P(W_P)
    ) systolic_system (
        .clk(clk_clk),
        .rst_n(reset_reset_n),
        .start(systolic_start),
        .matrix_a(matrix_a_internal),    // NUEVO: Pasar matriz A
        .matrix_b(matrix_b_internal),    // NUEVO: Pasar matriz B
        .busy(systolic_busy),
        .done(systolic_done),
        .result(result_internal)
    );
    
    // Contador de delay para inicialización
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            init_delay_counter <= 26'b0;
            init_delay_done <= 1'b0;
        end else begin
            if (init_delay_counter < 26'd50000000) begin
                init_delay_counter <= init_delay_counter + 1;
            end else begin
                init_delay_done <= 1'b1;
            end
        end
    end
    
    // Performance counters
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            cycle_counter <= 64'b0;
            mem_ops_counter <= 32'b0;
            compute_cycles <= 32'b0;
            flop_counter <= 32'b0;
        end else begin
            cycle_counter <= cycle_counter + 1;
            
            if (start_write || start_read) begin
                mem_ops_counter <= mem_ops_counter + 1;
            end
            
            if (current_state == SYSTOLIC_COMPUTE && systolic_busy) begin
                compute_cycles <= compute_cycles + 1;
                // 4x4 = 16 MAC operations por ciclo activo, cada MAC = 2 FLOPs
                flop_counter <= flop_counter + 32;
            end
        end
    end
    
    // Cálculo de intensidad aritmética
    always_comb begin
        if (mem_ops_counter > 0) begin
            // FLOPs / (Memory Operations * bytes per operation)
            // Total FLOPs para 4x4 matrix mult = 4*4*4*2 = 128 FLOPs
            // Total memory operations = 16+16+16 = 48 operations * 2 bytes = 96 bytes
            arithmetic_intensity = 32'd128 / (mem_ops_counter * 2);
        end else begin
            arithmetic_intensity = 32'b0;
        end
    end
    
    // Detección de flanco del botón
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            btn2_prev <= 1'b0;
            btn2_edge <= 1'b0;
        end else begin
            btn2_prev <= btn2;
            btn2_edge <= btn2 & ~btn2_prev;
        end
    end
    
    // Control del display mode
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            display_mode <= 4'b0;
        end else if (btn2_edge && current_state == DISPLAY_RESULTS) begin
            if (display_mode == 4'd4) begin  // 0-3 para resultados, 4 para intensidad
                display_mode <= 4'b0;
            end else begin
                display_mode <= display_mode + 1;
            end
        end
    end
    
    // INICIALIZACIÓN DE MATRICES - CORREGIDA Y MEJORADA
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            matrices_initialized <= 1'b0;
            
            // Matriz A - VALORES CORRECTOS DEL TESTBENCH
            matrix_a[0][0] <= 16'd5; matrix_a[0][1] <= 16'd1; matrix_a[0][2] <= 16'd3; matrix_a[0][3] <= 16'd0;
            matrix_a[1][0] <= 16'd1; matrix_a[1][1] <= 16'd2; matrix_a[1][2] <= 16'd0; matrix_a[1][3] <= 16'd1;
            matrix_a[2][0] <= 16'd0; matrix_a[2][1] <= 16'd1; matrix_a[2][2] <= 16'd2; matrix_a[2][3] <= 16'd3;
            matrix_a[3][0] <= 16'd3; matrix_a[3][1] <= 16'd0; matrix_a[3][2] <= 16'd1; matrix_a[3][3] <= 16'd2;
            
            // Matriz B - VALORES CORRECTOS DEL TESTBENCH
            matrix_b[0][0] <= 16'd2; matrix_b[0][1] <= 16'd2; matrix_b[0][2] <= 16'd1; matrix_b[0][3] <= 16'd3;
            matrix_b[1][0] <= 16'd2; matrix_b[1][1] <= 16'd1; matrix_b[1][2] <= 16'd3; matrix_b[1][3] <= 16'd0;
            matrix_b[2][0] <= 16'd1; matrix_b[2][1] <= 16'd3; matrix_b[2][2] <= 16'd0; matrix_b[2][3] <= 16'd2;
            matrix_b[3][0] <= 16'd0; matrix_b[3][1] <= 16'd1; matrix_b[3][2] <= 16'd2; matrix_b[3][3] <= 16'd1;
            
            // Inicializar matrices internas
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrix_a_internal[i][j] <= 16'b0;
                    matrix_b_internal[i][j] <= 16'b0;
                end
            end
        end else if (!matrices_initialized) begin
            // Copiar a matrices internas en el primer ciclo después del reset
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    matrix_a_internal[i][j] <= matrix_a[i][j];
                    matrix_b_internal[i][j] <= matrix_b[i][j];
                end
            end
            matrices_initialized <= 1'b1;
        end
    end
    
    // Máquina de estados principal
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            current_state <= INIT;
            matrix_index <= 5'b0;
            result_index <= 5'b0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                LOAD_MATRIX_A, LOAD_MATRIX_B: begin
                    if (operation_done && matrix_index < 15) begin
                        matrix_index <= matrix_index + 1;
                    end else if (operation_done && matrix_index == 15) begin
                        matrix_index <= 5'b0;
                    end
                end
                
                STORE_RESULTS: begin
                    if (operation_done && result_index < 15) begin
                        result_index <= result_index + 1;
                    end else if (operation_done && result_index == 15) begin
                        result_index <= 5'b0;
                    end
                end
            endcase
        end
    end
    
    // Lógica de transición de estados
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            INIT: begin
                if (init_delay_done && matrices_initialized) begin
                    next_state = LOAD_MATRIX_A;
                end
            end
            
            LOAD_MATRIX_A: begin
                if (operation_done && matrix_index == 15) begin
                    next_state = LOAD_MATRIX_B;
                end
            end
            
            LOAD_MATRIX_B: begin
                if (operation_done && matrix_index == 15) begin
                    next_state = SYSTOLIC_COMPUTE;
                end
            end
            
            SYSTOLIC_COMPUTE: begin
                if (systolic_done) begin
                    next_state = STORE_RESULTS;
                end
            end
            
            STORE_RESULTS: begin
                if (operation_done && result_index == 15) begin
                    next_state = DISPLAY_RESULTS;
                end
            end
            
            DISPLAY_RESULTS: begin
                next_state = DISPLAY_RESULTS;  // Permanece aquí
            end
            
            default: begin
                next_state = INIT;
            end
        endcase
    end
    
    // Control de operaciones de memoria
    always_comb begin
        start_write = 1'b0;
        start_read = 1'b0;
        address = 25'b0;
        write_data = 16'b0;
        
        case (current_state)
            LOAD_MATRIX_A: begin
                if (!busy) begin  // Solo iniciar si no está ocupado
                    start_write = 1'b1;
                    address = MATRIX_A_BASE + matrix_index;
                    write_data = matrix_a[matrix_index >> 2][matrix_index & 3];
                end
            end
            
            LOAD_MATRIX_B: begin
                if (!busy) begin  // Solo iniciar si no está ocupado
                    start_write = 1'b1;
                    address = MATRIX_B_BASE + matrix_index;
                    write_data = matrix_b[matrix_index >> 2][matrix_index & 3];
                end
            end
            
            STORE_RESULTS: begin
                if (!busy) begin  // Solo iniciar si no está ocupado
                    start_write = 1'b1;
                    address = MATRIX_C_BASE + result_index;
                    write_data = result_internal[result_index >> 2][result_index & 3][15:0];
                end
            end
        endcase
    end
    
    // Control del arreglo sistólico - MEJORADO
    always_ff @(posedge clk_clk or negedge reset_reset_n) begin
        if (!reset_reset_n) begin
            systolic_start <= 1'b0;
            for (int i = 0; i < 4; i++) begin
                column_results[i] <= 32'b0;
            end
        end else begin
            case (current_state)
                SYSTOLIC_COMPUTE: begin
                    if (!systolic_start && !systolic_busy && !systolic_done) begin
                        // Iniciar el cálculo sistólico
                        systolic_start <= 1'b1;
                    end else if (systolic_start) begin
                        // Desactivar start después de un ciclo
                        systolic_start <= 1'b0;
                    end
                    
                    if (systolic_done) begin
                        // Capturar resultados de la primera fila
                        for (int i = 0; i < 4; i++) begin
                            column_results[i] <= result_internal[i][i];  // Primera fila
                        end
                    end
                end
                
                default: begin
                    systolic_start <= 1'b0;
                end
            endcase
        end
    end
    
    // Selección de valor para display
    always_comb begin
        if (display_mode < 4) begin
            display_value = column_results[display_mode];
        end else begin
            display_value = arithmetic_intensity;
        end
    end
    
    // Función de decodificación 7-segmentos
    function logic [6:0] hex_to_7seg(input logic [3:0] hex);
        case (hex)
            4'h0: hex_to_7seg = 7'b1000000; // 0
            4'h1: hex_to_7seg = 7'b1111001; // 1
            4'h2: hex_to_7seg = 7'b0100100; // 2
            4'h3: hex_to_7seg = 7'b0110000; // 3
            4'h4: hex_to_7seg = 7'b0011001; // 4
            4'h5: hex_to_7seg = 7'b0010010; // 5
            4'h6: hex_to_7seg = 7'b0000010; // 6
            4'h7: hex_to_7seg = 7'b1111000; // 7
            4'h8: hex_to_7seg = 7'b0000000; // 8
            4'h9: hex_to_7seg = 7'b0010000; // 9
            4'hA: hex_to_7seg = 7'b0001000; // A
            4'hB: hex_to_7seg = 7'b0000011; // b
            4'hC: hex_to_7seg = 7'b1000110; // C
            4'hD: hex_to_7seg = 7'b0100001; // d
            4'hE: hex_to_7seg = 7'b0000110; // E
            4'hF: hex_to_7seg = 7'b0001110; // F
        endcase
    endfunction
    
    // Asignación de displays - MOSTRAR EN HEXADECIMAL
    assign hex0 = hex_to_7seg(display_value[3:0]);
    assign hex1 = hex_to_7seg(display_value[7:4]);
    assign hex2 = hex_to_7seg(display_value[11:8]);
    assign hex3 = hex_to_7seg(display_value[15:12]);

    // Debug - Solo para simulación
    `ifdef SIMULATION
    always @(posedge clk_clk) begin
        if (systolic_start) begin
            $display("=== INICIANDO MULTIPLICACIÓN SISTÓLICA ===");
            $display("Matriz A:");
            for (int i = 0; i < 4; i++) begin
                $display("  [%0d]: %2d %2d %2d %2d", i, 
                    matrix_a_internal[i][0], matrix_a_internal[i][1], 
                    matrix_a_internal[i][2], matrix_a_internal[i][3]);
            end
            $display("Matriz B:");
            for (int i = 0; i < 4; i++) begin
                $display("  [%0d]: %2d %2d %2d %2d", i, 
                    matrix_b_internal[i][0], matrix_b_internal[i][1], 
                    matrix_b_internal[i][2], matrix_b_internal[i][3]);
            end
        end
        
        if (systolic_done) begin
            $display("=== RESULTADO SISTÓLICO COMPLETADO ===");
            $display("Primera fila del resultado:");
            $display("  [%0d %0d %0d %0d]", 
                result_internal[0][0], result_internal[0][1], 
                result_internal[0][2], result_internal[0][3]);
        end
        
        if (current_state == DISPLAY_RESULTS && display_mode < 4) begin
            $display("Display Mode %0d: Mostrando resultado[0][%0d] = %0d", 
                display_mode, display_mode, column_results[display_mode]);
        end
    end
    `endif

endmodule