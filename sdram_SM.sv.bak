// sdram_SM.sv
// SM simplificada para el controlador SDRAM
// Maneja automaticamente las senales de control y temporizacion

module sdram_SM (
    input  logic           clk,
    input  logic           reset_n,
    
    // Interfaz simplificada hacia el usuario
    input  logic           start_write,    // Pulso para iniciar escritura
    input  logic           start_read,     // Pulso para iniciar lectura
    input  logic [24:0]    address,        // Direccion de memoria
    input  logic [15:0]    write_data,     // Datos a escribir
    output logic [15:0]    read_data,      // Datos leidos
    output logic           operation_done, // Senal de operacion completada
    output logic           busy,           // Indica si hay operacion en curso
    
    // Conexion hacia el controlador SDRAM
    output logic [24:0]    sdram_address,
    output logic [1:0]     sdram_byteenable_n,
    output logic           sdram_chipselect,
    output logic [15:0]    sdram_writedata,
    output logic           sdram_read_n,
    output logic           sdram_write_n,
    input  logic [15:0]    sdram_readdata,
    input  logic           sdram_readdatavalid,
    input  logic           sdram_waitrequest
);

    // Estados de la mÃ¡quina de estados
    typedef enum logic [2:0] {
        IDLE,       // Estado inactivo, esperando comandos
        WRITE_START, // Iniciando operacion de escritura
        WRITE_WAIT,  // Esperando completar escritura
        READ_START,  // Iniciando operacion de lectura
        READ_WAIT,   // Esperando datos de lectura
        DONE         // Operacion completada
    } state_t;
    
    state_t current_state, next_state;
    
    // Registros internos
    logic [24:0] addr_reg;          // Registro de direccion
    logic [15:0] data_reg;          // Registro de datos a escribir
    logic [15:0] read_data_reg;     // Registro de datos leidos
    logic operation_done_reg;       // Registro de operacion completada
    
    // Logica secuencial - actualiza registros en cada ciclo de reloj
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= IDLE;
            addr_reg <= 25'b0;
            data_reg <= 16'b0;
            read_data_reg <= 16'b0;
            operation_done_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            
            // Capturar direccion y datos al inicio de operacion
            if ((start_write || start_read) && current_state == IDLE) begin
                addr_reg <= address;
                if (start_write) begin
                    data_reg <= write_data;
                end
            end
            
            // Capturar datos leidos cuando estan validos
            if (sdram_readdatavalid) begin
                read_data_reg <= sdram_readdata;
            end
            
            // Controlar senal de operacion completada
            operation_done_reg <= (next_state == DONE);
        end
    end
    
    // Logica combinacional para la maquina de estados
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (start_write) begin
                    next_state = WRITE_START;
                end else if (start_read) begin
                    next_state = READ_START;
                end
            end
            
            WRITE_START: begin
                next_state = WRITE_WAIT;
            end
            
            WRITE_WAIT: begin
                if (!sdram_waitrequest) begin
                    next_state = DONE;
                end
            end
            
            READ_START: begin
                next_state = READ_WAIT;
            end
            
            READ_WAIT: begin
                if (sdram_readdatavalid) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Asignacion de senales hacia el controlador SDRAM
    always_comb begin
        // Valores por defecto (inactivos)
        sdram_address = addr_reg;
        sdram_byteenable_n = 2'b00;  // Ambos bytes habilitados
        sdram_chipselect = 1'b0;
        sdram_writedata = data_reg;
        sdram_read_n = 1'b1;         // Lectura inactiva
        sdram_write_n = 1'b1;        // Escritura inactiva
        
        case (current_state)
            WRITE_START, WRITE_WAIT: begin
                sdram_chipselect = 1'b1;
                sdram_write_n = 1'b0;    // Activar escritura
            end
            
            READ_START, READ_WAIT: begin
                sdram_chipselect = 1'b1;
                sdram_read_n = 1'b0;     // Activar lectura
            end
            
            default: begin
                // Mantener valores por defecto
            end
        endcase
    end
    
    // Asignacion de senales hacia el usuario
    assign read_data = read_data_reg;
    assign operation_done = operation_done_reg;
    assign busy = (current_state != IDLE);

endmodule