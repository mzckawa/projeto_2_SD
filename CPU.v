// arquivo para a FSM da CPU 

module CPU (input clk, input botao_ligar_agora, input botao_enviar_agora, input [2:0] instrucao, output reg flag_clear, ) 

parameter estado_desligado = 0,
estado_ligado = 1,
estado_aguardando = 2,
estado_gravando = 3,
estado_decodificando = 4,
estado_executando = 5,
estado_escrevendo = 6,
estado_preparando_lcd = 7,
estado_exibindo = 8;

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
        // lembrete: essa inversão ocorrerá, somente, ao FINAL do ciclo do clock 

        // se o sistema estava ligado, vamos desligá-lo (a lógica abaixo irá acontecer antes do bit sistema_ligado ser invertido)
        if(sistema_ligado) begin
            estado <= estado_desligado;
        end

        else begin
            estado <= estado_ligado;
        end

        // agora, sim, o corpo majoritário da lógica da FSM da CPU

        if(sistema_ligado) begin
            
            case(estado)

            estado_desligado: begin
                // vazio, indicando que não deve ser feita nenhuma mudança
            end

            estado_ligado: begin
                estado <= estado_aguardando;
            end 

            estado_aguardando begin
                estado <= (flag_enviar) ? estado_decodificando : estado_aguardando;
            end 

            estado_gravando: begin
                estado <= estado_decodificando;
            end 

            estado_decodificando: begin
                estado <= estado_executando;
            end

            estado_executando: begin 
                estado <= estado_escrevendo;
            end

            estado_escrevendo: begin
                estado <= estado_preparando_lcd;
            end

            estado_preparando_lcd: begin
                estado <= estado_exibindo;
            end

            estado_exibindo: begin
                estado <= estado_aguardando;
            end
        
            endcase
        end 
    end
end

// Lógica das saídas 
always@(posedge clk) begin

if(estado == estado_ligado) begin 
    // lógica de ace
end
end

endmodule