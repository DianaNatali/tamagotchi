`include "spi_master.v"

module rc522_controller (
    input wire clk,        
    input wire rst,        
    input wire start,      
    output reg [31:0] uid, 
    output reg done,       
    output wire cs,         
    output wire sck,        
    output wire mosi,       
    input wire miso        
);

    localparam IDLE = 3'b000; 
    localparam INIT = 3'b001; 
    localparam DETECT = 3'b010; 
    localparam ANTICOLLISION = 3'b011;
    localparam READ_UID = 3'b100; 
    localparam DONE = 3'b101;

    reg [2:0] state, next_state;

    reg [7:0] spi_data_out;
    wire [7:0] spi_data_in;

    reg spi_start;
    wire spi_done;

    // reg [7:0] config_commands [0:]

    initial begin
        state <= IDLE;
        done <= 'b0;
        spi_data_out <= 'b0;
        uid <= 'b0;
    end

    spi_master spi (
        .clk(clk),
        .rst(rst),
        .start(spi_start),
        .data_in(spi_data_out),
        .data_out(spi_data_in),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .spi_done(spi_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                next_state = (start)? INIT : IDLE;
            end
            INIT: begin
                next_state = (spi_done)? DETECT : INIT;
            end
            DETECT: begin
                next_state = (spi_done)? ANTICOLLISION : DETECT;
            end
            ANTICOLLISION: begin
                next_state = (spi_done)? READ_UID : ANTICOLLISION;
            end
            READ_UID: begin
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if(rst)begin
            uid <= 32'h00000000;
            done <= 0;
        end else begin
            case(next_state)
                IDLE: begin
                    done = 0;
                end
                INIT: begin
                    spi_start = 1;
                    spi_data_out = 8'h0F;
                end
                DETECT: begin
                    spi_start = 1;
                    spi_data_out = 8'h26; 
                end
                ANTICOLLISION: begin
                    spi_start = 1;
                    spi_data_out = 8'h93;
                end
                READ_UID: begin
                    spi_data_out = 8'h00;
                    uid = {uid[23:0], spi_data_in}; // Guarda el UID leído
                end
                DONE: begin
                    done = 1;
                end
            endcase
        end

    end
endmodule
