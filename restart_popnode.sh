#!/bin/bash

echo "🔄 Скрипт перезапуска POP ноды"
echo "================================"

# Проверяем, есть ли запущенный контейнер popnode
if docker ps -a | grep -q popnode; then
    echo "📋 Найден существующий контейнер popnode"
    echo "🛑 Останавливаем и удаляем старый контейнер..."
    docker stop popnode >/dev/null 2>&1
    docker rm popnode >/dev/null 2>&1
    echo "✅ Старый контейнер удален"
else
    echo "ℹ️  Контейнер popnode не найден"
fi

# Запрашиваем invite код
echo ""
echo "🔑 Введите invite код для этого сервера:"
read -p "Invite код: " INVITE_CODE

# Проверяем, что invite код не пустой
if [ -z "$INVITE_CODE" ]; then
    echo "❌ Ошибка: Invite код не может быть пустым!"
    exit 1
fi

echo ""
echo "🚀 Запускаем новый контейнер с invite кодом..."

# Запускаем новый контейнер
docker run -d --name popnode --restart unless-stopped -e POP_INVITE_CODE="$INVITE_CODE" popnode sh -c "rm -f .pop.lock 2>/dev/null; ./pop"

if [ $? -eq 0 ]; then
    echo "✅ Контейнер успешно запущен!"
    
    # Ждем несколько секунд для инициализации
    echo "⏳ Ожидание инициализации (5 секунд)..."
    sleep 5
    
    # Проверяем статус
    if docker ps | grep -q popnode; then
        echo "🎉 Контейнер работает!"
        echo ""
        echo "📊 Последние логи:"
        docker logs popnode --tail 10
        echo ""
        echo "🔍 Для проверки работы выполните:"
        echo "docker exec popnode curl -sk https://localhost/"
    else
        echo "❌ Контейнер не работает. Логи:"
        docker logs popnode --tail 20
    fi
else
    echo "❌ Ошибка при запуске контейнера!"
    exit 1
fi
