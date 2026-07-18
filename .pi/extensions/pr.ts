import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

function exec(cmd: string): string {
  return execSync(cmd, { encoding: "utf8", cwd: process.cwd() }).trim();
}

const TYPES = ["feat", "fix", "refactor", "docs", "chore"] as const;

function hasStagedOrModified(): boolean {
  const porcelain = exec("git status --porcelain");
  if (!porcelain) return false;
  return porcelain.split("\n").some((l) => !l.startsWith("??"));
}

function doPR(branch: string, ctx: ExtensionCommandContext) {
  try {
    exec("git push -u origin HEAD");
  } catch (e) {
    ctx.ui.notify(`Push failed: ${e}`, "error");
    return;
  }
  try {
    const url = exec(`gh pr create --base main --head "${branch}" --fill`);
    ctx.ui.notify(`PR created: ${url}`, "info");
  } catch (e) {
    ctx.ui.notify(`PR creation failed: ${e}`, "error");
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pr", {
    description:
      "Push current branch and create a PR. On main or with changes, prompts to create a feature branch first.",
    handler: async (_args, ctx) => {
      const branch = exec("git branch --show-current");
      const onMain = branch === "main";
      const hasChanges = hasStagedOrModified();

      if (!onMain && !hasChanges) {
        // Fast path: already on a feature branch with clean tree
        doPR(branch, ctx);
        return;
      }

      // Prompt for branch name explicitly
      const type = await ctx.ui.select(
        "Branch type — pick one",
        TYPES.map((t) => `${t}`)
      );
      if (!type) return;

      const summary = await ctx.ui.input(
        "Branch summary (kebab-case, e.g. add-foo)"
      );
      if (!summary) return;

      const newBranch = `${type}/${summary}`;

      if (onMain) {
        exec(`git fetch origin main`);
        exec(`git checkout -b "${newBranch}" origin/main`);
      } else {
        exec(`git checkout -b "${newBranch}"`);
      }

      if (hasChanges) {
        const msg = `${type}(${summary}): add ${summary}`;
        exec(`git add -A`);
        exec(`git commit -m "${msg}"`);
        doPR(newBranch, ctx);
      } else {
        ctx.ui.notify(
          `Branch "${newBranch}" created. Add some work, then run /pr again.`,
          "info"
        );
      }
    },
  });

  pi.registerCommand("prdone", {
    description: "Merge (merge commit) the current branch's PR and delete the branch.",
    handler: async (_args, ctx) => {
      const branch = exec("git branch --show-current");
      if (branch === "main") {
        ctx.ui.notify("On main. Nothing to merge.", "error");
        return;
      }

      // Check gh is authenticated
      try {
        exec("gh auth status");
      } catch {
        ctx.ui.notify("gh not authenticated.", "error");
        return;
      }

      // Merge
      try {
        exec(`gh pr merge --merge --delete-branch`);
      } catch (e) {
        ctx.ui.notify(`Merge failed: ${e}`, "error");
        return;
      }

      // Checkout main and pull
      exec("git checkout main");
      exec("git pull --ff-only origin main");

      ctx.ui.notify(`Branch "${branch}" merged and deleted. Back on main.", "info`);
    },
  });
}
