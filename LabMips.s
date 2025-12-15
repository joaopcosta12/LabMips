.data
    # --- ÁREA DE MEMÓRIA RAM (VARIÁVEIS GLOBAIS) ---

    # Vetor de Estoque: Lista com 8 posições. Cada posição começa com 5.
    estoque_array: .word 5, 5, 5, 5, 5, 5, 5, 5
    
    # Vetor de Preços: 8 preços. Valores pares para o troco funcionar com nota de 2.
    precos_array:  .word 6, 4, 2, 8, 4, 6, 8, 2
    
    # Variável que guarda o lucro total (começa em R$ 0).
    total_caixa:   .word 0

    # Texto de topo do menu
    msg_topo:      .asciiz "\n========================================\n       VENDING MACHINE (8 ITENS)       \n========================================\n"
    
    # Menu Principal (lista dos itens)
    msg_menu:      
        .ascii  "1. Batata       (R$ 6)\n"
        .ascii  "2. Refrigerante (R$ 4)\n"
        .ascii  "3. Doce         (R$ 2)\n"
        .ascii  "4. Chocolate    (R$ 8)\n"
        .ascii  "5. Suco         (R$ 4)\n"
        .ascii  "6. Sanduiche    (R$ 6)\n"
        .ascii  "7. Energetico   (R$ 8)\n"
        .asciiz "8. Agua         (R$ 2)\n"
    
    # Mensagem de Input (Onde o usuário escolhe a opção)
    msg_input:     .asciiz "\nEscolha uma opcao (1-8) ou 0 Finalizar Compra: "
    
    # Mensagens para o Pagamento (Cédulas)
    msg_insira_notas: .asciiz "\n--- INSIRA AS CEDULAS ---\n"
    msg_qtd_20:       .asciiz "Quantas notas de R$ 20? "
    msg_qtd_10:       .asciiz "Quantas notas de R$ 10? "
    msg_qtd_5:        .asciiz "Quantas notas de R$  5? "
    msg_qtd_2:        .asciiz "Quantas notas de R$  2? "
    
    msg_total_inserido: .asciiz "Total inserido: R$ "
    
    # Mensagens para o Troco (Detalhado)
    msg_calc_troco: .asciiz "\n--- CALCULANDO TROCO ---\n"
    msg_t_20:       .asciiz " nota(s) de R$ 20\n"
    msg_t_10:       .asciiz " nota(s) de R$ 10\n"
    msg_t_5:        .asciiz " nota(s) de R$  5\n"
    msg_t_2:        .asciiz " nota(s) de R$  2\n"
    
    # Feedback
    msg_sucesso:   .asciiz "\n[SUCESSO] Retire seu produto!\n"
    msg_erro_est:  .asciiz "\n[ERRO] Item esgotado.\n"
    msg_erro_din:  .asciiz "\n[ERRO] Valor insuficiente. Devolvendo notas...\n"
    
    # Mensagens de Administrador
    msg_admin:     .asciiz "\n*** ACESSO ADMINISTRATIVO ***\n1. Ver Caixa\n2. Sacar Caixa\n3. Ver Estoque\n4. Repor Item\n5. Reset Total\nOpcao: "
    msg_caixa:     .asciiz "\n[ADMIN] O valor no caixa eh: R$ " # Mensagem corrigida
    msg_caixa_sacada: .asciiz "\n[ADMIN] Sacado: R$ "
    msg_reset:     .asciiz "\n[ADMIN] Estoque reabastecido.\n"
    msg_estoque_atual: .asciiz "\n[ADMIN] ESTOQUE ATUAL:\n"
    msg_reposicao_item: .asciiz "\n[ADMIN] Reposicao: Qual item (1-8)? "
    msg_acao:      .asciiz "[ADMIN] Adicionar [1] ou Retirar [0]? "
    msg_nova_qtd:  .asciiz "[ADMIN] Quantidade: "
    msg_sucesso_repo: .asciiz "\n[ADMIN] Estoque atualizado.\n"
    msg_separador: .asciiz " | " 
    
