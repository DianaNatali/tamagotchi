`timescale 1ns / 1ps
`include "dht11_controller.v"

module dht11_controller_TB();
    reg clk;
    reg rst;
    wire dht11_io;
    wire [15:0] data_o;
    wire valid;

    reg data_drive; // Señal para manejar data como entrada/salida
    reg data_out; 

    reg dht11_sim; 
    reg dht11_dir_sim; 

    dht11_controller #(2500, 9000, 15, 80, 25, 26, 29) uut (
        .clk(clk),
        .rst(rst), 
        .dht11_io(dht11_io),
        .data_out(data_o),
        .valid(valid)
    );

    assign dht11_io = data_drive ? data_out : 1'bz;

    initial begin
        clk = 0;
        rst = 0;
        data_drive = 0;
        #10 rst = 1;
        #10 rst = 0;

        wait(uut.fsm_state == 4);

        send_dht_data(8'h24, 8'h00, 8'h1A, 8'h2E, 8'h6C);
    end

    task send_dht_data;
        input [7:0] hum_int, hum_dec, temp_int, temp_dec, checksum;
        integer i;
        reg [39:0] full_data;
      begin
        full_data = {hum_int, hum_dec, temp_int, temp_dec, checksum};
        
        for (i = 39; i >= 0; i = i - 1) begin
          @(posedge clk);
          data_drive = 1;
          data_out = 0; 
          #500; 
          data_out = full_data[i]; 
          $display("i: %d | data_out: %b | full_data: %b", i, data_out, full_data);
          if (full_data[i])
            #700;
          else
            #240;
          data_out = 1;
          #500; 
        end
      end
    endtask

    always #10 clk = ~clk;

    initial begin: TEST_CASE
        $dumpfile("dht11_controller_tb.vcd");
        $dumpvars(-1, uut);
        //$monitor("Tiempo=%0t | dato=%d.%d| Valido=%b", $time, data_o, valid);
        #(350000) $finish;
    end

endmodule
