module LCD1602_cust_char #(parameter num_commands = 2, 
                                      num_data_all = 16,  
                                      char_data = 8,
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
localparam CMD1 = 1;
localparam WRITE_CGRAM = 2;
localparam SET_CURSOR = 3;
localparam SHOW = 4;
localparam CMD2 = 5;
localparam WRITE_CGRAM2 = 6;
localparam SET_CURSOR2 = 7;
localparam SHOW2 = 8;

reg [3:0] fsm_state;
reg [3:0] next;
reg clk_16ms;

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
localparam CGRAM_ADDR0 = 8'h40;

// Definir un contador para controlar el envío de comandos
reg [$clog2(num_commands):0] command_counter;
// Definir un contador para controlar el envío de cada dato
reg [$clog2(num_data_all):0] data_counter;

// Banco de registros
reg [7:0] data_memory [0: num_data_all-1];
reg [7:0] config_memory [0:num_commands-1]; 


initial begin
    fsm_state <= IDLE;
    data <= 'b0;
    command_counter <= 'b0;
    data_counter <= 'b0;
    rw <= 0;
	rs <= 0;
    clk_16ms <= 'b0;
    counter_div_freq <= 'b0;
    $readmemh("/home/dnmaldonador/Documents/2024_digital_I/projects/LCD1602_cust_char/data.txt", data_memory);    
	config_memory[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_memory[1] <= CGRAM_ADDR0;
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
            next <= (ready_i)? CMD1 : IDLE;
        end
        CMD1: begin 
            next <= (command_counter == num_commands)? WRITE_CGRAM : CMD1;
        end
        WRITE_CGRAM:begin
            next <= (data_counter == char_data)? SET_CURSOR : WRITE_CGRAM;
        end
        SET_CURSOR: begin 
            next <= SHOW;
        end
        SHOW: begin
            next <= CMD2;
        end
        CMD2: begin 
            next <= (command_counter == num_commands)? WRITE_CGRAM2 : CMD2;
        end
        WRITE_CGRAM2:begin
            next <= (data_counter == char_data)? SET_CURSOR2 : WRITE_CGRAM2;
        end
        SET_CURSOR2: begin 
            next <= SHOW2;
        end
        SHOW2: begin
            next <= CMD1;
        end
        default: next = IDLE;
    endcase
end

always @(posedge clk_16ms) begin
    if (reset == 0) begin
        command_counter <= 'b0;
        data_counter <= 'b0;
		data <= 'b0;
        $readmemh("/home/dnmaldonador/Documents/2024_digital_I/projects/LCD1602_cust_char/data.txt", data_memory);
    end else begin
        case (next)
            IDLE: begin
                command_counter <= 'b0;
                data_counter <= 'b0;
                data <= 'b0;
                rs <= 'b0;
				data <= CLEAR_DISPLAY;
            end
            CMD1: begin
                rs <= 'b0;
                command_counter <= command_counter + 1;
			    data <= config_memory[command_counter];
            end
            WRITE_CGRAM: begin
                command_counter <= 'b0;
                data_counter <= data_counter + 1; 
                rs <= 1;
                data <= data_memory[data_counter];
            end
            SET_CURSOR: begin
                data_counter <= 'b0;
			    rs <= 0; data <= 8'h80;
            end
            SHOW: begin
                rs <= 1; 
				data <=  8'h00;
            end
            CMD2: begin
                rs <= 'b0;
                command_counter <= command_counter + 1;
			    data <= config_memory[command_counter];
            end
            WRITE_CGRAM2: begin
                command_counter <= 'b0;
                data_counter <= data_counter + 1; 
                rs <= 1;
                data <= data_memory[data_counter + 8];
            end
            SET_CURSOR2: begin
                data_counter <= 'b0;
			    rs <= 0; data <= 8'h80;
            end
            SHOW2: begin
                rs <= 1; 
					 data <=  8'h00;
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule
