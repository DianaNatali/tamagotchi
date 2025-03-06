`timescale 1ns / 1ps
`include "servo4.v"

module tb_servo_enable;
    reg clk;
    reg [1:0] switches;
    wire servo;

    servo_n_pos uut (
        .clk(clk),
        .switches(switches),
        .servo(servo)
    );

    always #10 clk = ~clk; 

    initial begin
        clk = 0;
        switches = 0;
        #50000000;
        switches = 2;
    end

    initial begin: TEST_CASE
        $dumpfile("servo_controller_tb.vcd");
        $dumpvars(-1, uut);
        #(125000000) $finish;
    end

endmodule

