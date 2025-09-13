# --- Переменные ---
# Определяем системные переменные один раз, чтобы избежать проблем с экранированием в командах.
USER := $(shell whoami)
ARCH := $(shell dpkg --print-architecture)
CODENAME := $(shell lsb_release -cs)

# --- Цели ---

# Цель по умолчанию: выводит справку
help:
	@echo "Доступные команды:"
	@echo "  make setup                - Полная автоматическая установка и настройка всего окружения."
	@echo "  make docker               - Установка Docker и Docker Compose."
	@echo "  make permissions          - Настройка прав для /var/www и Docker."
	@echo "  make dl                   - Установка утилиты local-deploy."
	@echo "  make php                  - Установка PHP 8.2 и необходимых расширений."
	@echo "  make init-dl              - Запуск 'dl service up' для инициализации окружения."
	@echo "  make terminal             - Установка и настройка Zsh, Oh My Zsh и шрифтов."
	@echo "  make vscode               - Установка Visual Studio Code."
	@echo "  make configure-vscode     - Установка расширений и применение настроек VS Code."
	@echo "  make fix-docker-repo      - Исправление поврежденного репозитория Docker."
	@echo "  make status               - Проверка статуса установленных компонентов."
	@echo "  make clean                - Очистка временных файлов."
	@echo "  make stop-port-80         - Остановка процессов на порту 80."

# Основная команда для полной настройки (Zsh перенесен в конец)
setup: docker permissions dl php init-dl terminal
	@echo "\n\n"
	@echo "========================================================================"
	@echo "🎉 УСТАНОВКА ЗАВЕРШЕНА! 🎉"
	@echo "ВАЖНО: Пожалуйста, закройте этот терминал и откройте новый."
	@echo "Это необходимо для применения прав Docker и перехода на Zsh."
	@echo "Ваш терминал и VS Code уже настроены."
	@echo "========================================================================"

# Установка Docker & Docker-compose
docker:
	@echo "Шаг 1/6: Установка Docker и Docker Compose..."
	sudo apt-get update
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common libssl-dev libffi-dev git wget nano
	# Установка Docker через официальный метод
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo \
	  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	  ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
	# Настройка автозапуска Docker
	@if ! grep -q "docker service not running" ~/.profile 2>/dev/null; then \
		echo 'if ! service docker status > /dev/null 2>&1; then' >> ~/.profile; \
		echo '  echo "docker service not running, starting..."' >> ~/.profile; \
		echo '  sudo service docker start' >> ~/.profile; \
		echo 'fi' >> ~/.profile; \
	fi
	@echo "Docker установлен."

# Настройка прав
permissions:
	@echo "Шаг 2/6: Настройка прав доступа..."
	-sudo groupadd docker
	sudo usermod -aG docker ${USER}
	sudo mkdir -p /var/www
	sudo chown -R ${USER}:${USER} /var/www
	@echo "Права для Docker и /var/www настроены для пользователя ${USER}."

# Установка утилиты local-deploy (dl)
dl:
	@echo "Шаг 3/6: Установка local-deploy (dl)..."
	cd ~ && rm -rf .local/bin/dl .config/dl
	sudo apt-get update
	sudo apt-get install -y ca-certificates gnupg
	sudo install -m 0755 -d /etc/apt/keyrings
	wget -qO - https://apt.fury.io/local-deploy/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/dl.gpg > /dev/null
	echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/dl.gpg] https://apt.fury.io/local-deploy/ /" | sudo tee /etc/apt/sources.list.d/dl.list > /dev/null
	sudo apt-get update
	sudo apt-get install -y dl
	@echo "Утилита 'dl' установлена."

# Установка PHP 8.2
php:
	@echo "Шаг 4/6: Установка PHP 8.2 и необходимых расширений..."
	sudo apt-get update
	sudo apt-get install -y software-properties-common
	sudo add-apt-repository ppa:ondrej/php -y
	sudo apt-get update
	sudo apt-get install -y php8.2 php8.2-cli php8.2-common php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath php8.2-xdebug php8.2-dev php8.2-sqlite3 php8.2-intl
	# Установка Composer
	curl -sS https://getcomposer.org/installer | php
	sudo mv composer.phar /usr/local/bin/composer
	sudo chmod +x /usr/local/bin/composer
	@echo "PHP 8.2 и Composer установлены."