.text
.globl main

# ==============================================================================
# MAIN (PONTO DE ENTRADA E LOOP PRINCIPAL)
# ==============================================================================
main:
    # 1. Mostra o Menu
    jal mostrar_menu            # Pula para função que imprime as opções

    # 2. Pede o Input
    li $v0, 4                   # Prepara para imprimir texto
    la $a0, msg_input           # Carrega o endereço da pergunta
    syscall                     # Imprime

    # 3. Lê o número
    li $v0, 5                   # Prepara para ler um número
    syscall
    move $s0, $v0               # Salva o número digitado em $s0 (seguro)

    # 4. Roteamento de Saída
    beqz $s0, finaliza_compra   # SE input for 0, vai para o rótulo de encerrar
    beq $s0, 9999, modo_admin   # SE input for 9999, vai para o menu Admin

    # 5. Validação de Venda
    blt $s0, 1, main            # Se for menor que 1 (e não for 0), volta
    bgt $s0, 8, main            # Se for maior que 8, volta

    # 6. Ajuste de Índice (1..8 -> 0..7)
    sub $s1, $s0, 1             # $s1 é o índice real do vetor

    # 7. Executa a Venda
    jal processar_venda         # Pula para a função de venda
    j main                      # Volta para o início (cria o loop)

# ==============================================================================
# FUNÇÃO: PROCESSAR VENDA
# Cuida da transação completa.
# ==============================================================================
processar_venda:
    # --- SALVAR ESTADO NA PILHA ---
    # Para garantir que o loop principal (main) funcione, salvamos TUDO que vamos
    # usar, incluindo o endereço de retorno ($ra).
    addi $sp, $sp, -20          # Abre espaço na pilha ($sp = Stack Pointer)
    sw $ra, 16($sp)             # Salva o endereço de retorno da main
    sw $s0, 12($sp)             # Salva $s0
    sw $s1, 8($sp)              # Salva $s1 (o índice)
    sw $t2, 4($sp)              # Salva $t2 (preço)
    sw $t3, 0($sp)              # Salva $t3 (endereço de estoque)

    # --- CÁLCULO DE ENDEREÇO E BUSCA DE DADOS ---
    mul $t0, $s1, 4             # Multiplica índice por 4 (bytes)

    la $t1, precos_array        # Pega endereço da lista de preços
    add $t1, $t1, $t0
    lw $t2, 0($t1)              # $t2 = Preço do Produto

    la $t3, estoque_array       # Pega endereço da lista de estoque
    add $t3, $t3, $t0
    lw $t4, 0($t3)              # $t4 = Quantidade Atual

    # 1. Checagem de Estoque
    blez $t4, erro_estoque      # Se Qtd <= 0, erro

    # 2. Chama a função de Pagamento Detalhado
    jal receber_pagamento_cedulas
    move $t5, $v1               # $t5 = Total pago (vem da função)

    # 3. Checagem de Dinheiro
    blt $t5, $t2, erro_grana    # Se Pago < Preço, erro

    # --- VENDA CONCLUÍDA (ATUALIZAÇÃO DE MEMÓRIA) ---
    
    # 4. Diminui Estoque
    sub $t4, $t4, 1
    sw $t4, 0($t3)              # Grava o novo valor no vetor (Memória)

    # 5. Atualiza Caixa
    lw $t7, total_caixa
    add $t7, $t7, $t2
    sw $t7, total_caixa         # Grava o novo valor no cofre

    # 6. Prepara Troco
    sub $t6, $t5, $t2           # Troco = Total Pago - Preço
    
    li $v0, 4
    la $a0, msg_sucesso
    syscall

    # 7. Calcula Troco em Cédulas
    move $a0, $t6               # Passa o valor do troco como argumento
    jal calcular_troco_cedulas

    # 8. Pausa de 3 segundos
    li $v0, 32
    li $a0, 3000
    syscall

    # --- RECUPERAR ESTADO DA PILHA E SAIR ---
    lw $ra, 16($sp)             # Traz de volta o endereço de retorno
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $t2, 4($sp)
    lw $t3, 0($sp)
    addi $sp, $sp, 20           # Fecha o espaço na pilha

    jr $ra                      # Volta para 'main'

