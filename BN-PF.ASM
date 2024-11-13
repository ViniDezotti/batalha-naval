; Vinicius Brilhante Dezotti - RA 19049154

TITLE BATALHA_NAVAL
.MODEL SMALL
.STACK 100h

; ################################### Macros ###################################
PULA_LINHA MACRO
    PUSH DX
    MOV AH,2
    MOV DL,0AH
    INT 21h
    MOV DL,0Dh
    INT 21h
    POP DX
ENDM

SALVA_REGS MACRO R1,R2,R3,R4
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
ENDM        

RET_REGS MACRO R1,R2,R3,R4
    POP R1
    POP R2
    POP R3
    POP R4
ENDM   

; Macro para imprimir strings
; - STRING: texto desejado
PRINT_STR MACRO STRING
    MOV AH,9
    LEA DX,STRING
    INT 21h
ENDM

; Macro para imprimir espaços X vezes
; - QUANT: quantidade de espaços
PRINT_ESPACO MACRO QUANT
    LOCAL LOCAL_LOOP
    PUSH CX
    PUSH DX
    PUSH AX
    MOV CX,QUANT
    MOV DL,' '
    MOV AH,2

    LOCAL_LOOP:
        INT 21h
        LOOP LOCAL_LOOP
    POP AX
    POP DX
    POP CX
ENDM

; Macro para inserir embarcação (Encouraçado, Fragata ou Submarino)
; - LINHA: linha do tabuleiro onde se inicia a embarcação
; - COLUNA: coluna inicial do tabuleiro
; - TAMANHO: tamanho da embarcação (Encouraçado = 4, Fragata = 3, Submarino = 2)
INSERE_EMBARCACAO MACRO LINHA,COLUNA,TAMANHO
    LOCAL LOCAL_LOOP
    MOV AX,LINHA
    MOV BL,COLUNA
    MOV CX,TAMANHO

    MOV SI,AX       ; SI = linha

    MOV AL,10
    MUL BL
    MOV BX,AX       ; BX = coluna

    LOCAL_LOOP:
        MOV MAT_GABARITO[BX][SI],1
        INC SI
        LOOP LOCAL_LOOP
ENDM

; Macro para inserir um hidroavião em formato "T" voltado para a direita
; - LINHA: linha do tabuleiro onde o centro do "T" se inicia
; - COLUNA: coluna onde o centro do "T" se inicia
INSERE_HIDROAVIAO MACRO LINHA, COLUNA
    LOCAL PARTE_HORIZONTAL, PARTE_VERTICAL
    MOV AX,LINHA
    MOV BL,COLUNA
    MOV SI,AX       ; SI = linha

    MOV AL,10
    MUL BL
    MOV BX,AX       ; BX = coluna

    MOV MAT_GABARITO[BX][SI],1
    ADD BX,10
    MOV MAT_GABARITO[BX][SI],1
    INC SI
    MOV MAT_GABARITO[BX][SI],1
    ADD BX,10
    DEC SI
    MOV MAT_GABARITO[BX][SI],1
ENDM

.DATA
; ################################### Mensagens ###################################
MSG_INTRO_TITLE     DB "            ==== { Batalha naval } ====$"
MSG_INTRO_SUBTITLE  DB 10,13,"Destrua as embarcacoes para ganhar$"
MSG_INTRO_REGRAS    DB 10,13,"Regras: $"
MSG_INTRO_REGRA_1   DB 10,13,"- Digite uma linha (A-J) quando solicitado $"
MSG_INTRO_REGRA_2   DB 10,13,"- Digite uma coluna (1-10) quando solicitado $"
MSG_INTRO_REGRA_3   DB 10,13,"- Para encerrar o jogo, pressione ENTER quando for solicitado uma linha $"

MSG_INTRO_HASH      DB 10,13,"Digite um numero de 0 a 9 para sortear um tabuleiro: $" 
MSG_TIRO_LINHA      DB 10,13,"Digite a linha do tiro: $"
MSG_TIRO_COLUNA     DB 10,13,"Digite a coluna do tiro: $"

