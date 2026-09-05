// Exercita services/parsers.js contra o /proc real desta máquina.
// Não é uma cópia da lógica: importa exatamente o arquivo que roda
// no shell. Rode com tools/test-parsers.sh.

import QtQml
import "../quickshell/.config/quickshell/keep/services/parsers.js" as P
import "../quickshell/.config/quickshell/keep/services/fuzzy.js" as F

QtObject {
    property int failures: 0

    function ok(name, cond, detail) {
        if (cond) {
            console.log("  ✓ " + name);
        } else {
            console.log("  ✗ " + name + (detail !== undefined ? "  -> " + detail : ""));
            failures++;
        }
    }

    function read(path) {
        const x = new XMLHttpRequest();
        x.open("GET", "file://" + path, false);
        x.send(null);
        return x.responseText;
    }

    Component.onCompleted: {
        console.log("\n/proc/stat");
        const first = P.stat(read("/proc/stat"), null);
        ok("primeira amostra nao inventa uso", first.usage === 0);
        ok("descobre os nucleos", first.cores.length > 0, first.cores.length);
        ok("um tick por nucleo", Object.keys(first.ticks).length === first.cores.length + 1);

        const a = "cpu  100 0 100 1000 0 0 0 0 0 0\ncpu0 10 0 10 100 0 0 0 0 0 0\nintr 1\n";
        const b = "cpu  200 0 200 1000 0 0 0 0 0 0\ncpu0 20 0 20 100 0 0 0 0 0 0\nintr 1\n";
        const c = "cpu  200 0 200 1100 0 0 0 0 0 0\ncpu0 20 0 20 110 0 0 0 0 0 0\nintr 1\n";
        const busy = P.stat(b, P.stat(a, null).ticks);
        ok("200 ticks ocupados de 200 = 100%", busy.usage === 1, busy.usage);
        ok("mesmo para o nucleo", busy.cores[0] === 1, busy.cores[0]);
        const idle = P.stat(c, busy.ticks);
        ok("100 ticks so de idle = 0%", idle.usage === 0, idle.usage);

        const halfA = "cpu  0 0 0 0 0 0 0 0 0 0\n";
        const halfB = "cpu  50 0 0 50 0 0 0 0 0 0\n";
        ok("metade ocupado = 50%", P.stat(halfB, P.stat(halfA, null).ticks).usage === 0.5);

        ok("contador que retrocede nao vira negativo",
           P.stat(halfA, P.stat(halfB, null).ticks).usage >= 0);
        ok("iowait conta como ocioso",
           P.stat("cpu  0 0 0 0 100 0 0 0 0 0\n", P.stat(halfA, null).ticks).usage === 0);

        console.log("\n/proc/meminfo");
        const m = P.meminfo(read("/proc/meminfo"));
        ok("total plausivel (>1 GiB)", m.total > 1073741824, m.total);
        ok("available <= total", m.available <= m.total);
        ok("cache lido", m.cached > 0);
        ok("swapFree <= swapTotal", m.swapFree <= m.swapTotal);
        ok("linha ausente vira 0", P.meminfo("MemTotal: 100 kB\n").cached === 0);

        console.log("\n/proc/loadavg");
        const l = P.loadavg(read("/proc/loadavg"));
        ok("load1 nao negativo", l.l1 >= 0, l.l1);
        ok("total de processos > 0", l.procs > 0, l.procs);
        ok("rodando <= total", l.running <= l.procs);

        console.log("\n/proc/net/dev");
        const n = P.netdev(read("/proc/net/dev"));
        ok("achou alguma interface", Object.keys(n).length > 0, Object.keys(n));
        ok("loopback ignorado", n["lo"] === undefined);
        const prev = { eth0: { rx: 0, tx: 0 } };
        const now = { eth0: { rx: 2048, tx: 1024 } };
        const r = P.netRate(now, prev, 2);
        ok("taxa = delta / segundos", r.rx === 1024 && r.tx === 512, JSON.stringify(r));
        ok("sem amostra anterior a taxa e zero", P.netRate(now, null, 2).rx === 0);
        ok("interface nova nao explode",
           P.netRate({ novo: { rx: 9, tx: 9 } }, prev, 2).rx === 0);

        console.log("\ndf");
        const d = P.df("Filesystem 1B-blocks Used Available Capacity Mounted on\n"
                     + "/dev/nvme0n1p2 500000000000 200000000000 300000000000 40% /\n"
                     + "/dev/nvme0n1p1 1000000000 100000000 900000000 10% /boot\n");
        ok("duas montagens", d.length === 2, d.length);
        ok("uso calculado", Math.abs(d[0].usage - 0.4) < 0.001, d[0].usage);
        ok("ponto de montagem com espaco", P.df(
            "F S U A C M\n/dev/x 100 50 50 50% /mnt/disco rigido\n")[0].mount === "/mnt/disco rigido");
        ok("cabecalho ignorado", P.df("Filesystem 1B-blocks Used Available Capacity Mounted on\n").length === 0);
        ok("tamanho zero descartado", P.df("F S U A C M\ntmpfs 0 0 0 - /run\n").length === 0);

        console.log("\n/proc/diskstats");
        const ds = P.diskstats(read("/proc/diskstats"));
        ok("achou algum disco", Object.keys(ds).length > 0, Object.keys(ds));
        const fake = "   8   0 sda 1 0 100 0 2 0 200 0\n"
                   + "   8   1 sda1 1 0 100 0 2 0 200 0\n"
                   + " 259   0 nvme0n1 1 0 10 0 2 0 20 0\n"
                   + " 259   1 nvme0n1p2 1 0 10 0 2 0 20 0\n"
                   + "   7   0 loop0 1 0 999 0 2 0 999 0\n";
        const fd = P.diskstats(fake);
        ok("particoes nao entram na conta", fd["sda1"] === undefined && fd["nvme0n1p2"] === undefined);
        ok("loopback de arquivo ignorado", fd["loop0"] === undefined);
        ok("discos inteiros contados", fd["sda"] !== undefined && fd["nvme0n1"] !== undefined);
        ok("setor de 512 B", fd["sda"].read === 100 * 512, fd["sda"].read);
        const dr = P.diskRate({ sda: { read: 1024, written: 2048 } },
                              { sda: { read: 0, written: 0 } }, 2);
        ok("taxa de disco = delta / segundos", dr.read === 512 && dr.written === 1024, JSON.stringify(dr));

        console.log("\npp_dpm");
        ok("pega a linha marcada", P.ppDpm("0: 400Mhz \n1: 600Mhz *\n2: 2200Mhz \n") === 600);
        ok("aceita o prefixo S:", P.ppDpm("S: 0Mhz *\n1: 500Mhz \n") === 0);
        ok("sem marca devolve 0", P.ppDpm("0: 400Mhz \n") === 0);

        console.log("\nclamp01");
        ok("limita acima", P.clamp01(5) === 1);
        ok("limita abaixo", P.clamp01(-5) === 0);

        console.log("\nbusca difusa");
        ok("nao casa devolve -1", F.score("zzz", "Firefox") === -1);
        ok("consulta vazia e neutra", F.score("", "Firefox") === 0);
        ok("exato ganha de tudo", F.score("firefox", "Firefox") === 1000);
        ok("prefixo vale muito", F.score("fire", "Firefox") > 700);

        // O caso que motiva o algoritmo: iniciais de palavra batem
        // subsequencia espalhada.
        ok("iniciais de palavra > letras espalhadas",
           F.score("ff", "Firefox Browser") > F.score("ff", "Diff Tool"),
           F.score("ff", "Firefox Browser") + " vs " + F.score("ff", "Diff Tool"));
        ok("camelCase conta como fronteira",
           F.score("vc", "VSCode") > 0);
        ok("letras seguidas valem mais que separadas",
           F.score("abc", "abcxxx") > F.score("abc", "axbxc"));
        ok("entre iguais, o nome curto ganha",
           F.score("term", "Terminal") > F.score("term", "Terminal Emulator Deluxe"));
        ok("ignora maiusculas", F.score("FIRE", "firefox") > 0);
        ok("ordem importa", F.score("xof", "Firefox") === -1);

        ok("posicoes marcam as letras certas",
           JSON.stringify(F.positions("ff", "Firefox")) === "[0,4]",
           JSON.stringify(F.positions("ff", "Firefox")));
        ok("sem casar, sem posicoes", F.positions("zz", "Firefox").length === 0);

        ok("campo com peso maior vence",
           F.scoreFields("x", [["x", 1], ["x", 3]]) === F.score("x", "x") * 3);
        ok("campo que nao casa e ignorado",
           F.scoreFields("fire", [["zzz", 9], ["Firefox", 1]]) > 0);

        const tNow = Date.now();
        ok("nunca usado pesa zero", F.frecency(0, tNow, tNow) === 0);
        ok("usado agora pesa cheio", Math.abs(F.frecency(10, tNow, tNow) - 10) < 0.01);
        ok("meia-vida de 14 dias",
           Math.abs(F.frecency(10, tNow - 14 * 86400000, tNow) - 5) < 0.05,
           F.frecency(10, tNow - 14 * 86400000, tNow));
        ok("relogio para tras nao amplifica",
           F.frecency(10, tNow + 86400000, tNow) <= 10);

        console.log(failures === 0
            ? "\n── As pedras estao assentadas."
            : "\n── " + failures + " falha(s).");
        Qt.exit(failures === 0 ? 0 : 1);
    }
}
