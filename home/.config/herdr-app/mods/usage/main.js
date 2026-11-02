import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { theme, home, readTextFile } from "herdr";

const REFRESH_MS = 120_000;
const OPENCODE_AUTH = ".pi/agent/auth.json";
const CURSOR_AUTH = ".config/cursor/auth.json";

const pct = (value) => Math.max(0, Math.min(100, Number(value) || 0));

function ago(ms) {
  if (!ms) return "?";
  const minutes = Math.round((ms - Date.now()) / 60_000);
  if (minutes <= 0) return "soon";
  if (minutes < 90) return `in ${minutes}m`;
  const hours = Math.round(minutes / 60);
  if (hours < 48) return `in ${hours}h`;
  return `in ${Math.round(hours / 24)}d`;
}

function clock(ms) {
  const d = new Date(ms);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function gauge(t, value, limited) {
  const color = limited ? t.blocked : value >= 90 ? t.blocked : value >= 70 ? t.working : t.accent;
  return div()
    .h(6)
    .w("100%")
    .rounded(3)
    .bg(t.raised)
    .child(div().h(6).rounded(3).bg(color).w(`${value}%`));
}

async function readAuth(root, path) {
  const text = await readTextFile(`${root}/${path}`);
  if (!text) throw new Error(`missing ~/${path}`);
  return JSON.parse(text);
}

async function readGo(root) {
  const auth = await readAuth(root, OPENCODE_AUTH);
  const key = auth["opencode-go"]?.key;
  if (!key) throw new Error("no opencode-go key");
  const res = await fetch("https://opencode.ai/zen/go/v1/usage", {
    headers: { authorization: `Bearer ${key}`, accept: "application/json" },
  });
  if (!res.ok) throw new Error(`opencode.ai ${res.status}`);
  const usage = (await res.json())?.usage ?? {};
  const meter = (m) => ({
    value: pct(m?.percent),
    limited: m?.status === "rate-limited",
    resetsAt: Date.parse(m?.resetsAt) || 0,
  });
  return { rolling: meter(usage.rolling), weekly: meter(usage.weekly), monthly: meter(usage.monthly) };
}

async function readCursor(root) {
  const auth = await readAuth(root, CURSOR_AUTH);
  if (!auth.accessToken) throw new Error("no cursor access token");
  const call = async (method) => {
    const res = await fetch(`https://api2.cursor.sh/aiserver.v1.DashboardService/${method}`, {
      method: "POST",
      headers: {
        authorization: `Bearer ${auth.accessToken}`,
        "content-type": "application/json",
        "connect-protocol-version": "1",
      },
      body: "{}",
    });
    if (!res.ok) throw new Error(`cursor.sh ${method} ${res.status}`);
    return res.json();
  };
  const [period, info] = await Promise.all([call("GetCurrentPeriodUsage"), call("GetPlanInfo")]);
  const used = period?.planUsage ?? {};
  return {
    plan: info?.planInfo?.planName ?? "Cursor",
    price: info?.planInfo?.price ?? "",
    value: pct(used.totalPercentUsed),
    api: pct(used.apiPercentUsed),
    auto: pct(used.autoPercentUsed),
    resetsAt: Number(period?.billingCycleEnd ?? 0) || 0,
  };
}

export default class UsagePanel extends View {
  init(_props, cx) {
    this.go = null;
    this.cursor = null;
    this.problems = [];
    this.loaded = 0;
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      const root = home();
      const [go, cursor] = await Promise.allSettled([readGo(root), readCursor(root)]);
      const problems = [];
      if (go.status === "fulfilled") this.go = go.value;
      else problems.push(`OpenCode Go: ${go.reason?.message ?? go.reason}`);
      if (cursor.status === "fulfilled") this.cursor = cursor.value;
      else problems.push(`Cursor: ${cursor.reason?.message ?? cursor.reason}`);
      this.problems = problems;
      this.loaded = Date.now();
      cx.notify();
    });
  }

  meter(t, label, meter) {
    return v_flex()
      .gap(2)
      .child(
        h_flex()
          .justify_between()
          .w("100%")
          .child(div().text_color(t.muted).child(label))
          .child(
            div()
              .text_color(meter.limited ? t.blocked : t.foreground)
              .font_semibold()
              .child(meter.limited ? "limited" : `${Math.round(meter.value)}%`),
          ),
      )
      .child(gauge(t, meter.value, meter.limited))
      .child(div().text_size(10).text_color(t.dim).child(`resets ${ago(meter.resetsAt)}`));
  }

  card(t, title, subtitle, children) {
    return v_flex()
      .gap(6)
      .p(9)
      .rounded(8)
      .bg(t.surface)
      .border(1)
      .border_color(t.border)
      .child(
        h_flex()
          .justify_between()
          .w("100%")
          .gap(8)
          .child(div().text_size(12.5).font_semibold().text_color(t.foreground).truncate().child(title))
          .when(Boolean(subtitle), (el) =>
            el.child(div().text_size(11).text_color(t.dim).child(subtitle)),
          ),
      )
      .children(children);
  }

  render(_cx) {
    const t = theme();
    const go = this.go;
    const cursor = this.cursor;
    const stale = (label) => div().text_size(10.5).text_color(t.blocked).child(label);

    return v_flex()
      .size_full()
      .bg(t.chrome)
      .p(10)
      .gap(8)
      .text_size(11.8)
      .overflow_y_scrollbar()
      .child(
        h_flex()
          .justify_between()
          .w("100%")
          .child(div().text_size(12).font_semibold().text_color(t.muted).child("Usage"))
          .child(
            div()
              .id("refresh")
              .text_size(10.5)
              .text_color(t.dim)
              .hover((s) => s.text_color(t.foreground))
              .on_click((_e, cx) => this.refresh(cx))
              .child(this.loaded ? `refreshed ${clock(this.loaded)}` : "loading"),
          ),
      )
      .when(Boolean(go), (el) =>
        el.child(
          this.card(t, "OpenCode Go", "monthly plan", [
            this.meter(t, "5 hours", go.rolling),
            this.meter(t, "week", go.weekly),
            this.meter(t, "month", go.monthly),
          ]),
        ),
      )
      .when(Boolean(cursor), (el) =>
        el.child(
          this.card(t, `Cursor ${cursor.plan}`, cursor.price, [
            this.meter(t, "included usage", { value: cursor.value, limited: cursor.value >= 100, resetsAt: cursor.resetsAt }),
            h_flex()
              .gap(12)
              .child(div().text_size(10.5).text_color(t.dim).child(`API ${Math.round(cursor.api)}%`))
              .child(div().text_size(10.5).text_color(t.dim).child(`Auto ${Math.round(cursor.auto)}%`)),
          ]),
        ),
      )
      .when(this.problems.length > 0, (el) =>
        el.child(v_flex().gap(2).children(this.problems.map(stale))),
      );
  }
}
