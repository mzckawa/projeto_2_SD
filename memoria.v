module memoria(input clk, input enable, input [3:0] endereco_reg1, input [3:0] endereco_reg2, input [3:0] endereco_escrita, input [15:0] conteudo_escrita, output [15:0] conteudo_reg1, output [15:0] conteudo_reg2, )
begin

// nota sobre os argumentos acima: separamos inputs de leitura e de escrita para evitar bugs, pois eles serao lidos de porções diferentes da instrução, além de um ser feito de forma síncrona e outro, de forma assíncrona 

// criando o banco de memória 16X16 
reg [15:0] banco_mem [15:0];

// atualizando os endereços lidos assincronamente
assign conteudo_reg1 = banco_mem[endereco_reg1];
assign conteudo_reg2 = banco_mem[endereco_reg2];

// escrita síncrona (sujeita ao clock e ao enable estar ativo)
always@(posedge clk) begin
if (enable) begin banco_mem[endereco_escrita] <= conteudo_escrita; end
end


endmodule