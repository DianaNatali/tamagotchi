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

    // Instancia del módulo a probar
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

    // Generación de reloj
    always #5 clk = ~clk;

    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        start = 0;
        miso = 0;
        
        #20 rst = 0; // Desactivar reset
        #10 start = 1; // Iniciar proceso
        #10 start = 0;
    end

    always @(posedge sck) begin
        if (!cs) begin
            // Simular respuesta del RC522 (datos recibidos en MISO)
            case (uut.state)
                uut.DETECT: miso <= 1; // Simular que hay tarjeta
                uut.ANTICOLLISION: miso <= 8'hAB; // Respuesta simulada UID byte 1
                uut.READ_UID: begin
                    case (uut.uid[31:24])
                        8'h00: miso <= 8'hCD; // UID byte 2
                        8'hAB: miso <= 8'hEF; // UID byte 3
                        8'hCD: miso <= 8'h12; // UID byte 4
                        default: miso <= 8'h00;
                    endcase
                end
            endcase
        end
    end
    
    initial begin
        #500; // Esperar la simulación
        $display("UID leído: %h", uid);
        $finish;
    end
endmodule
