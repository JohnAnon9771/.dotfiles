pragma Singleton

//  Como o castelo escreve números.
//  Regra: nunca mais de 3 dígitos significativos numa barra estreita.

import QtQuick
import Quickshell

Singleton {
    /// Bytes → "1.4G". Base 1024, que é como o kernel conta.
    /// A unidade vem SEMPRE junto: "354.0" sozinho não diz nada.
    function bytes(n, digits) {
        if (!isFinite(n) || n <= 0) return "0B";
        const units = ["B", "K", "M", "G", "T", "P"];
        let i = 0;
        let v = n;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        // Bytes crus não têm casa decimal: "354B", não "354.0B".
        const d = i === 0 ? 0 : (digits !== undefined ? digits : (v < 10 ? 1 : 0));
        return v.toFixed(d) + units[i];
    }

    /// Bytes por segundo → "1.4M/s".
    function rate(n) {
        if (!isFinite(n) || n < 1) return "0B/s";
        return bytes(n) + "/s";
    }

    /// 0..1 → "42%"
    function pct(f, digits) {
        if (!isFinite(f)) return "—";
        return (f * 100).toFixed(digits || 0) + "%";
    }

    /// °C com o grau junto, sem casa decimal.
    function temp(c) {
        return isFinite(c) && c > 0 ? Math.round(c) + "°" : "—";
    }

    /// Hz → "2,40 GHz" · aceita 0 (placa dormindo).
    function hertz(hz) {
        if (!isFinite(hz) || hz <= 0) return "0";
        if (hz >= 1e9) return (hz / 1e9).toFixed(2) + "G";
        if (hz >= 1e6) return Math.round(hz / 1e6) + "M";
        return Math.round(hz / 1e3) + "k";
    }

    /// Microwatts → "142 W"
    function watts(uw) {
        if (!isFinite(uw) || uw < 0) return "—";
        const w = uw / 1e6;
        return (w < 10 ? w.toFixed(1) : Math.round(w)) + " W";
    }

    /// Segundos → "3d 4h" · "4h 12m" · "12m"
    function duration(s) {
        if (!isFinite(s) || s < 0) return "—";
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0) return d + "d " + h + "h";
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    /// Dois dígitos, para relógio.
    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function clamp01(v) {
        return v < 0 ? 0 : (v > 1 ? 1 : v);
    }
}
