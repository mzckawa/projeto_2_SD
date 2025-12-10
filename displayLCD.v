module displayLCD (
    input wire clk,
    input wire rst, // Reset Geral (Vem de ~sistema_ligado)
    input wire btn_send, // Pulso ativo em nível alto vindo da CPU (detector_botao)
    input wire [2:0] op_selc,
    input wire [3:0] logger,
    input wire signed [15:0] result,

    output reg [7:0] lcd_data,
    output reg lcd_rs,
    output reg lcd_rw,
    output reg lcd_e
);

    // Registradores Internos
    reg [2:0] reg_op;
    reg [3:0] reg_logger;
    reg signed [15:0] reg_result;

    // Comandos LCD
    localparam [7:0] CMD_FUNC_SET = 8'h38;
    localparam [7:0] CMD_DISP_ON = 8'h0C;
    localparam [7:0] CMD_CLEAR = 8'h01;
    localparam [7:0] CMD_ENTRY = 8'h06;

    // Timings
    localparam [31:0] D_INIT_WAIT = 32'd2_500_000;
    localparam [31:0] D_CMD_STD = 32'd2_500;
    localparam [31:0] D_CMD_CLR = 32'd100_000;
    localparam [31:0] D_PULSE = 32'd50;

    reg [7:0] cmd_rom [0:3];
    initial begin
        cmd_rom[0] = CMD_FUNC_SET;
        cmd_rom[1] = CMD_DISP_ON;
        cmd_rom[2] = CMD_CLEAR;
        cmd_rom[3] = CMD_ENTRY;
    end

    // --- CONVERSOR BCD ---
    wire [15:0] magnitude = (reg_result < 0) ? -reg_result : reg_result;
    wire [3:0] w_d4, w_d3, w_d2, w_d1, w_d0;

    binario_bcd conversor (
        .binario(magnitude),
        .dezemilhar(w_d4),
        .milhar(w_d3),
        .centena(w_d2),
        .dezena(w_d1),
        .unidade(w_d0)
    );

    // --- GERAÇÃO DA MENSAGEM ---
    reg [7:0] message [0:31];
    integer i;

    always @(*) begin
        // Limpa buffer com espaços
        for(i=0; i<32; i=i+1)
            message[i] = " ";

        // Primeiros 4 chars: operação
        case (reg_op)
            3'b000: begin message[0]="L"; message[1]="O"; message[2]="A"; message[3]="D"; end
            3'b001: begin message[0]="A"; message[1]="D"; message[2]="D"; message[3]=" "; end
            3'b010: begin message[0]="A"; message[1]="D"; message[2]="D"; message[3]="I"; end
            3'b011: begin message[0]="S"; message[1]="U"; message[2]="B"; message[3]=" "; end
            3'b100: begin message[0]="S"; message[1]="U"; message[2]="B"; message[3]="I"; end
            3'b101: begin message[0]="M"; message[1]="U"; message[2]="L"; message[3]="T"; end
            3'b110: begin message[0]="C"; message[1]="L"; message[2]="R"; message[3]=" "; end
            3'b111: begin message[0]="D"; message[1]="P"; message[2]="L"; message[3]=" "; end
            default:begin message[0]="E"; message[1]="R"; message[2]="R"; message[3]="O"; end
        endcase

        // Logger [Rxxx]
        message[10] = "[";
        message[11] = (reg_logger[3]) ? "1" : "0";
        message[12] = (reg_logger[2]) ? "1" : "0";
        message[13] = (reg_logger[1]) ? "1" : "0";
        message[14] = (reg_logger[0]) ? "1" : "0";
        message[15] = "]";

        // Resultado na direita
        message[26] = (reg_result < 0) ? "-" : "+";
        message[27] = 8'h30 + w_d4;
        message[28] = 8'h30 + w_d3;
        message[29] = 8'h30 + w_d2;
        message[30] = 8'h30 + w_d1;
        message[31] = 8'h30 + w_d0;
    end

    // --- FSM PRINCIPAL ---
    localparam [4:0]
        S_OFF = 5'd0,
        S_INIT_START = 5'd1,
        S_INIT_PULSE = 5'd2,
        S_INIT_WAIT = 5'd3,
        S_IDLE = 5'd4,
        S_SYNC_CPU = 5'd5,
        S_CMD_ADDR = 5'd6,
        S_CMD_PULSE = 5'd7,
        S_CMD_WAIT = 5'd8,
        S_DATA_WRITE = 5'd9,
        S_DATA_PULSE = 5'd10,
        S_DATA_WAIT = 5'd11,
        S_WAIT_RELEASE = 5'd12;

    reg [4:0] state, next_state;
    reg [31:0] cnt, next_cnt;
    reg [2:0] cmd_idx, next_cmd_idx;
    reg [5:0] msg_idx, next_msg_idx;
    reg load_inputs;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= S_OFF;
            cnt <= 0;
            cmd_idx <= 0;
            msg_idx <= 0;
            reg_op <= 0;
            reg_logger <= 0;
            reg_result <= 0;
        end
        else begin
            state <= next_state;
            cnt <= next_cnt;
            cmd_idx <= next_cmd_idx;
            msg_idx <= next_msg_idx;

            if (load_inputs) begin
                reg_op <= op_selc;
                reg_logger <= logger;
                reg_result <= result;
            end
        end
    end

    always @(*) begin
        next_state = state;
        next_cnt = cnt;
        next_cmd_idx = cmd_idx;
        next_msg_idx = msg_idx;
        load_inputs = 0;

        case(state)
            S_OFF: begin
                next_cnt = 0;
                next_state = S_INIT_START;
            end

            // Inicialização
            S_INIT_START: begin
                if (cnt < D_INIT_WAIT)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    next_cmd_idx = 0;
                    next_state = S_INIT_PULSE;
                end
            end

            S_INIT_PULSE: begin
                if (cnt < D_PULSE)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    next_state = S_INIT_WAIT;
                end
            end

            S_INIT_WAIT: begin
                if (cnt < (cmd_idx == 2 ? D_CMD_CLR : D_CMD_STD))
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    if (cmd_idx < 3) begin
                        next_cmd_idx = cmd_idx + 1;
                        next_state = S_INIT_PULSE;
                    end
                    else begin
                        next_msg_idx = 0;
                        next_state = S_CMD_ADDR;
                    end
                end
            end

            // Estado Ocioso
            S_IDLE: begin
                if (btn_send) begin // Detectou aperto (pulso)
                    next_cnt = 0;
                    next_state = S_SYNC_CPU;
                end
            end

            // Sincronia: Espera a CPU travar (latch) os dados
            S_SYNC_CPU: begin
                if (cnt < 32'd1000)
                    next_cnt = cnt + 1; // ~20us
                else begin
                    load_inputs = 1; // Captura agora!
                    next_msg_idx = 0;
                    next_cnt = 0;
                    next_state = S_CMD_ADDR;
                end
            end

            // Rotina de Escrita
            S_CMD_ADDR: begin
                if (msg_idx == 0 || msg_idx == 16) begin
                    next_cnt = 0;
                    next_state = S_CMD_PULSE;
                end
                else begin
                    next_cnt = 0;
                    next_state = S_DATA_WRITE;
                end
            end

            S_CMD_PULSE: begin
                if (cnt < D_PULSE)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    next_state = S_CMD_WAIT;
                end
            end

            S_CMD_WAIT: begin
                if (cnt < D_CMD_STD)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    next_state = S_DATA_WRITE;
                end
            end

            S_DATA_WRITE: begin
                next_cnt = 0;
                next_state = S_DATA_PULSE;
            end

            S_DATA_PULSE: begin
                if (cnt < D_PULSE)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    next_state = S_DATA_WAIT;
                end
            end

            S_DATA_WAIT: begin
                if (cnt < D_CMD_STD)
                    next_cnt = cnt + 1;
                else begin
                    next_cnt = 0;
                    if (msg_idx == 31)
                        next_state = S_WAIT_RELEASE;
                    else begin
                        next_msg_idx = msg_idx + 1;
                        next_state = S_CMD_ADDR;
                    end
                end
            end

            // Trava final: só volta quando soltar o botão (em nível)
            S_WAIT_RELEASE: begin
                if (!btn_send)
                    next_state = S_IDLE;
            end

            default: begin
                next_state = S_OFF;
            end
        endcase
    end

    // Saídas
    always @(*) begin
        lcd_e = 0;
        lcd_rs = 0;
        lcd_rw = 0;
        lcd_data = 0;

        case(state)
            S_INIT_PULSE: begin
                lcd_e = 1;
                lcd_data = cmd_rom[cmd_idx];
            end

            S_INIT_WAIT: begin
                lcd_data = cmd_rom[cmd_idx];
            end

            S_CMD_PULSE: begin
                lcd_e = 1;
                lcd_data = (msg_idx == 0) ? 8'h80 : 8'hC0;
            end

            S_CMD_WAIT: begin
                lcd_data = (msg_idx == 0) ? 8'h80 : 8'hC0;
            end

            S_DATA_PULSE: begin
                lcd_e = 1;
                lcd_rs = 1;
                lcd_data = message[msg_idx];
            end

            S_DATA_WAIT: begin
                lcd_rs = 1;
                lcd_data = message[msg_idx];
            end
        endcase
    end
endmodule
	
