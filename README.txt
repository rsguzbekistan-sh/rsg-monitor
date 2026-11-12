RSG monitor — комплект для сборки
=================================

rsg/              -> загрузить в КОРЕНЬ вашей копии (fork) rustdesk на GitHub
  apply.sh        -> скрипт: меняет иконки, логотип, цвета, имя и вшивает сервер+ключ
  overlay/        -> готовые иконки и логотипы RSG
rsg-build.yml     -> загрузить в папку .github/workflows/

Секреты (Settings -> Secrets and variables -> Actions -> New repository secret):
  RSG_SERVER = 83.69.139.109
  RSG_KEY    = ключ сервера (cat /opt/rustdesk/data/id_ed25519.pub)

Запуск: вкладка Actions -> "RSG monitor build" -> Run workflow.
Готовые файлы: вкладка Releases -> rsg-monitor (Windows .exe/.msi, Mac .dmg).
