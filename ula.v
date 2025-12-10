module ula(input [7:0] A, input [7:0] B, input [2:0] opcode, output reg [6:0] res_com_sinal)
    
    localparam ADD = 3'b001;
    localparam ADDI = 3'b010;
    localparam SUB = 3'b011;
    localparam SUBI = 3'b100;
    localparam MUL = 3'b101;
    
    always@(*) // executa se alguns dos inputs do módulo mudar (A, B ou opcode)

    begin 
    res_com_sinal = 8'd0;
    if (opcode == ADD || opcode == ADDI)
    begin
    res_com_sinal = A + B;
    end 
    
    else if (opcode == SUB || opcode == SUBI)
    begin
    res_com_sinal = A - B;
    end 

    else if (opcode == MUL)
    begin
    res_com_sinal = A * B;
    end 
    end

endmodule

