#!/usr/bin/env bash
# 一键发布到 GitHub Pages
# 用法： GITHUB_TOKEN=ghp_xxx OWNER=你的用户名 REPO=birthday-zxt ./deploy.sh
set -euo pipefail

OWNER="${OWNER:-djskhe}"
REPO="${REPO:-birthday-zxt}"
BRANCH="main"
DIR="$(cd "$(dirname "$0")" && pwd)"

: "${GITHUB_TOKEN:?请先设置 GITHUB_TOKEN（需要 repo 权限）}"

api() {
  curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" \
       -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

echo "→ 检查/创建仓库 ${OWNER}/${REPO}"
code=$(api -o /tmp/gh_repo.json -w '%{http_code}' "https://api.github.com/repos/${OWNER}/${REPO}")
if [ "$code" = "404" ]; then
  api -X POST "https://api.github.com/user/repos" \
      -d "{\"name\":\"${REPO}\",\"description\":\"曾祥婷 · 十八岁生日贺卡\",\"private\":false,\"has_issues\":false}" >/dev/null
  echo "  已创建"
else
  echo "  已存在"
fi

echo "→ 提交并推送"
cd "$DIR"
git init -q 2>/dev/null || true
git config user.name "xixi" >/dev/null 2>&1 || true
git config user.email "xixi@local" >/dev/null 2>&1 || true
git add -A
git commit -q -m "生日贺卡：蛋小黑 + 18 根蜡烛的三层蛋糕" 2>/dev/null || true
git branch -M "$BRANCH"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${REPO}.git"
git push -q -u origin "$BRANCH"
echo "  已推送"

echo "→ 开启 GitHub Pages"
api -X POST "https://api.github.com/repos/${OWNER}/${REPO}/pages" \
    -d "{\"source\":{\"branch\":\"${BRANCH}\",\"path\":\"/\"}}" >/dev/null 2>&1 || \
api -X PUT "https://api.github.com/repos/${OWNER}/${REPO}/pages" \
    -d "{\"source\":{\"branch\":\"${BRANCH}\",\"path\":\"/\"}}" >/dev/null 2>&1 || true

sleep 3
echo
echo "✅ 线上地址（首次部署约 1 分钟后生效）："
echo "   https://${OWNER}.github.io/${REPO}/"