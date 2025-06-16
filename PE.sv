module PE #(
    parameter int W_A = 16,   // ancho de datos de entrada A/B
    parameter int W_P = 32    // ancho de acumulador (psum)
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // datos de inyección (válidos solo en columna 0/fila 0)
    input  logic signed [W_A-1:0] in_a,
    input  logic signed [W_A-1:0] in_b,
    input  logic                  load_a,    // 1 = inyecta in_a; 0 = toma shift_a_in
    input  logic                  load_b,    // 1 = inyecta in_b; 0 = toma shift_b_in

    // entradas de shift desde vecinos
    input  logic signed [W_A-1:0] shift_a_in,
    input  logic signed [W_A-1:0] shift_b_in,

    // salidas de shift hacia vecinos
    output logic signed [W_A-1:0] shift_a_out,
    output logic signed [W_A-1:0] shift_b_out,

    // salida de la suma parcial
    output logic signed [W_P-1:0] psum_out
);

    // registros internos
    logic signed [W_A-1:0] a_reg, b_reg;
    logic signed [W_P-1:0] psum_reg;
    
    // Señales combinacionales para los valores a usar
    logic signed [W_A-1:0] a_current, b_current;
    
    // Determinar qué valores usar en este ciclo
    assign a_current = load_a ? in_a : shift_a_in;
    assign b_current = load_b ? in_b : shift_b_in;

    // Lógica secuencial
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg    <= '0;
            b_reg    <= '0;
            psum_reg <= '0;
        end else begin
            // Actualizar registros de shift
            a_reg <= a_current;
            b_reg <= b_current;
            
            // MAC: solo acumular si ambos valores son diferentes de cero
            // Esto evita acumulaciones espurias durante la inicialización
            if (a_current != 0 && b_current != 0) begin
                psum_reg <= psum_reg + a_current * b_current;
            end
        end
    end

    // Conexión a las salidas
    assign shift_a_out = a_reg;
    assign shift_b_out = b_reg;
    assign psum_out    = psum_reg;

endmodule