//`include "ultrasonic_controller.v"
//`include "display.v"

module top_ultrasonic(
        input clk,
        input rst,
        input ready_i,
        input echo_i,
        output trigger_o,
        output led_o
    );

    wire [15:0] echo_counter;
	reg led_reg;
    wire measure_cont;
    reg led_state;

    initial begin
        led_reg <= 'b0;
        led_state <= 'b0;
    end


    ultrasonic_controller ultrasonic0 (
        .clk(clk),
        .ready_i(ready_i),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .echo_counter(echo_counter)
    );


    always @(posedge clk) begin
        if (echo_counter < 100) begin
            led_reg <= 1'b0;
        end else if  (echo_counter > 200)  begin
            led_reg <= 1'b1;
        end
    end

    assign led_o = led_reg;

endmodule