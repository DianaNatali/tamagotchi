`include "ultrasonic_controller.v"

module top_ultrasonic(
        input clk,
        input rst,
        input ready_i,
        input echo_i,
        output wire trigger_o,
        output wire led_o
    );

    wire [31:0] echo_counter;
	reg led_reg;

    initial begin
        led_reg <= 'b0;
    end


    ultrasonic_controller ultrasonic0 (
        .clk(clk),
        .rst(rst),
        .ready_i(ready_i),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .echo_counter(echo_counter)
    );


    always @(posedge clk) begin
        if(rst)begin
            led_reg <= 1'b0;
        end else if (echo_counter < 100) begin
            led_reg <= 1'b0;
        end else if  (echo_counter > 100)  begin
            led_reg <= 1'b1;
        end
    end

    assign led_o = led_reg;

endmodule