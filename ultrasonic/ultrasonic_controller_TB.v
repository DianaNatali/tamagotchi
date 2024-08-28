`timescale 1ns/1ps
`include "top_ultrasonic.v"

module top_ultrasonic_TB;
    reg clk;
    reg rst;
    reg echo;
    reg ready;

    top_ultrasonic uut (
        .clk(clk),
        .rst(rst),
        .ready_i(ready),
        .echo_i(echo)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        echo = 0;
        ready = 1;
        #10 rst = 1;
        #10 rst = 0;
        ready = 1;
        #13000 echo = 1;
        #2300 echo = 0;
        #13000 echo = 1;
        #2000 echo = 0;
    end

    initial begin: TEST_CASE
        $dumpfile("ultrasonic_TB.vcd");
        $dumpvars(-1, uut);
        #(100000) $finish;
    end


endmodule