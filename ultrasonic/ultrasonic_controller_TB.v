`timescale 1ns/1ps
`include "ultrasonic_controller.v"

module ultrasonic_controller_TB;
    reg clk;
    reg rst;
    reg echo;
    reg ready;
    wire [15:0] echo_counter;

    ultrasonic_controller uut (
        .clk(clk),
        .echo_counter(echo_counter),
        .ready_i(ready),
        .echo_i(echo)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        ready = 1;
        #10 rst = 0;
        #10 rst = 1;
        echo = 0;
        #13000 echo = 1;
        #1000 echo = 0;
        #13000 echo = 1;
        #4000 echo = 0;
    end

    initial begin: TEST_CASE
        $dumpfile("ultrasonic_controller_TB.vcd");
        $dumpvars(-1, uut);
        #(50000) $finish;
    end


endmodule