`timescale 1ns / 1ps
`include "dht11_controller.v"

module dht11_controller_TB();
    reg clk;
    reg rst;
    wire dht11_io;
    wire [15:0] humidity;
    wire [15:0] temperature;
    wire valid;

    reg dht11_sim; 
    reg dht11_dir_sim; 

    dht11_controller #(2500, 9000, 15, 80, 25, 13, 35) uut (
        .clk(clk),
        .rst(rst), 
        .dht11_io(dht11_io),
        .humidity(humidity),
        .temperature(temperature),
        .valid(valid)
    );

    //assign dht11_io = dht11_dir_sim ? dht11_sim : 1'bz;

    initial begin
        clk = 0;
        rst = 0;
        #10 rst = 1;
        #10 rst = 0;
        // dht11_sim = 1;
        // dht11_dir_sim = 1;

        #2000000;   
        #10 rst = 1;
        #10 rst = 0;   
        // dht11_sim = 0;

        // #250600;

        // dht11_sim = 1;
        // #4600;

        // send_byte(8'b00110101); // 55 (Humedad entera)
        // send_byte(8'b00000000); // 0 (Humedad decimal)
        // send_byte(8'b00010111); // 23 (Temperatura entera)
        // send_byte(8'b00000000); // 0 (Temperatura decimal)
        // send_byte(8'b00110100); // Checksum (55 + 23 = 34h)

    end

    // // Procedimiento para enviar un byte simulando la señal del DHT11
    // task send_byte(input [7:0] byte);
    //     integer i;
    //     begin
    //         for (i = 7; i >= 0; i = i - 1) begin
    //             // Pulso bajo de ~50µs
    //             dht11_sim = 0;
    //             #26060;

    //             // Pulso alto: 26µs para '0', 70µs para '1'
    //             dht11_sim = 1;
    //             if (byte[i] == 1)
    //                 #4000; // Pulso alto largo para '1'
    //             else
    //                 #4000; // Pulso alto corto para '0'
    //         end
    //     end
    // endtask

    always #4 clk = ~clk;

    initial begin: TEST_CASE
        $dumpfile("dht11_controller_tb.vcd");
        $dumpvars(-1, uut);
        #(10000000) $finish;
    end


endmodule