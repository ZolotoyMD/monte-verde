#!/usr/bin/env bash
set -e

REPO_NAME="${1:-monte-verde}"

echo "1. Проверка авторизации в GitHub CLI..."
if ! gh auth status >/dev/null 2>&1; then
  echo "Сейчас откроется авторизация в GitHub через браузер..."
  gh auth login -h github.com -p https -w
fi

GH_USER=$(gh api user -q .login)
echo "Авторизован как: $GH_USER"

echo "2. Создание/привязка публичного репозитория $GH_USER/$REPO_NAME..."
if ! gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
else
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  git push -u origin main --force
fi

echo "3. Включение GitHub Pages на ветке main..."
gh api "repos/$GH_USER/$REPO_NAME/pages" \
  -X POST \
  -f "build_type=legacy" \
  -f "source[branch]=main" \
  -f "source[path]=/" 2>/dev/null || \
gh api "repos/$GH_USER/$REPO_NAME/pages" \
  -X PUT \
  -f "build_type=legacy" \
  -f "source[branch]=main" \
  -f "source[path]=/" >/dev/null

echo ""
echo "✅ Готово! Через 30–60 секунд сайт будет доступен круглосуточно по ссылке:"
echo "👉 https://${GH_USER}.github.io/${REPO_NAME}/"
