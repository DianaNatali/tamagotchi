`timescale 1ns / 1ps
`include "servo3.v"

module tb_servo_pwm;

    reg clk;
    reg rst;
    reg [7:0] angle;
    wire pwm_out;

    servo_pwm uut (
        .clk(clk),
        .rst(rst),
        .angle(angle),
        .pwm_out(pwm_out)
    );

    // Generar un reloj de 50MHz (20ns de período)
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        angle = 0;
        #100;  
        
        rst = 0;

        // Probar ángulo 0° 
        angle = 8'd0;
        #50000000; 

        // Probar ángulo 90° 
        angle = 8'd90;
        #50000000;

        // Probar ángulo 180° 
        angle = 8'd180;
        #50000000;
        $finish;
    end

    initial begin: TEST_CASE
        $dumpfile("servo_controller_tb.vcd");
        $dumpvars(-1, uut);
        #(105000000) $finish;
    end

endmodule

