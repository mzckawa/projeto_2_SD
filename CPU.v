// arquivo para a FSM da CPU 

module CPU (input botao_ligar, input botao_enviar, input [2:0] instrucao, output ) 

parameter state_desligado = 0,
state_iniciado = 1,
state_aguardando = 2,
state_gravando = 3,
state_decodificando = 4,
state_executando = 5,
state_escrevendo = 6,
state_preparando_lcd = 7,
state_exibindo = 8;

instrucao = 0; // começando no estado desligado (não há nada non display)

// Lógica da máquina de estados
always@(posedge clk) begin
    
    case(instrucao) 

    if(instrucao == state) begin
        
    endcase 


end

// Lógica das saídas 


endmodule