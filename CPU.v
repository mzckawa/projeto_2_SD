// arquivo para a FSM da CPU 

module CPU (input clk, input botao_ligar_agora, 
input botao_enviar_agora, input [17:0] instrucao_completa, 
output reg flag_clear, output reg flag_escrever, output reg [7:0] lcd_data,  
output reg lcd_rs, output reg lcd_rw, output reg lcd_e) 

localparam estado_desligado = 4'd0,
estado_ligado = 4'd1,
estado_aguardando = 4'd2,
estado_gravando = 4'd3,
estado_decodificando = 4'd4,
estado_executando = 4'd5,
estado_escrevendo = 4'd6,
estado_preparando_lcd = 4'd7,
estado_exibindo = 4'd8;

reg [3:0] estado; 

reg sistema_ligado = 0;

wire flag_ligar;
wire flag_enviar;

// controle de memória
reg [3:0] reg_1_endereco;
reg [3:0] reg_2_endereco;
reg [3:0] escrita_endereco;

// dados que saem da memória
wire [15:0] reg_1_conteudo;
wire [15:0] reg_2_conteudo;

// entradas da ula
reg [15:0] operador_1;
reg [15:0] operador_2;
reg [2:0] codigo_instrucao;

// saída da ula (que irá virar entrada da memória)
wire [15:0] conteudo_resultado;

// fios do imediato 
wire sinal = instrucao_completa[6];
wire [5:0] modulo_imediato_curto = instrucao_completa[5:0];
wire [15:0] imediato_estendido; 

// tratando a diferença de tamanho do número que extraímos da instrução (6 bits de magnitude) e o tamanho que ele terá quando for guardado na memória (16 bits)
// além disso, dependendo do sinal, estamos guardando o número no formato de complemento de 2
assign imediato_estendido = (sinal) ? -{10'd0, modulo_imediato_curto} : {10'd0, modulo_imediato_curto};

memoria banco_memoria(.clk(clk), .enable(flag_escrever), 
.ativar_clear(flag_clear), .endereco_reg1(reg_1_endereco), 
.endereco_reg2(reg_2_endereco), .endereco_escrita(escrita_endereco), 
.conteudo_escrita(conteudo_resultado), .conteudo_reg1(reg_1_conteudo), .conteudo_reg2(reg_2_conteudo));

ula ula(.A(operador_1), .B(operador_2), .opcode(codigo_instrucao), .res_com_sinal(conteudo_resultado))

displayLCD LCD(.clk(clk), .rst(flag_clear), 
.btn_power(flag_ligar), .btn_send(flag_enviar), 
.op_selc(codigo_instrucao), .logger(escrita_endereco), 
result(conteudo_resultado), .lcd_data(lcd_data),
.lcd_rs(lcd_rs), .lcd_rw(lcd_rw),
.lcd_e(lcd_e));

module displayLCD (

input wire clk, // Clock do FPGA = 50MHz
input wire rst, // Reset (Ativo alto)

// Botões de Controle
input wire btn_power, // Botão Ligar
input wire btn_send, // Botão Enviar

// Entradas de Dados
input wire [2:0] op_selc, // Seletor das operações
input wire [3:0] logger, // Registrador de dados
input wire signed [15:0] result, // Resultado (sinal + módulo)

// Saídas LCD
output reg [7:0] lcd_data,  // Informação que podem ser dados ou comandos para o display
output reg lcd_rs, // Envio de comando = 0, Envio de dados = 1
output reg lcd_rw, // Write = 0, Read = 1 (só vmaos utilizar escrita)
output reg lcd_e // Pulso de Enable - quando o display recebe um pulso (0 -> 1 -> 0) ele registra o valor presente

);

detector_botao detector_ligar (.clk(clk), .botao_agora(botao_ligar_agora), .flag_botao(flag_ligar));
detector_botao detector_enviar(.clk(clk), .botao_agora(botao_enviar_agora), .flag_botao(flag_enviar));

always@(posedge clk) begin

    if(flag_ligar) begin
        sistema_ligado <= ~sistema_ligado; // em qualquer situação, o botão vai inverter o atual estado do sistema
        // lembrete: essa inversão ocorrerá, somente, ao FINAL do ciclo do clock 
    end
end


always@(posedge clk) begin

    // primeiro, vamos verificar se o o sistema precisa ser desligado. Só depois disso iremos para a FSM em si
    
    if(~sistema_ligado) begin
        estado <= estado_desligado;
    end

    else begin

            // agora, sim, o corpo majoritário da lógica da FSM da CPU
            case(estado)

            estado_desligado: begin // se chegou nesse else, é porque sistema_ligado == 1, logo, o estado do sistema deve ser LIGADO
                estado <= estado_ligado;
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



// Lógica das saídas (usamos always@(*) para que o "roteamento" dos fios aconteça instaneamente, sem depender do clock)
always@(*) begin

    // saídas padrão (para evitar bugs)
    reg_1_endereco = 0;
    reg_2_endereco = 0;
    escrita_endereco = 0;
    operador_1 = 0;
    operador_2 = 0;
    codigo_instrucao = 0;
    flag_escrever = 0;
    flag_clear = 0;

case(estado) 

    estado_desligado, estado_ligado: begin
        flag_clear = 1;
        flag_escrever = 0;
    end

    estado_aguardando: begin
        flag_clear = 0;
        flag_escrever = 0;
    end

    estado_gravando: begin
        flag_clear = 0;
        flag_escrever = 1;

        // lógica da gravação na memória:

        // operação aritmética com imediato
        if(instrucao_completa[17:15] != 3'b000) begin 
            codigo_instrucao = instrucao_completa[17:15];
            escrita_endereco = instrucao_completa[14:11];
            reg_1_endereco = instrucao_completa[10:7];
            reg_2_endereco = 0;

            operador_1 = reg_1_conteudo;
            operador_2 = imediato_estendido;

        end

        // load de memória com valor do imediato
        else if (instrucao_completa[17:11] == 6'b0000000) begin

            codigo_instrucao = instrucao_completa[13:11];
            escrita_endereco = instrucao_completa[10:7];
            operador_1 = 16'd0; // zerando por precaução
            reg_2_conteudo = imediato_estendido; 

        end

        // operação aritmética com números em registradores
        else begin
        
            codigo_instrucao = instrucao_completa[14:12];
            escrita_endereco = instrucao_completa[11:8];
            reg_1_endereco = instrucao_completa[7:4];
            reg_2_endereco = instrucao_completa[3:0];

            operador_1 = reg_1_conteudo;
            operador_2 = reg_2_conteudo;

    end
    end 

endcase

end

endmodule