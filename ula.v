module ula(
    input [15:0] A, // 16 bits para casar com registradores
    input [15:0] B,
    input [2:0] opcode,
    output reg signed [15:0] res_com_sinal // 16 bits
);

    // Opcodes baseados no PDF
    localparam LOAD = 3'b000;
    localparam ADD = 3'b001;
    localparam ADDI = 3'b010;
    localparam SUB = 3'b011;
    localparam SUBI = 3'b100;
    localparam MUL = 3'b101;
    localparam CLR = 3'b110;
    localparam DISP = 3'b111;

    always@(*) begin
        res_com_sinal = 16'd0;
        case(opcode)
            // Load: O valor imediato (B) passa direto
            LOAD: res_com_sinal = B;

            // Aritmética
            ADD,
            ADDI: res_com_sinal = A + B;

            SUB,
            SUBI: res_com_sinal = A - B;

            MUL: res_com_sinal = A * B;

            // Clear: Retorna 0 (tratado na CPU também, mas aqui garante zero)
            CLR: res_com_sinal = 16'd0;

            // Display: Passa o valor do registrador (A)
            DISP: res_com_sinal = A;

            default: res_com_sinal = 16'd0;
        endcase
    end

endmodule