; ################################### Variaveis e constantes ###################################
MAT_TABULEIRO       DB 10 DUP(10 DUP(0))
MAT_GABARITO        DB 10 DUP(10 DUP(0))
ALVOS               DB 19
TIROS               DB 0

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    CALL TELA
    CALL INICIALIZA_JOGO 
    MOV AH,4Ch
    INT 21h
MAIN ENDP

; ################################### Imprime tabuleiro ###################################
IMPRIME PROC
    ; Cabecalho indice das colunas (0-9)
    MOV AH,2
    MOV CX,10
    MOV DH,'0'

    PULA_LINHA
    PRINT_ESPACO 5
    HEADER_COLUNA:
        MOV DL,DH
        INT 21h
        PRINT_ESPACO 2
        INC DH
        LOOP HEADER_COLUNA

    ; Impressão da matriz
    MOV CL,10                                   ; Contador de linhas
    XOR BX,BX                                   ; Endereço inicial da linha
    MOV DL,'A'

    PULA_LINHA
    PULA_LINHA
    LOOP_LINHA:
        XOR SI,SI                               ; Endereço inicial da coluna
        MOV CH,10                               ; Contador de colunas

        ; Indice das linhas (A-J)
        PRINT_ESPACO 2
        INT 21h                                 ; Imprime letra correspondente a linha
        PUSH DX
        PRINT_ESPACO 2

        ; Impressão da matriz
        LOOP_COLUNA:
            MOV AL,MAT_GABARITO[BX][SI]         ; Carrega o valor da célula atual em AL
            CMP AL,0
            JE  CASA_NAO_JOGADA                 ; Se AL = 0, jogador ainda nao atirou nela
            CMP AL,1
            JE CASA_ATINGIDA                    ; Se AL = 1, jogador já acertou um barco
            CMP AL,2
            JE CASA_VAZIA                       ; Se AL = 2, jogador já acertou a água

            JMP PROXIMO                         ; Pula para a próxima célula se nenhuma condição foi atendida
            CASA_NAO_JOGADA:
                MOV DL,219
                JMP PRINT_CHAR
            CASA_ATINGIDA:
                MOV DL,'X'
                JMP PRINT_CHAR

            CASA_VAZIA:
                MOV DL,' '              ; Caractere para 2

            PRINT_CHAR:
                INT 21h                 ; Imprime o caractere em DL

            PROXIMO:
                PRINT_ESPACO 2
                INC SI
                DEC CH
                JNZ LOOP_COLUNA         ; Repete até completar a linha

        PULA_LINHA           
        PULA_LINHA
        ADD BX,10
        POP DX
        INC DL
        DEC CL
        JZ SAI_LOOP_LINHA
        JMP LOOP_LINHA                  ; Repete até completar todas as linhas

    SAI_LOOP_LINHA:
        RET
IMPRIME ENDP

; ################################### Limpa tela ###################################
TELA PROC
    MOV AH,0
    MOV AL,3
    INT 10h
    MOV AH,6
    INT 10h
    RET
TELA ENDP

; ################################### Inicializa jogo ###################################
; Mostrará mensagens iniciais e pedirá um número (hash) para escolher o tabuleiro
INICIALIZA_JOGO PROC
    PRINT_STR MSG_INTRO_TITLE
    PULA_LINHA
    PRINT_STR MSG_INTRO_SUBTITLE
    PULA_LINHA
    PRINT_STR MSG_INTRO_REGRAS
    PRINT_STR MSG_INTRO_REGRA_1
    PRINT_STR MSG_INTRO_REGRA_2
    PRINT_STR MSG_INTRO_REGRA_3
    PULA_LINHA

    XOR DX,DX
    MOV CX,4

    ; Sorteia tabuleiro de acordo com o número (0-9) inserdo pelo user
    LE_HASH:
        PRINT_STR MSG_INTRO_HASH
        MOV AH,1
        INT 21h
        AND AL,0Fh
        CMP AL,0
        JL LE_HASH
        CMP AL,9
        JG LE_HASH

        MOV BL,4
        DIV BL

        CMP AH,0
        JE CALL_TABULEIRO1
        CMP AH,1
        JE CALL_TABULEIRO2
        CMP AH,2
        JE CALL_TABULEIRO3
        CMP AH,3
        JE CALL_TABULEIRO4
    RET

