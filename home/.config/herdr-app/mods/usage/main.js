import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { theme, home, readTextFile, exec } from "herdr";

const REFRESH_MS = 120_000;
const KEYS_ON = "dev";
const OPENCODE_AUTH = ".pi/agent/auth.json";
const CURSOR_AUTH = ".config/cursor/auth.json";
const DEEPSEEK_ENV = ".config/deepseek/env";
const OPENROUTER_ENV = ".config/openrouter/env";

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

function stamp(ms) {
  const d = new Date(ms);
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${clock(ms)}`;
}

function jwtExp(token) {
  try {
    const body = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = body + "=".repeat((4 - (body.length % 4)) % 4);
    return Number(JSON.parse(atob(padded))?.exp) || 0;
  } catch {
    return 0;
  }
}

function money(n, currency = "USD") {
  const v = Number(n);
  if (!Number.isFinite(v)) return "?";
  const abs = Math.abs(v);
  const digits = abs >= 100 ? 0 : abs >= 10 ? 1 : 2;
  const s = v.toFixed(digits);
  if (currency === "USD") return `$${s}`;
  if (currency === "CNY") return `¥${s}`;
  return `${s} ${currency}`;
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

async function remoteJson(script) {
  const r = await exec("sh", ["-c", script], { on: KEYS_ON, timeout: 45_000 });
  const out = String(r.stdout ?? "").trim();
  if (r.code !== 0) {
    const err = String(r.stderr ?? "").trim() || out || `exit ${r.code}`;
    throw new Error(err.split("\n").pop());
  }
  if (!out) throw new Error("empty response");
  try {
    return JSON.parse(out);
  } catch {
    throw new Error("bad json");
  }
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
  if (!auth.accessToken) throw new Error("no cursor access token, run cursor-agent login");
  const exp = jwtExp(auth.accessToken) * 1000;
  if (exp && exp <= Date.now()) {
    throw new Error(`login expired ${stamp(exp)}, run cursor-agent login`);
  }
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
    if (res.status === 401) throw new Error("login expired, run cursor-agent login");
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

async function readDeepseek() {
  const data = await remoteJson(`
set -e
f="$HOME/${DEEPSEEK_ENV}"
test -f "$f" || { echo "missing ~/${DEEPSEEK_ENV}" >&2; exit 2; }
set -a; . "$f"; set +a
test -n "$DEEPSEEK_API_KEY" || { echo "no DEEPSEEK_API_KEY" >&2; exit 2; }
curl -sS --max-time 30 -H "Authorization: Bearer $DEEPSEEK_API_KEY" -H "Accept: application/json" \
  "https://api.deepseek.com/user/balance"
`);
  const infos = Array.isArray(data?.balance_infos) ? data.balance_infos : [];
  const pick = infos.find((b) => b?.currency === "USD") || infos[0];
  if (!pick) throw new Error("no balance");
  return {
    available: Boolean(data?.is_available),
    currency: String(pick.currency || "USD"),
    total: Number(pick.total_balance),
    granted: Number(pick.granted_balance),
    topped: Number(pick.topped_up_balance),
  };
}

async function readOpenrouter() {
  const data = await remoteJson(`
set -e
f="$HOME/${OPENROUTER_ENV}"
test -f "$f" || { echo "missing ~/${OPENROUTER_ENV} (OPENROUTER_API_KEY=…)" >&2; exit 2; }
set -a; . "$f"; set +a
test -n "$OPENROUTER_API_KEY" || { echo "no OPENROUTER_API_KEY" >&2; exit 2; }
export OPENROUTER_MANAGEMENT_API_KEY="\${OPENROUTER_MANAGEMENT_API_KEY:-\$OPENROUTER_API_KEY}"
python3 <<'PY'
import json, os, urllib.error, urllib.request

def get(url, key):
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        try:
            payload = json.loads(body)
        except Exception:
            payload = {"error": {"message": body[:200]}}
        return e.code, payload

key = os.environ["OPENROUTER_API_KEY"]
mgmt = os.environ.get("OPENROUTER_MANAGEMENT_API_KEY") or key
key_status, key_body = get("https://openrouter.ai/api/v1/key", key)
credits_status, credits_body = get("https://openrouter.ai/api/v1/credits", mgmt)
print(json.dumps({
    "key_status": key_status,
    "key": key_body,
    "credits_status": credits_status,
    "credits": credits_body,
}))
PY
`);
  if (data.key_status !== 200) {
    const msg = data?.key?.error?.message || `key ${data.key_status}`;
    throw new Error(msg);
  }
  const keyData = data?.key?.data ?? data?.key ?? {};
  const limit = keyData.limit == null ? null : Number(keyData.limit);
  const remaining = keyData.limit_remaining == null ? null : Number(keyData.limit_remaining);
  const budget = keyData.effective_budget || null;
  let credits = null;
  if (data.credits_status === 200) {
    const c = data?.credits?.data ?? {};
    const total = Number(c.total_credits);
    const used = Number(c.total_usage);
    if (Number.isFinite(total) && Number.isFinite(used)) {
      credits = { total, used, left: total - used };
    }
  }
  let cap = null;
  if (limit != null && Number.isFinite(limit) && limit > 0 && remaining != null && Number.isFinite(remaining)) {
    const used = Math.max(0, limit - remaining);
    cap = {
      limit,
      remaining,
      value: pct((used / limit) * 100),
      limited: remaining <= 0,
      resetsAt: budget?.resets_at ? Date.parse(budget.resets_at) || 0 : 0,
    };
  }
  return {
    credits,
    creditsError: data.credits_status === 200 ? null : data?.credits?.error?.message || `credits ${data.credits_status}`,
    cap,
    budget: budget
      ? {
          spend: Number(budget.spend_usd),
          limit: Number(budget.limit_usd),
          remaining: Number(budget.remaining_usd),
          resetsAt: budget.resets_at ? Date.parse(budget.resets_at) || 0 : 0,
          interval: String(budget.reset_interval || ""),
        }
      : null,
  };
}

export default class UsagePanel extends View {
  init(_props, cx) {
    this.go = null;
    this.cursor = null;
    this.deepseek = null;
    this.openrouter = null;
    this.problems = [];
    this.loaded = 0;
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      const root = home();
      const [go, cursor, deepseek, openrouter] = await Promise.allSettled([
        readGo(root),
        readCursor(root),
        readDeepseek(),
        readOpenrouter(),
      ]);
      const problems = [];
      if (go.status === "fulfilled") this.go = go.value;
      else problems.push(`OpenCode Go: ${go.reason?.message ?? go.reason}`);
      if (cursor.status === "fulfilled") this.cursor = cursor.value;
      else problems.push(`Cursor: ${cursor.reason?.message ?? cursor.reason}`);
      if (deepseek.status === "fulfilled") this.deepseek = deepseek.value;
      else problems.push(`DeepSeek: ${deepseek.reason?.message ?? deepseek.reason}`);
      if (openrouter.status === "fulfilled") this.openrouter = openrouter.value;
      else problems.push(`OpenRouter: ${openrouter.reason?.message ?? openrouter.reason}`);
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
    const deepseek = this.deepseek;
    const openrouter = this.openrouter;
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
            this.meter(t, "included usage", {
              value: cursor.value,
              limited: cursor.value >= 100,
              resetsAt: cursor.resetsAt,
            }),
            h_flex()
              .gap(12)
              .child(div().text_size(10.5).text_color(t.dim).child(`API ${Math.round(cursor.api)}%`))
              .child(div().text_size(10.5).text_color(t.dim).child(`Auto ${Math.round(cursor.auto)}%`)),
          ]),
        ),
      )
      .when(Boolean(deepseek), (el) =>
        el.child(
          this.card(t, "DeepSeek", deepseek.available ? "platform" : "unavailable", [
            h_flex()
              .justify_between()
              .w("100%")
              .child(div().text_color(t.muted).child("balance"))
              .child(
                div()
                  .font_semibold()
                  .text_color(deepseek.available ? t.foreground : t.blocked)
                  .child(money(deepseek.total, deepseek.currency)),
              ),
            h_flex()
              .gap(12)
              .child(
                div()
                  .text_size(10.5)
                  .text_color(t.dim)
                  .child(`topped ${money(deepseek.topped, deepseek.currency)}`),
              )
              .child(
                div()
                  .text_size(10.5)
                  .text_color(t.dim)
                  .child(`granted ${money(deepseek.granted, deepseek.currency)}`),
              ),
            div().text_size(10).text_color(t.dim).child(`keys on ${KEYS_ON}`),
          ]),
        ),
      )
      .when(Boolean(openrouter), (el) => {
        const or = openrouter;
        const kids = [];
        if (or.credits) {
          kids.push(
            h_flex()
              .justify_between()
              .w("100%")
              .child(div().text_color(t.muted).child("credits left"))
              .child(div().font_semibold().text_color(t.foreground).child(money(or.credits.left))),
          );
          kids.push(
            h_flex()
              .gap(12)
              .child(div().text_size(10.5).text_color(t.dim).child(`used ${money(or.credits.used)}`))
              .child(div().text_size(10.5).text_color(t.dim).child(`bought ${money(or.credits.total)}`)),
          );
        } else if (or.creditsError) {
          kids.push(div().text_size(10.5).text_color(t.dim).child(`credits: ${or.creditsError}`));
        }
        if (or.cap) {
          kids.push(
            this.meter(t, "key spend cap", {
              value: or.cap.value,
              limited: or.cap.limited,
              resetsAt: or.cap.resetsAt,
            }),
          );
          kids.push(
            div()
              .text_size(10.5)
              .text_color(t.dim)
              .child(`${money(or.cap.remaining)} of ${money(or.cap.limit)} left`),
          );
        }
        if (or.budget && Number.isFinite(or.budget.limit) && or.budget.limit > 0) {
          const usedPct = pct((or.budget.spend / or.budget.limit) * 100);
          kids.push(
            this.meter(t, or.budget.interval ? `${or.budget.interval} budget` : "budget", {
              value: usedPct,
              limited: or.budget.remaining <= 0,
              resetsAt: or.budget.resetsAt,
            }),
          );
        }
        kids.push(div().text_size(10).text_color(t.dim).child(`keys on ${KEYS_ON}`));
        const subtitle = or.credits ? money(or.credits.left) : "pay as you go";
        return el.child(this.card(t, "OpenRouter", subtitle, kids));
      })
      .when(this.problems.length > 0, (el) =>
        el.child(v_flex().gap(2).children(this.problems.map(stale))),
      );
  }
}
