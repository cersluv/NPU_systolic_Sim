module uart_matrix_writer (
    input  wire clk,
    input  wire reset_n,
    input  wire start_send,
    input  wire signed [31:0] result_matrix [0:3][0:3],
    output reg  done,
    output reg  chipselect,
    output reg  address,
    output reg  read_n,
    output reg  write_n,
    output reg [31:0] writedata,
    input  wire waitrequest
);

    typedef enum logic [3:0] {
        IDLE,
        SEND_HEADER,
        SEND_ROW_LABEL,
        LOAD_VALUE,
        CONVERT_DIGIT,
        SEND_DIGIT,
        SEND_SPACE,
        NEXT_VALUE,
        NEXT_ROW,
        DONE,
        WAIT_UART
    } state_t;

    state_t state, next_state;

    // Cabecera
    reg [7:0] header_msg [0:13];
    reg [3:0] header_idx;

    // Etiquetas [0] ... [3]
    reg [2:0] label_idx;

    // Coordenadas
    reg [1:0] row, col;

    // Conversión a ASCII
    reg signed [31:0] value, temp;
    reg [7:0] buffer [0:10];
    reg [3:0] num_len;
    reg [3:0] digit_idx;
    reg is_negative;

    reg [7:0] tx_char;

    initial begin
        header_msg[0]  = "M"; header_msg[1]  = "a";
        header_msg[2]  = "t"; header_msg[3]  = "r";
        header_msg[4]  = "i"; header_msg[5]  = "x";
        header_msg[6]  = " "; header_msg[7]  = "R";
        header_msg[8]  = "e"; header_msg[9]  = "s";
        header_msg[10] = "u"; header_msg[11] = "l";
        header_msg[12] = "t"; header_msg[13] = ":";
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state       <= IDLE;
            chipselect  <= 0;
            address     <= 0;
            read_n      <= 1;
            write_n     <= 1;
            writedata   <= 0;
            done        <= 0;
            row         <= 0;
            col         <= 0;
            header_idx  <= 0;
            label_idx   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start_send) begin
                        header_idx <= 0;
                        state <= SEND_HEADER;
                    end
                end

                SEND_HEADER: begin
                    if (header_idx <= 13) begin
                        tx_char <= header_msg[header_idx];
                        header_idx <= header_idx + 1;
                        next_state <= SEND_HEADER;
                        state <= WAIT_UART;
                    end else begin
                        tx_char <= 8'h0A;
                        next_state <= SEND_ROW_LABEL;
                        label_idx <= 0;
                        state <= WAIT_UART;
                    end
                end

                SEND_ROW_LABEL: begin
                    case (label_idx)
                        0: tx_char <= "["; 
                        1: tx_char <= 8'h30 + row;
                        2: tx_char <= "]";
                        3: tx_char <= " ";
                        default: tx_char <= " ";
                    endcase
                    label_idx <= label_idx + 1;
                    next_state <= (label_idx == 3) ? LOAD_VALUE : SEND_ROW_LABEL;
                    state <= WAIT_UART;
                end

                LOAD_VALUE: begin
                    value <= result_matrix[row][col];
                    temp <= (result_matrix[row][col] < 0) ? -result_matrix[row][col] : result_matrix[row][col];
                    is_negative <= (result_matrix[row][col] < 0);
                    num_len <= 0;
                    digit_idx <= 0;

                    if (result_matrix[row][col] == 0) begin
                        buffer[0] <= "0";
                        num_len <= 1;
                        digit_idx <= 1;
                        state <= SEND_DIGIT;
                    end else begin
                        state <= CONVERT_DIGIT;
                    end
                end

                CONVERT_DIGIT: begin
                    if (temp != 0) begin
                        buffer[num_len] <= 8'h30 + (temp % 10);
                        temp <= temp / 10;
                        num_len <= num_len + 1;
                    end else begin
                        if (is_negative) begin
                            buffer[num_len] <= "-";
                            num_len <= num_len + 1;
                        end
                        digit_idx <= num_len;
                        state <= SEND_DIGIT;
                    end
                end

                SEND_DIGIT: begin
                    if (digit_idx > 0) begin
                        tx_char <= buffer[digit_idx - 1];
                        next_state <= (digit_idx == 1) ? SEND_SPACE : SEND_DIGIT;
                        digit_idx <= digit_idx - 1;
                        state <= WAIT_UART;
                    end
                end

                SEND_SPACE: begin
                    tx_char <= (col == 3) ? 8'h0A : " ";
                    next_state <= (col == 3) ? NEXT_ROW : NEXT_VALUE;
                    state <= WAIT_UART;
                end

                NEXT_VALUE: begin
                    col <= col + 1;
                    state <= LOAD_VALUE;
                end

                NEXT_ROW: begin
                    if (row == 3) begin
                        tx_char <= 8'h0A;
                        next_state <= DONE;
                        state <= WAIT_UART;
                    end else begin
                        row <= row + 1;
                        col <= 0;
                        label_idx <= 0;
                        state <= SEND_ROW_LABEL;
                    end
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end

                WAIT_UART: begin
                    chipselect <= 1;
                    address    <= 0;
                    read_n     <= 1;
                    write_n    <= 0;
                    writedata  <= {24'd0, tx_char};
                    if (!waitrequest) begin
                        chipselect <= 0;
                        write_n    <= 1;
                        state <= next_state;
                    end
                end
            endcase
        end
    end

endmodule
