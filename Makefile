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
	@echo "  make terminal             - Установка и настройка Zsh, Oh My Zsh и шрифтов."
	@echo "  make vscode               - Установка Visual Studio Code."
	@echo "  make configure-vscode     - Установка расширений и применение настроек VS Code."
	@echo "  make init-dl              - Запуск 'dl service up' для инициализации окружения."
	@echo "  make fix-docker-repo      - Исправление поврежденного репозитория Docker."
	@echo "  make status               - Проверка статуса установленных компонентов."
	@echo "  make clean                - Очистка временных файлов."

# Основная команда для полной настройки
setup: docker permissions dl php terminal init-dl
	@echo "\n\n"
	@echo "========================================================================"
	@echo "🎉 УСТАНОВКА ЗАВЕРШЕНА! 🎉"
	@echo "ВАЖНО: Пожалуйста, закройте этот терминал и откройте новый."
	@echo "Это необходимо для применения прав Docker и перехода на Zsh."
	@echo "Ваш терминал и VS Code уже настроены."
	@echo "========================================================================"

# Установка Docker & Docker-compose
docker:
	@echo "Шаг 1/8: Установка Docker и Docker Compose..."
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
	@echo "Шаг 2/8: Настройка прав доступа..."
	-sudo groupadd docker
	sudo usermod -aG docker ${USER}
	sudo mkdir -p /var/www
	sudo chown -R ${USER}:${USER} /var/www
	@echo "Права для Docker и /var/www настроены для пользователя ${USER}."

# Установка утилиты local-deploy (dl)
dl:
	@echo "Шаг 3/8: Установка local-deploy (dl)..."
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
	@echo "Шаг 4/8: Установка PHP 8.2 и необходимых расширений..."
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

# Кастомизация терминала
terminal:
	@echo "Шаг 5/8: Настройка терминала (Zsh, Oh My Zsh, Powerlevel10k)..."
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

# Инициализация окружения dl
init-dl:
	@echo "Шаг 8/8: Инициализация окружения local-deploy..."
	dl service up
	@echo "Окружение local-deploy инициализировано."

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
	@echo "VS Code version:" && code --version 2>/dev/null || echo "VS Code не установлен"
	@echo "Zsh version:" && zsh --version 2>/dev/null || echo "Zsh не установлен"
	@echo "DL version:" && dl --version 2>/dev/null || echo "DL не установлен"

.PHONY: help setup docker permissions dl php terminal vscode configure-vscode init-dl clean status
