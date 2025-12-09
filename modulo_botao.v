module detector_botao(input clk, input botao_agora, output reg flag_botao)

reg botao_anterior = 1; // atribuindo 1 (solto) no início para evitar ruído

always@(posedge clk) begin

botao_anterior <= botao_agora;

// como os botões da placa são low level, precisamos detectar o momento em que  "botao_anterior" é 0 e "botao_agora" é 1
if(~botao_anterior && botao_agora) begin
    flag_botao <= 1;
end

else begin
flag_botao <= 0;
end

end 
endmodule