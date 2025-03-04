module pwm4servo (input clk, sw1, sw2, output servo);

    reg [17:0] counter = 0;
    
    reg [17:0] position = 18480;
    
    wire inc_pos, dec_pos;
    
     
    
    tic switch1 (clk, sw1, inc_pos);
    
    tic switch2 (clk, sw2, dec_pos);
    
     
    
    always @(posedge clk)
    
    begin
    
      if (inc_pos == 1 && position <= 29280)
    
       position <= position + 1200;
    
      else if (dec_pos == 1 && position >= 7680)
    
       position <= position - 1200;
    
    end
    
     
    
    always @(posedge clk)
    
    begin
    
      if (counter < 240000) counter <= counter + 1;
    
      else counter <= 0;
    
    end
    
     
    
    assign servo = (counter < position) ? 1:0;
    
    endmodule
    
    
    module tic (input clk, btn_in, output out);
    
    reg d2;
    
    reg r_in;
    
    always @(posedge clk)
    
    d2 <= btn_in;
    
    always @(posedge clk)
    
     r_in <= d2;
    
    reg btn_prev = 0;
    
    reg btn_out = 0;
    
    reg [16:0] counter = 0;
    
    always @(posedge clk) begin
    
       if (btn_prev ^ r_in == 1'b1) begin
    
         counter <= 0;
    
         btn_prev <= r_in;
    
     end
    
     else if (counter[16] == 1'b0)
    
         counter <= counter + 1;
    
     else
    
         btn_out <= btn_prev;
    
     end
    
        
    reg old;
    
    always @(posedge clk)
    
     old <= btn_out;
    
    assign out = !old & btn_out;
    
    endmodule