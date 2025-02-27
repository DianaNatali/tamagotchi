module spi_master (
    input wire clk,         
    input wire rst,         
    input wire start,       
    input wire [7:0] data_in, 
    output reg [7:0] data_out, 
    output reg sck,         
    output reg mosi,        
    input wire miso,        
    output reg cs           
);
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sck <= 0;
            cs <= 1;
            bit_cnt <= 0;
            busy <= 0;
            shift_reg <= 0;
            data_out <= 0;
        end else if (start && !busy) begin
            cs <= 0;
            busy <= 1;
            shift_reg <= data_in;
            bit_cnt <= 0;
        end else if (busy) begin
            sck <= ~sck;
            if (sck) begin
                mosi <= shift_reg[7];
                shift_reg <= {shift_reg[6:0], miso};
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 7) begin
                    data_out <= {shift_reg[6:0], miso};
                    busy <= 0;
                    cs <= 1;
                end
            end
        end
    end
endmodule
