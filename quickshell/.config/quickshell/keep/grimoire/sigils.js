// ═══════════════════════════════════════════════════════════════
//  SIGILOS — o cofre de símbolos do grimório.
//  Não é um seletor de emoji: é o que um programador realmente
//  precisa copiar (setas, matemática, caixas, tipografia), mais os
//  símbolos que dão cara ao rice. Cabe num arquivo, sem baixar
//  base de dados de emoji nenhuma.
// ═══════════════════════════════════════════════════════════════

.pragma library

var sigils = [
    // Setas
    ["→", "seta direita"], ["←", "seta esquerda"], ["↑", "seta cima"], ["↓", "seta baixo"],
    ["⇒", "implica"], ["⇐", "implicado"], ["⇔", "equivale"], ["↔", "bidirecional"],
    ["↺", "gira anti-horario"], ["↻", "gira horario"], ["⤷", "ramifica"], ["⇢", "tracejada"],

    // Matematica e logica
    ["≈", "aproximadamente"], ["≠", "diferente"], ["≤", "menor ou igual"], ["≥", "maior ou igual"],
    ["±", "mais ou menos"], ["×", "vezes"], ["÷", "dividido"], ["√", "raiz"],
    ["∞", "infinito"], ["∑", "somatorio"], ["∏", "produtorio"], ["∫", "integral"],
    ["∂", "derivada parcial"], ["∆", "delta"], ["∇", "nabla"], ["∅", "conjunto vazio"],
    ["∈", "pertence"], ["∉", "nao pertence"], ["⊂", "contido"], ["∪", "uniao"], ["∩", "intersecao"],
    ["∀", "para todo"], ["∃", "existe"], ["¬", "negacao"], ["∧", "e logico"], ["∨", "ou logico"],
    ["⊕", "ou exclusivo"], ["≡", "identico"], ["∴", "portanto"], ["∵", "porque"],

    // Gregas
    ["α","alfa"],["β","beta"],["γ","gama"],["δ","delta"],["ε","epsilon"],["θ","teta"],
    ["λ","lambda"],["μ","mu"],["π","pi"],["σ","sigma"],["τ","tau"],["φ","fi"],["ψ","psi"],["ω","omega"],
    ["Γ","Gama"],["Δ","Delta"],["Θ","Teta"],["Λ","Lambda"],["Π","Pi"],["Σ","Sigma"],["Ω","Omega"],

    // Tipografia
    ["—", "travessao"], ["–", "meia risca"], ["·", "ponto medio"], ["•", "marcador"],
    ["…", "reticencias"], ["«", "aspas abre"], ["»", "aspas fecha"], ["“", "aspas curva abre"],
    ["”", "aspas curva fecha"], ["‘", "simples abre"], ["’", "simples fecha"], ["†", "adaga"],
    ["‡", "adaga dupla"], ["§", "secao"], ["¶", "paragrafo"], ["©", "copyright"], ["®", "registrado"],
    ["™", "marca"], ["°", "grau"], ["‰", "por mil"], ["№", "numero"],

    // Caixas e blocos — desenhar diagrama no terminal
    ["─","linha"],["│","barra"],["┌","canto sup esq"],["┐","canto sup dir"],
    ["└","canto inf esq"],["┘","canto inf dir"],["├","tê esq"],["┤","tê dir"],
    ["┬","tê cima"],["┴","tê baixo"],["┼","cruz"],["═","linha dupla"],["║","barra dupla"],
    ["╭","canto arredondado"],["╮","canto arredondado dir"],["╰","canto arred inf esq"],["╯","canto arred inf dir"],
    ["█","bloco cheio"],["▓","bloco escuro"],["▒","bloco medio"],["░","bloco claro"],
    ["▁","um oitavo"],["▄","meio bloco"],["▀","meio bloco alto"],

    // Formas
    ["◈","losango"],["◇","losango vazio"],["◆","losango cheio"],["○","circulo"],["●","circulo cheio"],
    ["□","quadrado"],["■","quadrado cheio"],["△","triangulo"],["▲","triangulo cheio"],
    ["★","estrela"],["☆","estrela vazia"],["✓","certo"],["✗","errado"],["✚","cruz grossa"],

    // Do castelo
    ["†","cruz do brasao"],["⚔","espadas"],["⚑","estandarte"],["☠","caveira"],
    ["⚜","flor de lis"],["♔","rei"],["♚","rei negro"],["☾","lua"],["☽","lua crescente"],
    ["⌛","ampulheta"],["⚱","urna"],["⛧","sigilo"],["☤","caduceu"],

    // Dinheiro
    ["€","euro"],["£","libra"],["¥","iene"],["¢","centavo"],["₿","bitcoin"],["R$","real"]
];
