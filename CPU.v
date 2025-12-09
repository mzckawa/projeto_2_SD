// arquivo para a FSM da CPU 

module CPU (input clk, input botao_ligar, input botao_ligar_agora, input botao_enviar_agora, input [2:0] instrucao, output ) 

parameter estado_aguardando = 0,
estado_gravando = 1,
estado_decodificando = 2,
estado_executando = 3,
estado_escrevendo = 4,
estado_preparando_lcd = 5,
estado_exibindo = 6;

reg [2:0] estado; 

reg sistema_ligado = 0;

wire flag_ligar;
wire flag_enviar;

detector_botao detector_ligar (.clk(clk), .botao_agora(botao_ligar_agora), .flag_botao(flag_ligar));

detector_botao detector_enviar(.clk(clk), .botao_agora(botao_enviar_agora), .flag_botao(flag_enviar));

always@(posedge clk) begin

    // primeiro, vamos verificar se o o sistema está ligado. Só depois disso iremos para a FSM em si

    if(flag_ligar) begin

        sistema_ligado <= ~sistema_ligado; // em qualquer situação, o botão vai inverter o atual estado do sistema

        // se, após a inversão, sistema_ligado==1, significa que precisamos LIGAR a CPU
        if(sistema_ligado) begin
            

    end


    
    case(estado) 

    if(estado == estado_desligado) begin
        if(detector_ligar) begin
        
        end
    end 
    endcase 


end

// Lógica das saídas 


endmodule