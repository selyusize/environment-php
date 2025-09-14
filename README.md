# Полная настройка PHP-окружения на Ubuntu (WSL2)

Это набор скриптов для **полностью автоматической** настройки рабочего окружения для PHP-разработки с использованием Docker, VS Code и терминала Zsh.

## Шаг 0: Предварительные требования (на Windows)

Перед началом убедитесь, что на вашей системе Windows установлена и настроена подсистема Windows для Linux (WSL2).

1.  **Включите WSL**: Откройте PowerShell от имени администратора и выполните `wsl --install`.
2.  **Установите Ubuntu 24.04**: В том же окне выполните `wsl --install -d Ubuntu-24.04`.
3.  **Создайте пользователя**: При первом запуске Ubuntu придумайте имя пользователя и пароль.
4.  **Установите Windows Terminal** из Microsoft Store для комфортной работы.

! **Сделайте Ubuntu 22.04 версией по умолчанию, если у вас несколько дистрибутивов в WSL**: В PowerShell выполните `wsl --set-default Ubuntu-24.04`.

## Шаг 1: Начальная настройка в Ubuntu

Запустите ваш терминал Ubuntu 22.04.

1.  **Обновление системы**:
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```
2.  **Установка `git` и `make`**:
    ```bash
    sudo apt install -y git make
    ```
3.  **Настройка Git**:
    ```bash
    git config --global user.name "Ваше Имя"
    git config --global user.email "ваш@email.com"
    ```

## Шаг 2: Клонирование репозитория и запуск установки

Теперь, когда все готово, можно приступить к автоматической настройке.

1.  **Клонирование репозитория**:
    ```bash
    cd ~
    git clone https://github.com/selyusize/php-environment.git
    cd php-environment
    ```
2.  **Запуск волшебной команды**:
    Выполните одну команду, которая запустит весь процесс. Скрипт будет запрашивать ваш пароль для выполнения `sudo` команд.
    ```bash
    make setup
    ```

Эта команда автоматически выполнит **все** необходимые действия:

- Установит Docker, Docker-compose и все зависимости.
- Настроит права доступа для Docker и для папки `/var/www`.
- Установит и настроит утилиту `local-deploy` (`dl`).
- Установит Zsh, Oh My Zsh, шрифт JetBrains Mono и **автоматически применит минималистичную конфигурацию терминала**, пропуская интерактивную настройку.
- Установит Visual Studio Code.
- **Автоматически установит тему "AMOLED Black Theme" в VS Code и применит все настройки** из файла `vscode/settings.json`.
- Запустит `dl service up` для инициализации PHP-окружения.

**ВАЖНО:** После завершения установки **полностью закройте терминал и откройте его заново**, чтобы все изменения, включая Zsh и права для Docker, вступили в силу.

## Шаг 3 (Опционально): Цвета терминала

Единственный шаг, который требует ручной настройки — это применение цветовой схемы в самом эмуляторе терминала (Windows Terminal).

1.  Откройте настройки Windows Terminal (`Ctrl + ,`) (Он находится в Windows, не в WSL).
2.  Нажмите "Открыть JSON-файл".
3.  В раздел `"schemes": []` добавьте объект:
    ```json
    {
    	"name": "AMOLED Black",
    	"background": "#000000",
    	"foreground": "#F0F0F0",
    	"black": "#000000",
    	"blue": "#007ACC",
    	"brightBlack": "#555555",
    	"brightBlue": "#3B9CFF",
    	"brightCyan": "#6CD8F7",
    	"brightGreen": "#50FA7B",
    	"brightPurple": "#BD93F9",
    	"brightRed": "#FF5555",
    	"brightWhite": "#FFFFFF",
    	"brightYellow": "#F1FA8C",
    	"cyan": "#4DC9F0",
    	"green": "#42E66C",
    	"purple": "#9F67FA",
    	"red": "#FF5555",
    	"white": "#F0F0F0",
    	"yellow": "#F1FA8C"
    }
    ```
4.  Сохраните файл. В настройках профиля Ubuntu (`profiles` -> `list` -> Ubuntu) добавьте строку: `"colorScheme": "AMOLED Black"`.

Готово!

Это проект с открытым исходным кодом, и я рад Вашим contribution. Чтобы предложить свои правки:
1. Форкните проект.
2. Создайте ветку для вашей функции (`git checkout -b feature/yourFeature`).
3. Закоммитьте изменения (`git commit -m 'feat: add your feature'`).
4. Запушьте ветку (`git push origin feature/yourFeature`).
5. Откройте Pull Request.
