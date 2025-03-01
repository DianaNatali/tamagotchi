`timescale 1ns / 1ps
`include "rfid_RC522.v"

module rc522_controller_tb;
    reg clk;
    reg rst;
    reg start;
    wire [31:0] uid;
    wire done;
    wire cs;
    wire sck;
    wire mosi;
    reg miso;

    rc522_controller uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .uid(uid),
        .done(done),
        .cs(cs),
        .sck(sck),
        .mosi(mosi),
        .miso(miso)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        start = 0;
        miso = 0;

        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;

        // wait(done);
        // #20;

        // #200 $stop;
    end

    reg [7:0] miso_data = 8'h3C; 
    reg [2:0] bit_index = 7;
    
    always @(posedge sck) begin
        if (!cs) begin
            miso <= miso_data[bit_index];
            if (bit_index == 0)
                bit_index <= 7;
            else
                bit_index <= bit_index - 1;
        end else begin
            bit_index <= 7;
        end
    end

    initial begin: TEST_CASE
        $dumpfile("rfid_controller_tb.vcd");
        $dumpvars(-1, uut);
        $display("UID leído: %h", uid);
        #(1000) $finish;
    end
endmodule
