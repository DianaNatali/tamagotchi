module ultrasonic_controller #(parameter TIME_TRIG = 500, parameter DISTANCE_CM = 400000, parameter CLOCK_FREQ = 50_000_000, SOUND_SPEED = 343)(
    input clk,
    input rst,
    input ready_i,
    input echo_i,
    output wire trigger_o,
    output reg [31:0] echo_counter
);

localparam IDLE = 2'b00;
localparam TRIGGER = 2'b01;
localparam WAIT_ECHO = 2'b10;
localparam COUNT_ECHO = 2'b11;

reg [1:0] fsm_state;
reg [1:0] next_state;
wire trigger_done;

wire idle_wait;
wire trig_wait;
wire echo_wait;
wire count_echo;

reg [$clog2(TIME_TRIG)-1:0] count_10us;

initial begin
    count_10us <= 'b0;
    fsm_state <= IDLE;
    next_state <= IDLE;
    echo_counter <= 'b0;
end

always @(negedge clk)begin
    if(rst) begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

always @(*) begin
    case(fsm_state)
        IDLE: next_state <= (ready_i)? TRIGGER : next_state;
        TRIGGER: next_state <= (trigger_done)? WAIT_ECHO : next_state;
        WAIT_ECHO: next_state <= (echo_i)? COUNT_ECHO : next_state;
        COUNT_ECHO: next_state <= (echo_i)? next_state : IDLE;
    endcase
end

always @(negedge clk) begin
    if(rst)begin 
        count_10us <= 'b0;;
    end else begin
        case(next_state)
            IDLE: begin
                count_10us <= 'b0;
            end
            TRIGGER: begin
                count_10us <= count_10us + 'b1;
            end
            WAIT_ECHO: begin
                echo_counter <= 'b0;
            end
            COUNT_ECHO: begin
                echo_counter <= echo_counter +1;
            end
        endcase
    end
end
 

assign trigger_o = (next_state == TRIGGER);
assign trigger_done = (count_10us == TIME_TRIG);

endmodule
