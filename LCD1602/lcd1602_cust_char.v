module LCD1602_controller #(parameter config_commands = 3, 
                                      data_mem_size = 56,  
                                      char_data = 8,
                                      num_cgram_addrs = 7,
                                      COUNT_MAX = 800000)(
    input clk,            
    input reset,          
    input ready_i,
    output reg rs,        
    output reg rw,
    output enable,    
    output reg [7:0] data
);

// Definir los estados del controlador
localparam IDLE = 0;
localparam INIT_CONFIG = 1;
localparam CREATE_CHARS = 2;
localparam SET_CURSOR = 3;
localparam SHOW = 4;
localparam SET_CGRAM_ADDR = 0;
localparam WRITE_CGRAM = 1;

reg [3:0] fsm_state;
reg [3:0] next;
reg clk_16ms;
reg create_char_task;
reg done_cgram_write;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] counter_div_freq;

// Comandos de configuración
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam LINES2_MATRIX5x8_MODE4bit = 8'h28;
localparam LINES1_MATRIX5x8_MODE8bit = 8'h30;
localparam LINES1_MATRIX5x8_MODE4bit = 8'h20;
localparam START_2LINE = 8'hC0;

// Direcciones de escritura de la CGRAM 
localparam CGRAM_ADDR0 = 8'h40;
localparam CGRAM_ADDR1 = 8'h48;
localparam CGRAM_ADDR2 = 8'h50;
localparam CGRAM_ADDR3 = 8'h58;
localparam CGRAM_ADDR4 = 8'h60;
localparam CGRAM_ADDR5 = 8'h68;
localparam CGRAM_ADDR6 = 8'h70;

// Definir un contador para controlar el envío de comandos
reg [$clog2(config_commands):0] command_counter;
// Definir un contador para controlar el envío de caracteres a la CGRAM
reg [$clog2(char_data):0] char_counter;
// Definir un contador para controlar el envío de cada dato
reg [$clog2(data_mem_size):0] data_counter;
// Definir un contador para controlar el envío de comandos
reg [$clog2(num_cgram_addrs):0] cgram_addrs_counter;

// Banco de registros
reg [7:0] data_memory [0: data_mem_size-1];
reg [7:0] config_memory [0:config_commands-1]; 
reg [7:0] cgram_addrs [0: num_cgram_addrs-1];
reg init_config_executed;


initial begin
    fsm_state <= IDLE;
    data <= 'b0;
    command_counter <= 'b0;
    char_counter <= 'b0;
    data_counter <= 'b0;
    rw <= 0;
	rs <= 0;
    clk_16ms <= 'b0;
    counter_div_freq <= 'b0;
    init_config_executed <= 1'b0;
    done_cgram_write <= 'b0;
    $readmemh("/home/dnmaldonador/Documents/2024_digital_I/projects/LCD1602_cust_char/data.txt", data_memory);    
	config_memory[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_memory[1] <= DISPON_CURSOROFF;
	config_memory[2] <= CLEAR_DISPLAY;
    cgram_addrs[0] <= CGRAM_ADDR0;
    cgram_addrs[1] <= CGRAM_ADDR1;
    cgram_addrs[2] <= CGRAM_ADDR2;
    cgram_addrs[3] <= CGRAM_ADDR3;
    cgram_addrs[4] <= CGRAM_ADDR4;
    cgram_addrs[5] <= CGRAM_ADDR5;
    cgram_addrs[6] <= CGRAM_ADDR6;
    create_char_task <= SET_CGRAM_ADDR;
    cgram_addrs_counter <= 'b0; 
end

always @(posedge clk) begin
    if (counter_div_freq == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        counter_div_freq <= 0;
    end else begin
        counter_div_freq <= counter_div_freq + 1;
    end
end


always @(posedge clk_16ms)begin
    if(reset == 0)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next;
    end
end

always @(*) begin
    case(fsm_state)
        IDLE: begin
            next <= (ready_i)? ((init_config_executed)? CREATE_CHARS : INIT_CONFIG) : IDLE;
        end
        INIT_CONFIG: begin 
            next <= (command_counter == config_commands)? CREATE_CHARS : INIT_CONFIG;
        end
        CREATE_CHARS:begin
            next <= (done_cgram_write)? SET_CURSOR : CREATE_CHARS;
        end
        SET_CURSOR: begin 
            next <= SHOW;
        end
        SHOW: begin
            next <= IDLE;
        end
        default: next = IDLE;
    endcase
end

always @(posedge clk_16ms) begin
    if (reset == 0) begin
        command_counter <= 'b0;
        char_counter <= 'b0;
		data <= 'b0;
        init_config_executed <= 0;
        $readmemh("/home/dnmaldonador/Documents/2024_digital_I/projects/LCD1602_cust_char/data.txt", data_memory);
    end else begin
        case (next)
            IDLE: begin
                command_counter <= 'b0;
                char_counter <= 'b0;
                data <= 'b0;
                rs <= 'b0;
            end
            INIT_CONFIG: begin
                rs <= 'b0;
                command_counter <= command_counter + 1;
			    data <= config_memory[command_counter];
                if(command_counter == config_commands-1) begin
                    init_config_executed <= 1'b1;
                end
            end
            CREATE_CHARS: begin
                case(create_char_task)
                    SET_CGRAM_ADDR: begin 
                        rs <= 'b0; data <= cgram_addrs[cgram_addrs_counter]; create_char_task <= WRITE_CGRAM; 
                        char_counter <= 'b0;
								cgram_addrs_counter <= cgram_addrs_counter + 1;
                    end
                    WRITE_CGRAM: begin
                        rs <= 1; 
				        data <= data_memory[data_counter];
                        if(char_counter == char_data-1) begin
                            if(cgram_addrs_counter == num_cgram_addrs) begin
                                done_cgram_write <= 1'b1; 
                                cgram_addrs_counter <= 1'b0;
                            end else begin
                                create_char_task <= SET_CGRAM_ADDR;
                            end
                        end else begin
                            char_counter <= char_counter + 1;
                            data_counter <= data_counter + 1;
                        end
                    end
                endcase
            end
            SET_CURSOR: begin
                char_counter <= 'b0;
                data_counter <= 'b0;
					 rs <= 0; data <= 8'h81;
            end
            SHOW: begin
                rs <= 1; 
					 data <=  8'h00;
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule
