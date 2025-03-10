module as608_controller(
    input wire clk,         
    input wire rst,         
    input wire start_scan,  
    input wire [7:0] rx_data,  
    input wire rx_done,     
    output reg tx_start,    
    output reg [7:0] tx_data,  
    output reg match,       
    output reg error       
);
    localparam  IDLE = 3'b000; 
    localparam  SEND_CAPTURE_CMD = 3'b001; 
    localparam  WAIT_RESPONSE = 3'b010; 
    localparam  CHECK_RESULT = 3'b011; 
    
    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_start <= 0;
            match <= 0;
            error <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_scan) begin
                        tx_data <= 8'hEF; // Enviar comando (Ejemplo)
                        tx_start <= 1;
                        state <= SEND_CAPTURE_CMD;
                    end
                end
                
                SEND_CAPTURE_CMD: begin
                    tx_start <= 0;
                    state <= WAIT_RESPONSE;
                end

                WAIT_RESPONSE: begin
                    if (rx_done) begin
                        state <= CHECK_RESULT;
                    end
                end

                CHECK_RESULT: begin
                    if (rx_data == 8'h00) // Código de éxito del AS608
                        match <= 1;
                    else
                        error <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
