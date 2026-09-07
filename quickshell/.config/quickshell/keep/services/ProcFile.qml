//  ARQUIVO DE /proc — o leitor de sensor do torreão.
//
//  Existe por dois motivos. O primeiro é chato e útil: sensor que não
//  existe nesta máquina é o caso comum, não erro, e `printErrors: false`
//  estava repetido em dezenove lugares.
//
//  O segundo é o que aprendemos medindo, e vale escrever para ninguém
//  tentar de novo:
//
//  O FileView é assíncrono. Cada reload() despacha para o QThreadPool
//  global e volta pelo event loop — e o pool tem `nproc` threads, doze
//  aqui. Com o torreão parado, essas doze respondiam por 0,45% dos
//  0,58% de CPU (72% do custo em repouso) e ~66 dos ~70 wakeups/s,
//  servindo dezenove leituras de /proc e /sys a cada dois segundos.
//
//  O caminho óbvio seria `blockAllReads: true`, que a documentação
//  descreve como leitura bloqueante. NÃO ADIANTA. Foi medido: com a
//  propriedade comprovadamente em `true` (conferido por IPC, não por
//  suposição), o pool continuou nos mesmos 0,5% e nos mesmos ~70
//  wakeups/s. O `blockAllReads` faz o `text()` esperar a leitura
//  pendente; ele não muda o despacho do reload(), que continua indo
//  para o pool. Não é a alavanca.
//
//  A alavanca é CADÊNCIA e CONTAGEM: os mesmos dezenove arquivos a
//  cada 60 s derrubaram o torreão para 0,03% de CPU e 3,7 wakeups/s.
//  É por isso que os serviços dividem a leitura entre o que a muralha
//  mostra e o que só o popup mostra — ver `Gpu.detailed`.

import Quickshell.Io

FileView {
    printErrors: false
}
