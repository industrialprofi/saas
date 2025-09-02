# Руководство по запуску (Linux)

Простое приложение (Rails 8, Hotwire, Tailwind). Ниже — пошаговая инструкция для нового компьютера.

## 1) Установить системные зависимости

```bash
sudo apt update
sudo apt install -y \
  build-essential libssl-dev libreadline-dev zlib1g-dev \
  libsqlite3-dev sqlite3 libpq-dev git curl \
  nodejs npm postgresql postgresql-contrib

# Установить Yarn (через Corepack или npm)
sudo corepack enable || sudo npm install -g yarn
```

## 2) Установить rbenv и Ruby 3.3.8

```bash
# rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc

# ruby-build плагин
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Установка Ruby версии из .ruby-version (3.3.8)
rbenv install 3.3.8
rbenv global 3.3.8

# Bundler
gem install bundler
```

## 3) Настроить PostgreSQL

Убедитесь, что PostgreSQL запущен. Конфиги: `config/database.yml`.
Для простого доступа от текущего пользователя:

```bash
sudo -u postgres createuser -s $USER || true
```

## 4) Установка зависимостей и подготовка БД

```bash
bundle install
bin/rails db:prepare   # создание БД + миграции
bin/rails db:seed      # начальные данные (см. ниже)
```

### Что такое db/seeds.rb?

`db/seeds.rb` — скрипт начального заполнения базы данных. Создаёт тестовых пользователей и демо‑данные (в т.ч. пользователя с платным тарифом), чтобы сразу проверить функциональность без ручного ввода. Запуск: `bin/rails db:seed`.

## 5) Запуск приложения

```bash
bin/dev   # запустит Puma и Tailwind watcher
```

Откройте в браузере: http://127.0.0.1:3000

Если `bin/dev` не запускается из‑за отсутствия foreman:


## Полезные команды

```bash
# Миграции
bin/rails db:migrate
bin/rails db:rollback STEP=1

# Линтер
rubocop -a

# Тесты
bin/rails test
```

## Примечания

- Локаль по умолчанию: `ru` (файлы в `config/locales/`).
- Для Telegram OmniAuth задайте переменные окружения и перезапустите:
  ```bash
  export TELEGRAM_BOT_NAME=your_bot_name
  export TELEGRAM_BOT_TOKEN=your_bot_token
  ```