# Остановка процессов на порту 80
stop-port-80:
	@echo "Проверка и остановка процессов на порту 80..."
	@if sudo lsof -ti:80 >/dev/null 2>&1; then \
		echo "Найдены процессы на порту 80. Останавливаем..."; \
		sudo lsof -ti:80 | xargs -r sudo kill -9; \
		echo "Процессы на порту 80 остановлены."; \
	else \
		echo "Порт 80 свободен."; \
	fi
	@if sudo systemctl is-active --quiet apache2; then \
		echo "Останавливаем Apache2..."; \
		sudo systemctl stop apache2; \
		sudo systemctl disable apache2; \
		echo "Apache2 остановлен и отключен."; \
	fi
	@if sudo systemctl is-active --quiet nginx; then \
		echo "Останавливаем Nginx..."; \
		sudo systemctl stop nginx; \
		sudo systemctl disable nginx; \
		echo "Nginx остановлен и отключен."; \
	fi

# Инициализация окружения dl
init-dl: stop-port-80
	@echo "Шаг 5/6: Инициализация окружения local-deploy..."
	@echo "Перезапуск Docker для применения групповых настроек..."
	sudo systemctl restart docker
	sleep 3
	@echo "Запуск dl service up..."
	dl service up || (echo "Ошибка при запуске dl service up. Попробуем с флагом --recreate..." && dl service up --recreate)
	@echo "Окружение local-deploy инициализировано."

# Кастомизация терминала (перенесено в конец)
terminal:
	@echo "Шаг 6/6: Настройка терминала (Zsh, Oh My Zsh, Powerlevel10k)..."
	sudo apt-get install -y zsh curl
	# Установка Oh My Zsh (только если не установлен)
	@if [ ! -d "$$HOME/.oh-my-zsh" ]; then \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended; \
	fi
	# Установка темы Powerlevel10k
	@if [ ! -d "$$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then \
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $$HOME/.oh-my-zsh/custom/themes/powerlevel10k; \
	fi
	# Установка плагинов
	@if [ ! -d "$$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; \
	fi
	# Применение настроек .zshrc
	sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $$HOME/.zshrc
	sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting)/' $$HOME/.zshrc
	# Копирование конфигурации p10k
	cp config/.p10k.zsh $$HOME/.p10k.zsh 2>/dev/null || echo "Файл .p10k.zsh не найден, будет создан при первом запуске"
	# Установка JetBrains Mono шрифта
	mkdir -p $$HOME/.local/share/fonts
	cd /tmp && wget -O JetBrainsMono.tar.xz "https://download.jetbrains.com/fonts/JetBrainsMono-2.304.tar.xz"
	cd /tmp && tar -xf JetBrainsMono.tar.xz
	cp /tmp/JetBrainsMono-*/fonts/ttf/*.ttf $$HOME/.local/share/fonts/
	fc-cache -f -v
	# Установка Zsh как shell по умолчанию
	sudo chsh -s $$(which zsh) ${USER}
	@echo "Терминал настроен."

# Дополнительные команды
clean:
	@echo "Очистка временных файлов..."
	sudo apt-get autoremove -y
	sudo apt-get autoclean

status:
	@echo "Проверка статуса установленных компонентов..."
	@echo "Docker version:" && docker --version 2>/dev/null || echo "Docker не установлен"
	@echo "Docker Compose version:" && docker-compose --version 2>/dev/null || echo "Docker Compose не установлен"
	@echo "PHP version:" && php --version 2>/dev/null || echo "PHP не установлен"
	@echo "Composer version:" && composer --version 2>/dev/null || echo "Composer не установлен"
	@echo "Zsh version:" && zsh --version 2>/dev/null || echo "Zsh не установлен"
	@echo "DL version:" && dl --version 2>/dev/null || echo "DL не установлен"
	@echo "Tree version:" && tree --version 2>/dev/null || echo "Tree не установлен"
	@echo "Проверка порта 80:"
	@sudo lsof -i:80 2>/dev/null || echo "Порт 80 свободен"

.PHONY: help setup docker permissions dl php terminal init-dl clean status stop-port-80