# --- TRATAMENTO DE ERROS (Recupera a Pilha e Volta) ---
erro_estoque:
    li $v0, 4
    la $a0, msg_erro_est
    syscall
    
    lw $ra, 16($sp)             # Recupera $ra para voltar ao menu
    addi $sp, $sp, 20
    jr $ra

erro_grana:
    li $v0, 4
    la $a0, msg_erro_din
    syscall
    
    lw $ra, 16($sp)             # Recupera $ra para voltar ao menu
    addi $sp, $sp, 20
    jr $ra

# ==============================================================================
# FUNÇÃO: RECEBER PAGAMENTO (Soma as notas)
# Retorna o total em $v1
# ==============================================================================
receber_pagamento_cedulas:
    li $t9, 0                   # $t9 = Acumulador (começa em zero)

    li $v0, 4
    la $a0, msg_insira_notas
    syscall

    # Pergunta Nota de 20
    li $v0, 4
    la $a0, msg_qtd_20
    syscall
    li $v0, 5
    syscall
    mul $t8, $v0, 20            # Qtd * 20
    add $t9, $t9, $t8           # Soma ao total

    # Pergunta Nota de 10
    li $v0, 4
    la $a0, msg_qtd_10
    syscall
    li $v0, 5
    syscall
    mul $t8, $v0, 10
    add $t9, $t9, $t8

    # Pergunta Nota de 5
    li $v0, 4
    la $a0, msg_qtd_5
    syscall
    li $v0, 5
    syscall
    mul $t8, $v0, 5
    add $t9, $t9, $t8

    # Pergunta Nota de 2
    li $v0, 4
    la $a0, msg_qtd_2
    syscall
    li $v0, 5
    syscall
    mul $t8, $v0, 2
    add $t9, $t9, $t8

    # Mostra total inserido
    li $v0, 4
    la $a0, msg_total_inserido
    syscall
    li $v0, 1
    move $a0, $t9
    syscall
    li $v0, 11
    li $a0, 10
    syscall

    move $v1, $t9               # Coloca o total em $v1 para retornar
    jr $ra

# ==============================================================================
# FUNÇÃO: CALCULAR TROCO (Lógica de Paridade para Notas)
# Recebe o valor total do troco em $a0
# ==============================================================================
calcular_troco_cedulas:
    move $t0, $a0               # $t0 = Troco que falta devolver
    
    li $v0, 4
    la $a0, msg_calc_troco
    syscall

    # --- 1. NOTAS DE 20 ---
    li $t1, 20
    div $t0, $t1                # Divide Troco por 20
    mflo $t2                    # $t2 = Quantidade de notas
    mfhi $t0                    # $t0 = Resto
    
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, msg_t_20
    syscall

    # --- 2. NOTAS DE 10 ---
    li $t1, 10
    div $t0, $t1
    mflo $t2
    mfhi $t0
    
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, msg_t_10
    syscall

    # --- 3. NOTAS DE 5 (Decisão de Paridade) ---
    li $t8, 2
    div $t0, $t8
    mfhi $t9                    # $t9 = Resto da divisão por 2 (0=Par, 1=Ímpar)
    
    # Se for PAR, não usa 5 (pois 5 transformaria o troco PAR em ÍMPAR)
    beqz $t9, pula_nota_5
    # Se for ÍMPAR, garante que o resto é >= 5 para poder usar a nota
    blt $t0, 5, pula_nota_5
    
    # Se for ÍMPAR e >= 5, usamos UMA nota de 5 para tornar o resto PAR
    li $t2, 1
    sub $t0, $t0, 5
    j imprime_nota_5

pula_nota_5:
    li $t2, 0                   # 0 notas de 5

