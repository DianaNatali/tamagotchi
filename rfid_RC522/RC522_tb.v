`timescale 1ns / 1ps

module rc522_tb();
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

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        miso = 0;
        
        #20 rst = 0; 
        #10 start = 1; 
        #10 start = 0;
    end

    always @(posedge sck) begin
        if (!cs) begin
            case (uut.state)
                uut.DETECT: miso <= 1; 
                uut.ANTICOLLISION: miso <= 8'hAB; 
                uut.READ_UID: begin
                    case (uut.uid[31:24])
                        8'h00: miso <= 8'hCD; 
                        8'hAB: miso <= 8'hEF; 
                        8'hCD: miso <= 8'h12;
                        default: miso <= 8'h00;
                    endcase
                end
            endcase
        end
    end
    
    initial begin
        #500; 
        $dumpfile("rfid_controller_tb.vcd");
        $dumpvars(-1, uut);
        $display("UID leído: %h", uid);
        $finish;
    end
endmodule
