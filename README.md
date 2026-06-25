# 🏥 Медицинский Центр MARIA — Website

**Сайт**: https://maria-site.duckdns.org (будет доступен после деплоя)

---

## Стек технологий

| Компонент | Технология |
|-----------|------------|
| **Web Server** | Nginx + HTML/CSS |
| **Reverse Proxy** | Traefik v3.1 |
| **HTTPS** | Let's Encrypt (авто-обновление) |
| **DNS** | DuckDNS (динамический IP) |
| **Database** | PostgreSQL 16 |
| **Cache** | Redis 7 |
| **Monitoring** | Prometheus + Grafana |
| **Server** | Oracle Cloud Free Tier (4 ARM ядра, 24 ГБ RAM) |
| **CI/CD** | GitHub Actions |

---

## Деплой за 3 шага

### Шаг 1: Регистрация (вручную)

1. **DuckDNS** → https://www.duckdns.org/
   - Войти через Google/GitHub
   - Создать домен: `maria-site`
   - Скопировать **Token** (будет нужен дальше)

2. **Oracle Cloud** → https://signup.cloud.oracle.com/
   - Создать аккаунт (нужна банковская карта для верификации, деньги не списывают)
   - Создать VM: **Ampere A1** (4 ядра, 24 ГБ RAM), Ubuntu 22.04
   - Открыть порты: 22, 80, 443, 8080
   - Сохранить публичный IP

### Шаг 2: Подключение к серверу

```bash
# Подключиться по SSH
ssh ubuntu@YOUR_SERVER_IP

# Скачать и запустить setup
curl -fsSL https://raw.githubusercontent.com/Serg2206/maria-site/main/scripts/server-setup.sh | bash

# Выйти и зайти снова (чтобы Docker заработал)
exit
ssh ubuntu@YOUR_SERVER_IP

# Редактировать .env
nano ~/maria-site/.env
# Добавить:
# DUCKDNS_TOKEN=your_token_from_duckdns
# POSTGRES_PASSWORD=your_secure_password

# Запустить деплой
cd ~/maria-site && ./deploy.sh
```

### Шаг 3: Готово! 🎉

- **Сайт**: https://maria-site.duckdns.org
- **Grafana**: https://grafana.maria-site.duckdns.org (admin/admin)
- **Traefik**: https://traefik.maria-site.duckdns.org

---

## Локальная разработка

```bash
# Запуск на локальном компьютере
docker compose up -d

# Открыть http://localhost
```

---

## Структура проекта

```
maria-site/
├── public/
│   └── index.html          # Сайт клиники
├── scripts/
│   └── server-setup.sh     # Скрипт настройки сервера
├── docker-compose.yml      # Production stack
├── prometheus.yml          # Мониторинг
├── deploy.sh              # Скрипт деплоя
└── README.md             # Этот документ
```

---

## Безопасность

- ✅ HTTPS (Let's Encrypt, авто-обновление)
- ✅ Fail2ban (защита от брутфорса)
- ✅ UFW Firewall (порты 22, 80, 443, 8080)
- ✅ Docker без root

---

## Обновление

```bash
# На сервере
cd ~/maria-site
git pull
docker compose up -d
```

---

## Поддержка

ssvnauka@gmail.com | ssvnauka.net