imprime_nota_5:
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, msg_t_5
    syscall

    # --- 4. NOTAS DE 2 ---
    # Agora o troco restante ($t0) é garantidamente PAR
    li $t1, 2
    div $t0, $t1
    mflo $t2
    mfhi $t0                    # O resto aqui deve ser 0
    
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, msg_t_2
    syscall

    jr $ra

# ==============================================================================
# FUNÇÕES DE ADMINISTRAÇÃO
# ==============================================================================

# 1. VER CAIXA
ver_caixa:
    li $v0, 4
    la $a0, msg_caixa
    syscall
    lw $a0, total_caixa
    li $v0, 1
    syscall
    li $v0, 32
    li $a0, 3000
    syscall
    j main

# 2. SACAR CAIXA (Limpa o cofre)
sacar_caixa:
    lw $t0, total_caixa
    li $v0, 4
    la $a0, msg_caixa_sacada
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $t1, 0
    sw $t1, total_caixa
    li $v0, 32
    li $a0, 3000
    syscall
    j main

# 4. REPOR ITEM ESPECÍFICO (Adicionar ou Retirar)
adicionar_estoque:
    li $v0, 4
    la $a0, msg_reposicao_item
    syscall
    li $v0, 5
    syscall
    move $s1, $v0               # Item
    blt $s1, 1, adicionar_estoque
    bgt $s1, 8, adicionar_estoque
    
    li $v0, 4
    la $a0, msg_acao            # Ação (1/0)
    syscall
    li $v0, 5
    syscall
    move $t0, $v0
    
    li $v0, 4
    la $a0, msg_nova_qtd        # Qtd
    syscall
    li $v0, 5
    syscall
    move $t3, $v0
    
    # Calcula endereço
    sub $t1, $s1, 1
    mul $t1, $t1, 4
    la $t2, estoque_array
    add $t2, $t2, $t1
    lw $t4, 0($t2)
    
    # Roteia Ação
    beq $t0, 1, executa_adicao
    beq $t0, 0, executa_retirada
    j main

executa_adicao:
    add $t4, $t4, $t3
    j salvar_novo_estoque

executa_retirada:
    sub $t4, $t4, $t3
    blt $t4, 0, zerar_estoque
    j salvar_novo_estoque

zerar_estoque:
    li $t4, 0
    
salvar_novo_estoque:
    sw $t4, 0($t2)
    li $v0, 4
    la $a0, msg_sucesso_repo
    syscall
    j main

# 5. RESETAR TODO O ESTOQUE (Volta todos para 5)
reset_estoque_total:
    la $t0, estoque_array
    li $t1, 5
    li $t2, 8
loop_reset:
    beqz $t2, fim_reset
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    sub $t2, $t2, 1
    j loop_reset
fim_reset:
    li $v0, 4
    la $a0, msg_reset
    syscall
    j main

# 3. VER ESTOQUE (Lista formatada verticalmente)
ver_estoque_detalhe:
    li $v0, 4
    la $a0, msg_estoque_atual
    syscall
    la $t0, estoque_array
    li $t1, 1
    li $t2, 8
loop_estoque_det:
    beqz $t2, fim_estoque_det
    
    li $v0, 1
    move $a0, $t1               # Imprime o número do Item (1, 2, 3...)
    syscall
    
    li $v0, 4
    la $a0, msg_separador       # Imprime " | "
    syscall
    
    li $v0, 1
    lw $a0, 0($t0)              # Carrega e Imprime a Quantidade
    syscall
    
    li $v0, 11
    li $a0, 10                  # Imprime caractere de Nova Linha (\n)
    syscall
    
    addi $t0, $t0, 4            # Avança o ponteiro do vetor (próximo item)
    addi $t1, $t1, 1            # Avança o contador visual
    addi $t2, $t2, -1
    j loop_estoque_det

fim_estoque_det:
    li $v0, 4
    la $a0, msg_topo 
    syscall
    j main

# ==============================================================================
# FINALIZAÇÃO
# ==============================================================================

# Função para Sair do Programa (chamada quando digita 0)
finaliza_compra:
    li $v0, 10                  # Syscall 10 = Encerra a Execução
    syscall
