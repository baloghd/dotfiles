import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { appHome, exec, machines, readTextFile, theme } from "herdr";

const REFRESH_MS = 2_000;
const SAMPLE = [
  "awk '/^cpu /{print $2+$3+$4+$5,$5}' /proc/stat",
  "awk '/^MemTotal:|^MemAvailable:/{print $2}' /proc/meminfo",
  "hostname -s",
].join("; ");

const pct = (value) => Math.max(0, Math.min(100, Number(value) || 0));

function gib(kib) {
  const n = Number(kib) || 0;
  return `${(n / (1024 * 1024)).toFixed(n >= 10 * 1024 * 1024 ? 1 : 2)} GiB`;
}

function clock(ms) {
  const d = new Date(ms);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}`;
}

function parseSample(stdout) {
  const lines = String(stdout ?? "")
    .trim()
    .split(/\n+/)
    .map((l) => l.trim())
    .filter(Boolean);
  if (lines.length < 4) throw new Error("short sample");
  const [total, idle] = lines[0].split(/\s+/).map(Number);
  const memTotal = Number(lines[1]);
  const memAvailable = Number(lines[2]);
  const host = lines[3] || "?";
  if (![total, idle, memTotal, memAvailable].every(Number.isFinite)) throw new Error("bad sample");
  return { total, idle, memTotal, memAvailable, host };
}

function viaLabel(host) {
  if (host.ssh) return "ssh";
  if (host.on == null) return "local";
  return "herdr";
}

export default class MetricsPanel extends View {
  init(_props, cx) {
    this.index = 0;
    this.prev = {};
    this.snap = {};
    this.errors = {};
    this.extra = [];
    this.loaded = 0;
    this.loadExtras(cx);
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  loadExtras(cx) {
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(`${appHome()}/mods/metrics/hosts.json`);
        const rows = text ? JSON.parse(text) : [];
        this.extra = (Array.isArray(rows) ? rows : [])
          .filter((r) => r && r.ssh && (r.id || r.label))
          .map((r) => ({
            id: String(r.id || r.label),
            label: String(r.label || r.id),
            ssh: String(r.ssh),
          }));
      } catch (err) {
        this.extra = [];
        this.errors._hosts = err?.message ?? String(err);
      }
      cx.notify();
      this.refresh(cx);
    });
  }

  hostList() {
    const seen = new Set();
    const list = [];
    const add = (host) => {
      if (seen.has(host.id)) return;
      seen.add(host.id);
      list.push(host);
    };

    add({ id: "local", label: "this computer", on: null });
    for (const row of this.extra) add(row);
    for (const m of machines()) {
      if (m.name == null || m.temporary) continue;
      add({ id: String(m.name), label: String(m.name), on: m.name, layout: m.layout });
    }

    if (this.index >= list.length) this.index = 0;
    return list;
  }

  current() {
    return this.hostList()[this.index];
  }

  step(delta, cx) {
    const n = this.hostList().length;
    if (n === 0) return;
    this.index = (this.index + delta + n) % n;
    cx.notify();
    this.refresh(cx);
  }

  async sample(host) {
    if (host.ssh) {
      return exec("ssh", ["-o", "BatchMode=yes", "-o", "ConnectTimeout=4", host.ssh, SAMPLE]);
    }
    return exec("sh", ["-c", SAMPLE], host.on == null ? {} : { on: host.on });
  }

  refresh(cx) {
    const host = this.current();
    if (!host) return;
    const k = host.id;
    cx.spawn(async (cx) => {
      try {
        const r = await this.sample(host);
        if (r.code !== 0) throw new Error((r.stderr || r.stdout || `exit ${r.code}`).trim().slice(0, 160));
        const sample = parseSample(r.stdout);
        const prev = this.prev[k];
        let cpu = null;
        if (prev) {
          const dTotal = sample.total - prev.total;
          const dIdle = sample.idle - prev.idle;
          if (dTotal > 0) cpu = pct(100 * (1 - dIdle / dTotal));
        }
        this.prev[k] = { total: sample.total, idle: sample.idle };
        const used = Math.max(0, sample.memTotal - sample.memAvailable);
        this.snap[k] = {
          host: sample.host,
          cpu,
          mem: pct((100 * used) / sample.memTotal),
          used,
          total: sample.memTotal,
          available: sample.memAvailable,
          at: Date.now(),
        };
        this.errors[k] = null;
        this.loaded = Date.now();
      } catch (err) {
        this.errors[k] = err?.message ?? String(err);
      }
      cx.notify();
    });
  }

  meter(t, label, value, detail) {
    return v_flex()
      .gap(4)
      .child(
        h_flex()
          .justify_between()
          .w("100%")
          .child(div().text_color(t.muted).child(label))
          .child(
            div()
              .font_semibold()
              .text_color(t.foreground)
              .child(value == null ? "…" : `${Math.round(value)}%`),
          ),
      )
      .child(
        div()
          .h(8)
          .w("100%")
          .rounded(4)
          .bg(t.raised)
          .child(
            div()
              .h(8)
              .rounded(4)
              .bg(pct(value) >= 90 ? t.blocked : pct(value) >= 70 ? t.working : t.accent)
              .w(`${pct(value ?? 0)}%`),
          ),
      )
      .when(Boolean(detail), (el) => el.child(div().text_size(10.5).text_color(t.dim).child(detail)));
  }

  nav(t, host, snap) {
    const list = this.hostList();
    const title = snap?.host || host.label;
    const many = list.length > 1;
    return h_flex()
      .justify_between()
      .w("100%")
      .gap(6)
      .items_center()
      .child(
        div()
          .id("metrics-prev")
          .size(26)
          .flex_none()
          .flex()
          .items_center()
          .justify_center()
          .rounded(6)
          .text_color(many ? t.muted : t.dim)
          .hover((s) => (many ? s.bg(t.hover).text_color(t.foreground) : s))
          .on_click((_e, cx) => {
            if (many) this.step(-1, cx);
          })
          .child("‹"),
      )
      .child(
        v_flex()
          .flex_1()
          .min_w(0)
          .items_center()
          .gap(1)
          .child(div().text_size(13).font_semibold().text_color(t.foreground).truncate().child(title))
          .child(
            div()
              .text_size(10.5)
              .text_color(t.dim)
              .child(`${this.index + 1}/${list.length} · ${viaLabel(host)}`),
          ),
      )
      .child(
        div()
          .id("metrics-next")
          .size(26)
          .flex_none()
          .flex()
          .items_center()
          .justify_center()
          .rounded(6)
          .text_color(many ? t.muted : t.dim)
          .hover((s) => (many ? s.bg(t.hover).text_color(t.foreground) : s))
          .on_click((_e, cx) => {
            if (many) this.step(1, cx);
          })
          .child("›"),
      );
  }

  render(_cx) {
    const t = theme();
    const host = this.current();
    const k = host?.id;
    const snap = k ? this.snap[k] : null;
    const err = k ? this.errors[k] : null;

    return v_flex()
      .size_full()
      .bg(t.chrome)
      .p(10)
      .gap(10)
      .text_size(11.8)
      .overflow_y_scrollbar()
      .child(
        h_flex()
          .justify_between()
          .w("100%")
          .items_center()
          .child(
            h_flex()
              .gap(6)
              .items_center()
              .child(svg("mods/metrics/activity.svg").size(14).text_color(t.muted))
              .child(div().text_size(12).font_semibold().text_color(t.muted).child("Metrics")),
          )
          .child(
            div()
              .id("metrics-refresh")
              .text_size(10.5)
              .text_color(t.dim)
              .hover((s) => s.text_color(t.foreground))
              .on_click((_e, cx) => this.refresh(cx))
              .child(this.loaded ? clock(this.loaded) : "loading"),
          ),
      )
      .when(Boolean(host), (el) => el.child(this.nav(t, host, snap)))
      .when(Boolean(err), (el) =>
        el.child(
          div()
            .p(9)
            .rounded(8)
            .bg(t.surface)
            .border(1)
            .border_color(t.border)
            .text_color(t.blocked)
            .text_size(11)
            .child(err),
        ),
      )
      .when(Boolean(snap) && !err, (el) =>
        el.child(
          v_flex()
            .gap(10)
            .p(10)
            .rounded(8)
            .bg(t.surface)
            .border(1)
            .border_color(t.border)
            .child(this.meter(t, "CPU", snap.cpu, snap.cpu == null ? "sampling…" : null))
            .child(
              this.meter(
                t,
                "RAM",
                snap.mem,
                `${gib(snap.used)} used · ${gib(snap.available)} free · ${gib(snap.total)} total`,
              ),
            ),
        ),
      )
      .when(!snap && !err, (el) => el.child(div().text_color(t.dim).child("sampling…")));
  }
}
