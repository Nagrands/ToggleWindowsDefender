# Скрипт PowerShell для переключения Windows Defender

## Обзор

Этот репозиторий содержит скрипт PowerShell, предназначенный для переключения состояния Windows Defender на компьютере с Windows. Скрипт может включать или отключать Windows Defender, управлять защитой от несанкционированного доступа и логировать все выполненные действия для аудита.

## Возможности

- Включение или отключение Windows Defender
- Управление защитой от несанкционированного доступа (Tamper Protection)
- Логирование всех действий в файл
- Проверка запуска скрипта с правами администратора

## Требования

- Операционная система Windows
- PowerShell 7 или новее
- Права администратора для выполнения скрипта

## Установка

1. Клонируйте этот репозиторий на ваш локальный компьютер:
    ```sh
    git clone https://github.com/Nagrands/ToggleWindowsDefender.git
    ```

2. Перейдите в директорию со скриптом:
    ```sh
    cd ToggleWindowsDefender
    ```

## Использование

1. Откройте PowerShell с правами администратора.

2. Запустите скрипт:
    ```sh
    ./ToggleWindowsDefender.ps1
    ```

## Описание скрипта

Скрипт выполняет следующие действия:

1. **Установка кодировки консоли**:
    Обеспечивает поддержку кириллических символов в консоли.

2. **Логирование сообщений**:
    Логирует все действия в файл `ToggleWindowsDefender.log` с временными метками.

3. **Проверка прав администратора**:
    Проверяет, запущен ли скрипт с правами администратора.

4. **Отключение/включение защиты от несанкционированного доступа**:
    Временно отключает защиту от несанкционированного доступа для изменения настроек Windows Defender.

5. **Проверка состояния Windows Defender**:
    Определяет, включен или отключен Windows Defender в данный момент.

6. **Переключение состояния Windows Defender**:
    Переключает состояние Windows Defender в зависимости от его текущего состояния.

7. **Включение защиты от несанкционированного доступа**:
    Повторно включает защиту от несанкционированного доступа после изменения настроек Windows Defender.

## Логирование

Все действия, выполняемые скриптом, логируются в файл `ToggleWindowsDefender.log`, расположенный в той же директории, что и скрипт. Лог содержит временные метки для каждого действия, что помогает при аудите.

## Устранение неполадок

- Убедитесь, что вы запускаете скрипт с правами администратора. Скрипт не будет работать корректно без необходимых прав.
- Проверьте файл журнала `ToggleWindowsDefender.log` для получения подробных сообщений об ошибках, если скрипт не выполнен правильно.

## Вклад в проект

Мы приветствуем вклад в улучшение функциональности этого скрипта. Если вы хотите внести свой вклад, пожалуйста, сделайте форк репозитория, внесите свои изменения и отправьте запрос на слияние.
