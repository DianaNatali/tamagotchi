module dht11_controller #(parameter WAIT_READ=25000000, 
                                    INIT_PULSE_DOWN=2250000, 
                                    INIT_PULSE_UP=3750,
                                    WAIT_RESPONSE_INIT=18125, //teniendo ene cuenta q S3 esta durando 145us
                                    WAIT_50u = 6250,
                                    ZERO_24u=3000, 
                                    ONE_70u=8750)(
    input wire clk,               
    input wire rst,               
    inout wire dht11_io,         
    output reg [15:0] humidity,    
    output reg [15:0] temperature, 
    output reg valid,
    output reg [2:0] state
    // output reg [39:0] data_out
);

    reg [2:0] fsm_state;
    reg [2:0] next_state;
    reg [39:0] shift_reg;
    reg [5:0] bit_count;
    wire [5:0] reg_timer_bits;
    reg [$clog2(WAIT_READ)-1:0] timer_init; 
    reg [$clog2(INIT_PULSE_UP)-1:0] timer_start_up;
    reg [$clog2(INIT_PULSE_DOWN)-1:0] timer_start_down; 
    reg [$clog2(WAIT_RESPONSE_INIT)-1:0] timer_response; 
    reg [$clog2(WAIT_50u)-1:0] timer_wait_data; 
    reg [$clog2(ONE_70u)-1:0] timer_bits;
    reg bit_done;  
    reg [7:0] sum_reg; 
    reg [7:0] sum_reg1;
    reg [7:0] sum_reg2;
    reg [7:0] sum_reg3;
    reg [7:0] sum_reg4;  
    reg [7:0] sum_reg5;
    reg [7:0] checksum;                       

    reg dht11_out;
    wire dht11_dir;
    
    
    reg [2:0] count_clk50; // Contador de 2 bits
    reg clk_50M;

    always @(posedge clk) begin
        if (rst) begin
            count_clk50 <= 0;
            clk_50M <= 0;
        end else begin
            if (count_clk50 == 2) begin  // Alternar entre 2 y 3 ciclos
                count_clk50 <= 0;
                clk_50M <= ~clk_50M; // Cambia cada 2.5 ciclos en promedio
            end else begin
                count_clk50 <= count_clk50 + 1;
            end
        end
    end
      

    assign dht11_io = dht11_dir ? dht11_out : 1'bz;

    localparam IDLE          = 3'b000;
    localparam START_DOWN    = 3'b001;
    localparam START_UP      = 3'b010;
    localparam WAIT_RESPONSE = 3'b011;
    localparam RECEIVE_BITS  = 3'b100;
    localparam CHECKSUM      = 3'b101;

    initial begin
        dht11_out <= 1'b1;
        humidity <= 'b0;
        temperature <= 'b0;
        valid <= 1'b0;
        timer_init <= 'b0;
        timer_start_up <= 'b0;
        timer_start_down <= 'b0;
        timer_response <= 'b0;
        timer_wait_data <= 'b0;
        timer_bits <= 'b0;
        shift_reg <= 'b0;
        fsm_state <= IDLE;
        bit_done <= 'b0;
        clk_50M <= 'b0;
        count_clk50 <= 'b0;
        state <='b0;
        bit_count <='b0;
    end

    always @(posedge clk) begin
        if (rst) begin
            fsm_state <= IDLE;
        end else begin
            fsm_state <= next_state;
        end
    end

    always @(*) begin
        case(fsm_state)
            IDLE: begin 
                next_state = (timer_init == WAIT_READ)? START_DOWN : IDLE;
            end
            START_DOWN: begin
                next_state = (timer_start_down == INIT_PULSE_DOWN)? START_UP : START_DOWN;
            end
            START_UP: begin
                next_state = (timer_start_up == INIT_PULSE_UP)? WAIT_RESPONSE : START_UP;
            end
            WAIT_RESPONSE: begin
                next_state = (timer_response == WAIT_RESPONSE_INIT)? RECEIVE_BITS : WAIT_RESPONSE;
            end
            RECEIVE_BITS: begin
                next_state = (bit_count == 39)? CHECKSUM : RECEIVE_BITS;
            end
            CHECKSUM: begin
                next_state = (valid)? IDLE : CHECKSUM;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            dht11_out <= 1'b1;
            valid <= 1'b0;
            timer_init <= 'b0;
            timer_start_up <= 'b0;
            timer_start_down <= 'b0;
            timer_response <= 'b0;
            timer_wait_data <= 'b0;
            timer_bits <= 'b0;
            shift_reg <= 'b0;
            bit_done <= 1'b0;
            bit_count <='b0;
        end else begin
            case (next_state)
                IDLE: begin
                    valid <= 1'b0;
                    timer_init <= timer_init + 1;
                end
                START_DOWN: begin
                    dht11_out <= 1'b0;
                    timer_start_down <= timer_start_down + 1;
                end
                START_UP: begin
                    dht11_out <= 1'b1;
                    timer_start_up <= timer_start_up + 1;
                end
                WAIT_RESPONSE: begin
                    timer_response <= timer_response + 1;
                    timer_bits <= 'b0;
                end
                RECEIVE_BITS: begin
                    timer_bits <= 'b0;
                    if(dht11_io == 1'b1) begin
                        timer_bits <= timer_bits +1;
                    end 
                end
                CHECKSUM: begin
                    sum_reg1 <= shift_reg[7:0];
                    sum_reg2 <= shift_reg[15:8];
                    sum_reg3 <= shift_reg[23:16];
                    sum_reg4 <= shift_reg[31:24];
                    sum_reg5 <= shift_reg[39:32];
                    sum_reg <= shift_reg[7:0] + shift_reg[15:8] + shift_reg[23:16] + shift_reg[31:24];
                    checksum <= shift_reg[39:32];
                    valid <= (shift_reg[7:0] + shift_reg[15:8] + shift_reg[23:16] + shift_reg[31:24] == shift_reg[39:32]) ;
                end
            endcase
        end
    end

    assign dht11_dir = (fsm_state == START_UP || fsm_state == START_DOWN)? 1'b1 : 1'b0;

    
    always@(posedge clk)begin
        if(rst) begin
            timer_bits <= 'b0;
            bit_count <= 'b0;
        end else begin
            if (fsm_state == RECEIVE_BITS) begin
                if (reg_timer_bits == ONE_70u || reg_timer_bits == ZERO_24u) begin
                    shift_reg[bit_count] <=  (reg_timer_bits == ONE_70u) ? 1'b1 : 1'b0;
                    bit_count <= bit_count + 1;  
                end else if (fsm_state == CHECKSUM) begin
                    bit_count <= 'b0;
                end
            end
        end
    end

    assign reg_timer_bits = (dht11_io == 0)? timer_bits : 'b0;
   

    always@(posedge clk)begin
        if(rst)begin
            humidity <= 0;
            temperature <= 0;
        end else begin
            humidity <= shift_reg[15:0];
            temperature<= shift_reg[31:16];
        end
    end

    always@(posedge clk)begin
        if(rst)begin
            state = 'b0;
        end else begin
            state <= fsm_state;
        end
    end
        
endmodule
