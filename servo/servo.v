module servo_n_pos (
    input clk, 
    input [1:0] switches, 
    output servo
);

    reg [19:0] counter = 0;  
    reg [19:0] position = 0;  

    always @(posedge clk) begin
        case (switches)
            2'b00: position <= 27000;   
            2'b01: position <= 52000;   
            2'b10: position <= 77000;   
            2'b11: position <= 128000;  
        endcase
    end

    always @(posedge clk) begin
        if (counter < 1000000) 
            counter <= counter + 1;
        else 
            counter <= 0;
    end

    assign servo = (counter < position) ? 1 : 0;

endmodule
