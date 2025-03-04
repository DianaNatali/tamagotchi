module servo_pwm (
    input wire clk,        
    input wire rst,        
    input wire [7:0] angle, 
    output reg pwm_out    
);

    reg [19:0] counter = 0;      
    reg [19:0] pwm_high_time;   

    // Contador de 20ms (1,000,000 ciclos a 50 MHz)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
        end else if (counter >= 999999) begin
            counter <= 0;
        end  begin
            counter <= counter + 1;
        end
    end

    // Convertir el ángulo a ancho de pulso (1ms a 2ms)
    always @(*) begin
        pwm_high_time = 50000 + (angle * 278); // Escala de 50,000 a 100,000
    end

    // Generar señal PWM
    always @(posedge clk) begin
        if(rst)begin
            pwm_out <= 0;
        end else if (counter < pwm_high_time) begin
            pwm_out <= 1;
        end else begin
            pwm_out <= 0;
        end
    end

endmodule
