module ultrasonic_controller #(parameter TIME_TRIG = 500, parameter DISTANCE_CM = 400000, parameter CLOCK_FREQ = 50_000_000, SOUND_SPEED = 343)(
        input clk,
        input ready_i,
        input echo_i,
        output trigger_o,
        output reg [15:0] echo_counter
    );

    localparam IDLE = 2'b00;
    localparam TRIGGER = 2'b01;
    localparam WAIT_ECHO = 2'b10;
    localparam COUNT_ECHO = 2'b11;

    reg [1:0] state;
    wire trigger_done;

    wire idle_wait;
    wire trig_wait;
    wire echo_wait;
    wire count_echo;

    reg [$clog2(TIME_TRIG)-1:0] count_10us;
    //reg [$clog2(DISTANCE_CM)-1:0] echo_counter;
    reg echo_counter_done;
    reg led_reg;

    initial begin
        count_10us <= 'b0;
        state <= IDLE;
		echo_counter <= 'b0;
        echo_counter_done <= 'b0;
        led_reg <= 'b0;
    end

    always @(posedge clk) begin
            case(state)
                IDLE: begin
                    state <= (ready_i)? TRIGGER : state;
                end
                TRIGGER: begin
                    state <= (trigger_done)? WAIT_ECHO : state;
                end
                WAIT_ECHO: begin
                    state <= (echo_i)? COUNT_ECHO : state;
                end
                COUNT_ECHO: begin
                    state <= (echo_i)? state : IDLE;
                end
            endcase
        end
        
    assign idle_wait = (state == IDLE);
    assign trig_wait = (state == TRIGGER);
    assign echo_wait = (state == WAIT_ECHO);
    assign count_echo = (state == COUNT_ECHO);
	 
	
    assign trigger_o = trig_wait;

    assign trigger_done = (count_10us == TIME_TRIG-1);

    always @(posedge clk) begin
        if (idle_wait) begin
                count_10us <= 'b0;
            end else begin
                count_10us <= count_10us + {9'd0, (|count_10us | trig_wait)};
            end
    end


    always @(posedge clk) begin
        if (echo_wait) begin
            echo_counter <= 'b0;
        end else if (count_echo) begin
            echo_counter <= echo_counter +1;
        end
    end

endmodule
