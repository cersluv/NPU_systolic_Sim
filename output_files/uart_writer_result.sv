//=========================================================
// UART_WRITER_RESULT
// Envía 4 enteros (resultado diagonal sistólica) por UART
// Cada uno en decimal, seguido de nueva línea (\n)
//=========================================================
module uart_writer_result (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        start,         // Activa la transmisión
    input  wire signed [31:0] value0,
    input  wire signed [31:0] value1,
    input  wire signed [31:0] value2,
    input  wire signed [31:0] value3,
    output reg         chipselect,
    output reg         address,
    output reg         read_n,
    output reg         write_n,
    output reg [31:0]  writedata,
    input  wire        waitrequest,
    output reg         done           // Se activa cuando termina
);

    typedef enum logic [2:0] {
        IDLE, LOAD_CHAR, SEND_CHAR, WAIT_WRITE, NEXT_CHAR, DONE
    } state_t;

    state_t state;
    reg [7:0] buffer [0:63]; // Suficiente para 4 números + \n
    reg [5:0] index;
    reg [2:0] current_value;
    reg active;

    function automatic int_to_ascii;
        input signed [31:0] value;
        integer i;
        reg signed [31:0] val;
        begin
            i = 0;
            val = value;
            if (val < 0) begin
                buffer[i++] = "-";
                val = -val;
            end
            int_to_ascii = i;
            if (val == 0) begin
                buffer[i++] = "0";
                int_to_ascii = i;
                return;
            end
            int digits[0:9];
            int d = 0;
            while (val > 0) begin
                digits[d++] = val % 10;
                val = val / 10;
            end
            for (int j = d-1; j >= 0; j--) begin
                buffer[i++] = digits[j] + 8'd48;
            end
            int_to_ascii = i;
        end
    endfunction

    integer len;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            chipselect <= 0;
            address <= 0;
            read_n <= 1;
            write_n <= 1;
            writedata <= 0;
            index <= 0;
            current_value <= 0;
            done <= 0;
            active <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    chipselect <= 0;
                    write_n <= 1;
                    if (start && !active) begin
                        current_value <= 0;
                        index <= 0;
                        // Convert value0 to ASCII
                        len = int_to_ascii(value0);
                        buffer[len++] = "\n";
                        state <= LOAD_CHAR;
                        active <= 1;
                    end
                end
                LOAD_CHAR: begin
                    writedata <= {24'b0, buffer[index]};
                    chipselect <= 1;
                    write_n <= 0;
                    state <= SEND_CHAR;
                end
                SEND_CHAR: begin
                    if (!waitrequest) begin
                        write_n <= 1;
                        chipselect <= 0;
                        state <= WAIT_WRITE;
                    end
                end
                WAIT_WRITE: begin
                    index <= index + 1;
                    if (buffer[index] == "\n") begin
                        state <= NEXT_CHAR;
                    end else begin
                        state <= LOAD_CHAR;
                    end
                end
                NEXT_CHAR: begin
                    current_value <= current_value + 1;
                    index <= 0;
                    if (current_value == 1)
                        len = int_to_ascii(value1);
                    else if (current_value == 2)
                        len = int_to_ascii(value2);
                    else if (current_value == 3)
                        len = int_to_ascii(value3);
                    else begin
                        done <= 1;
                        active <= 0;
                        state <= DONE;
                    end
                    buffer[len++] = "\n";
                    if (state != DONE)
                        state <= LOAD_CHAR;
                end
                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
