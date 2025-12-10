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