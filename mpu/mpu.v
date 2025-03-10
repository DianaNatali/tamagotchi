module mpu6050_i2c (
    input wire clk,          
    input wire rst_n,        
    input wire start,        
    inout wire sda,         
    output reg scl,          
    output reg [7:0] data_out, 
    output reg data_valid
);

    
    localparam  IDLE = 3'b000;
    localparam  START = 3'b001;
    localparam  ADDR = 3'b010;
    localparam  ACK1 = 3'b011;
    localparam  DATA = 3'b100;
    localparam  ACK2 = 3'b101;
    localparam  STOP = 3'b110;

    reg [2:0] state;
    reg [2:0] next_state;

    localparam MPU6050_ADDR = 7'h68;
    localparam REG_ADDR = 8'h3B;     

    reg [7:0] addr_reg;      
    reg [7:0] data_reg;      
    reg [3:0] bit_cnt;       
    reg ack;                 

    reg [8:0] clk_div;
    wire i2c_clk;

    reg sda_out;            
    reg sda_oe;              
    assign sda = (sda_oe) ? sda_out : 1'bz;

    assign i2c_clk = (clk_div == 9'd249); 

    always @(posedge clk) begin
        if (!rst_n) begin
            scl <= 1'b1; 
        end else if (i2c_clk) begin
            if (state == IDLE || state == START || state == STOP) begin
                scl <= 1'b1; 
            end else begin
                scl <= ~scl; 
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            clk_div <= 9'd0;
        end else begin
            if (clk_div == 9'd249) begin
                clk_div <= 9'd0;
            end else begin
                clk_div <= clk_div + 9'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = START;
                end
            end
            START: begin
                if (i2c_clk) begin
                    next_state = ADDR;
                end
            end
            ADDR: begin
                if (bit_cnt == 4'd7 && i2c_clk) begin
                    next_state = ACK1;
                end
            end
            ACK1: begin
                if (i2c_clk) begin
                    next_state = DATA;
                end
            end
            DATA: begin
                if (bit_cnt == 4'd7 && i2c_clk) begin
                    next_state = ACK2;
                end
            end
            ACK2: begin
                if (i2c_clk) begin
                    next_state = STOP;
                end
            end
            STOP: begin
                if (i2c_clk) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
            data_out <= 8'd0;
            data_valid <= 1'b0;
            addr_reg <= 8'd0;
            data_reg <= 8'd0;
            bit_cnt <= 4'd0;
            ack <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    sda_oe <= 1'b1;
                    data_valid <= 1'b0;
                end
                START: begin
                    if (i2c_clk) begin
                        sda_out <= 1'b0;
                        sda_oe <= 1'b1;
                    end
                end
                ADDR: begin
                    if (i2c_clk) begin
                        sda_out  <= MPU6050_ADDR[6-bit_cnt];
                        sda_oe <= 1'b1;
                        bit_cnt <= bit_cnt + 4'd1;
                    end
                end
                ACK1: begin
                    if (i2c_clk) begin
                        sda_oe <= 1'b0; 
                    end
                end
                DATA: begin
                    if (i2c_clk) begin
                        sda_out <= REG_ADDR[7-bit_cnt]; 
                        sda_oe <= 1'b1;
                        bit_cnt <= bit_cnt + 4'd1;
                    end
                end
                ACK2: begin
                    if (i2c_clk) begin
                        sda_oe <= 1'b0; 
                    end
                end
                STOP: begin
                    if (i2c_clk) begin
                        sda_out <= 1'b1; 
                        sda_oe <= 1'b1;
                        data_valid <= 1'b1;
                        data_out <= data_reg; 
                    end
                end
            endcase
        end
    end

endmodule