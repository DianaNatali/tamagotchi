module dht11_controller #(
    parameter WAIT_READ = 100000000,       // Tiempo de espera entre lecturas
    parameter INIT_PULSE_DOWN = 900000,   // Duración del pulso inicial bajo
    parameter INIT_PULSE_UP = 1500,        // Duración del pulso inicial alto
    parameter WAIT_RESPONSE_INIT = 8500,   // Tiempo de espera para la respuesta del sensor
    parameter WAIT_50u = 6250,             // Tiempo de espera de 50 µs
    parameter ZERO_24u = 1300,             // Duración de un bit '0' (24 µs)
    parameter ONE_70u = 3600,              // Duración de un bit '1' (70 µs)
    parameter DATA_BITS = 40,              // Número de bits de datos
    parameter COUNT_LCD = 800000           // Parámetro para el controlador LCD
)(
    input wire clk,                        // Señal de reloj
    input wire rst,                        // Señal de reset
    inout wire dht11_io,                   // Señal bidireccional para el sensor DHT11
    output reg valid,                      // Señal de dato válido
    output [2:0] state,                    // Estado actual de la FSM
    output reg flag,                       // Bandera de depuración
    output rs,                             // Señal RS para el LCD
    output rw,                             // Señal RW para el LCD
    output enable,                         // Señal Enable para el LCD
    output ready2wr,                       // Señal de listo para escribir en el LCD
    output [7:0] data                      // Datos para el LCD
);

    // Registros para la máquina de estados
    reg [2:0] fsm_state;
    reg [2:0] next_state;

    // Registros para almacenar los datos recibidos
    reg [DATA_BITS-1:0] shift_reg;

    // Contadores y temporizadores
    reg [$clog2(DATA_BITS)-1:0] bit_count;
    reg [$clog2(WAIT_READ)-1:0] timer_init;
    reg [$clog2(INIT_PULSE_UP)-1:0] timer_start_up;
    reg [$clog2(INIT_PULSE_DOWN)-1:0] timer_start_down;
    reg [$clog2(WAIT_RESPONSE_INIT)-1:0] timer_response;
    reg [$clog2(WAIT_50u)-1:0] timer_wait_data;
    reg [$clog2(ONE_70u)-1:0] timer_bits;

    // Registros para el cálculo del checksum
    reg [7:0] sum_reg1, sum_reg2, sum_reg3, sum_reg4, checksum;

    // Señales de control
    reg dht11_out;
    wire dht11_dir;

    // Sincronización de la señal dht11_io
    reg dht11_io_sync;
    reg dht11_io_prev;

    // Estados de la FSM
    localparam IDLE          = 3'b000;
    localparam START_DOWN    = 3'b001;
    localparam START_UP      = 3'b010;
    localparam WAIT_RESPONSE = 3'b011;
    localparam RECEIVE_BITS  = 3'b100;
    localparam CHECKSUM      = 3'b101;

    // Asignación de la señal bidireccional
    assign dht11_io = dht11_dir ? dht11_out : 1'bz;

    // Inicialización
    initial begin
        dht11_out <= 1'b1;
        valid <= 1'b0;
        timer_init <= 0;
        timer_start_up <= 0;
        timer_start_down <= 0;
        timer_response <= 0;
        timer_wait_data <= 0;
        timer_bits <= 0;
        shift_reg <= 0;
        fsm_state <= IDLE;
        bit_count <= 0;
        flag <= 0;
        dht11_io_prev <= 1'b1;
    end

    // Sincronización de la señal dht11_io
    always @(posedge clk) begin
        dht11_io_sync <= dht11_io;
        dht11_io_prev <= dht11_io_sync;
    end

    // Lógica de la FSM
    always @(posedge clk) begin
        if (rst == 0) begin
            fsm_state <= IDLE;
        end else begin
            fsm_state <= next_state;
        end
    end

    // Transiciones de la FSM
    always @(*) begin
        case (fsm_state)
            IDLE: begin
                next_state = (timer_init == WAIT_READ) ? START_DOWN : IDLE;
            end
            START_DOWN: begin
                next_state = (timer_start_down == INIT_PULSE_DOWN) ? START_UP : START_DOWN;
            end
            START_UP: begin
                next_state = (timer_start_up == INIT_PULSE_UP) ? WAIT_RESPONSE : START_UP;
            end
            WAIT_RESPONSE: begin
                next_state = (timer_response == WAIT_RESPONSE_INIT) ? RECEIVE_BITS : WAIT_RESPONSE;
            end
            RECEIVE_BITS: begin
                next_state = (bit_count == DATA_BITS) ? CHECKSUM : RECEIVE_BITS;
            end
            CHECKSUM: begin
                next_state = (valid) ? IDLE : CHECKSUM;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Lógica de los estados
    always @(posedge clk) begin
        if (rst == 0) begin
            dht11_out <= 1'b1;
            valid <= 1'b0;
            timer_init <= 0;
            timer_start_up <= 0;
            timer_start_down <= 0;
            timer_response <= 0;
            timer_wait_data <= 0;
            timer_bits <= 0;
            bit_count <= 0;
            flag <= 0;
            shift_reg <= 0;
        end else begin
            case (fsm_state)
                IDLE: begin
                    valid <= 1'b0;
                    timer_init <= timer_init + 1;
                    timer_start_down <= 0;
                    timer_start_up <= 0;
                    timer_response <= 0;
                    timer_bits <= 0;
                    checksum <= 0;
                    sum_reg1 <= 0;
                    sum_reg2 <= 0;
                    sum_reg3 <= 0;
                    sum_reg4 <= 0;
                end
                START_DOWN: begin
                    dht11_out <= 1'b0;
                    timer_start_down <= timer_start_down + 1;
                end
                START_UP: begin
                    dht11_out <= 1'b1;
                    timer_start_up <= timer_start_up + 1;
                end
                WAIT_RESPONSE: begin
                    timer_response <= timer_response + 1;
                end
                RECEIVE_BITS: begin
                    if (dht11_io_prev == 1'b1 && dht11_io_sync == 1'b0) begin
                        bit_count <= bit_count + 1;
                        if (timer_bits >= ONE_70u) begin
                            shift_reg[bit_count] <= 1'b1;
                        end else begin
                            shift_reg[bit_count] <= 1'b0;
                        end
                        timer_bits <= 0;
                    end else if (dht11_io_sync == 1'b1) begin
                        timer_bits <= timer_bits + 1;
                    end
                end
                CHECKSUM: begin
						  bit_count <= 0;
                    sum_reg1 <= shift_reg[7:0];
                    sum_reg2 <= shift_reg[15:8];
                    sum_reg3 <= shift_reg[23:16];
                    sum_reg4 <= shift_reg[31:24];
                    checksum <= shift_reg[39:32];
                    valid <= (sum_reg1 + sum_reg2 + sum_reg3 + sum_reg4 == checksum);
                    timer_init <= 0;
                end
            endcase
        end
    end

    // Control de la dirección de dht11_io
    assign dht11_dir = (fsm_state == START_UP || fsm_state == START_DOWN) ? 1'b1 : 1'b0;

    // Asignación del estado actual
    assign state = fsm_state;

    // Instancia del controlador LCD
    LCD1602_controller #(4, 32, 16, 1, COUNT_LCD) lcd(
        .clk(clk),
        .reset(rst),
        .ready_i(1'b1),
        .input_data1(sum_reg1),
        .rs(rs),
        .rw(rw),
        .enable(enable),
        .ready2wr(ready2wr),
        .data(data)
    );

endmodule