CALL_TABULEIRO1:
    CALL CARREGAR_TABULEIRO1
    JMP END_CALL_TABULEIRO

CALL_TABULEIRO2:
    CALL CARREGAR_TABULEIRO2
    JMP END_CALL_TABULEIRO

CALL_TABULEIRO3:
    CALL CARREGAR_TABULEIRO3
    JMP END_CALL_TABULEIRO

CALL_TABULEIRO4:
    CALL CARREGAR_TABULEIRO4
    
    JMP END_CALL_TABULEIRO

END_CALL_TABULEIRO:
    CALL IMPRIME
    RET
INICIALIZA_JOGO ENDP

; ################################### Tabuleiros ###################################
; Alocar as embarcações no Tabuleiro 1
CARREGAR_TABULEIRO1 PROC
    INSERE_EMBARCACAO 1, 1, 4         ; Encouraçado
    INSERE_EMBARCACAO 4, 6, 3         ; Fragata
    INSERE_EMBARCACAO 7, 3, 2         ; Submarino 1
    INSERE_EMBARCACAO 8, 7, 2         ; Submarino 2
    INSERE_HIDROAVIAO 1, 3            ; Hidroavião 1
    INSERE_HIDROAVIAO 1, 7            ; Hidroavião 2
    RET
CARREGAR_TABULEIRO1 ENDP

; Alocar as embarcações no Tabuleiro 2
CARREGAR_TABULEIRO2 PROC
    INSERE_EMBARCACAO 1, 1, 4         ; Encouraçado
    INSERE_EMBARCACAO 4, 5, 3         ; Fragata
    INSERE_EMBARCACAO 6, 2, 2         ; Submarino 1
    INSERE_EMBARCACAO 8, 8, 2         ; Submarino 2
    INSERE_HIDROAVIAO 1, 3            ; Hidroavião 1
    INSERE_HIDROAVIAO 5, 7            ; Hidroavião 2
    RET
CARREGAR_TABULEIRO2 ENDP

; Alocar as embarcações no Tabuleiro 3
CARREGAR_TABULEIRO3 PROC
    INSERE_EMBARCACAO 0, 4, 4         ; Encouraçado
    INSERE_EMBARCACAO 4, 1, 3         ; Fragata
    INSERE_EMBARCACAO 1, 2, 2         ; Submarino 1
    INSERE_EMBARCACAO 8, 3, 2         ; Submarino 2
    INSERE_HIDROAVIAO 2, 7            ; Hidroavião 1
    INSERE_HIDROAVIAO 5, 4            ; Hidroavião 2
    RET
CARREGAR_TABULEIRO3 ENDP

; Alocar as embarcações no Tabuleiro 4
CARREGAR_TABULEIRO4 PROC
    INSERE_EMBARCACAO 4, 5, 4         ; Encouraçado
    INSERE_EMBARCACAO 5, 2, 3         ; Fragata
    INSERE_EMBARCACAO 8, 0, 2         ; Submarino 1
    INSERE_EMBARCACAO 7, 8, 2         ; Submarino 2
    INSERE_HIDROAVIAO 1, 3            ; Hidroavião 1
    INSERE_HIDROAVIAO 4, 7            ; Hidroavião 2
    RET
CARREGAR_TABULEIRO4 ENDP

; ################################### Lógica do jogo ###################################
; JOGO PROC
;     XOR
;     IMPRIME:

; JOGO ENDP
END MAIN

