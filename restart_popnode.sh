#!/bin/bash

echo "🔄 Скрипт перезапуска POP ноды"
echo "=============================="

# Проверяем, есть ли контейнер popnode
if docker ps -a | grep -q popnode; then
    echo "📋 Найден существующий контейнер popnode"
    echo "🛑 Останавливаем контейнер..."
    docker stop popnode > /dev/null 2>&1
    
    echo "🧹 Очищаем блокировочный файл и перезапускаем..."
    docker start popnode > /dev/null 2>&1
    sleep 2
    
    # Убиваем старый процесс и запускаем новый
    docker exec popnode sh -c "pkill -f './pop' 2>/dev/null || true; rm -f .pop.lock 2>/dev/null || true; nohup ./pop >/dev/null 2>&1 &" > /dev/null 2>&1
    
    echo "⏳ Ожидание инициализации (15 секунд)..."
    sleep 15
    
    # Получаем POP ID
    POP_ID=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '\"pop_id\":\"[^\"]*\"' | cut -d'\"' -f4)
    
    if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
        echo "✅ Контейнер перезапущен успешно!"
        echo "🎯 POP ID: $POP_ID"
        echo "📈 ДАШБОРД: https://dashboard.testnet.pipe.network/node/$POP_ID"
    else
        echo "⚠️  Не удалось получить POP ID. Логи:"
        docker logs popnode --tail 10
    fi
    
    exit 0
fi

# Если контейнера нет, создаем новый
echo "ℹ️  Контейнер popnode не найден. Создаем новый..."
echo ""
echo "🔑 Введите invite код:"
read -p "Invite код: " INVITE_CODE

if [ -z "$INVITE_CODE" ]; then
    echo "❌ Ошибка: Invite код не может быть пустым!"
    exit 1
fi

echo ""
echo "🚀 Создаем новый контейнер..."

docker run -d --name popnode --restart unless-stopped \
    -p 80:80 -p 443:443 \
    -e POP_INVITE_CODE="$INVITE_CODE" \
    popnode sh -c "rm -f .pop.lock 2>/dev/null; ./pop"

if [ $? -eq 0 ]; then
    echo "✅ Контейнер создан!"
    echo "⏳ Ожидание инициализации (15 секунд)..."
    sleep 15
    
    # Получаем POP ID
    POP_ID=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '\"pop_id\":\"[^\"]*\"' | cut -d'\"' -f4)
    
    if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
        echo "🎯 POP ID: $POP_ID"
        echo "📈 ДАШБОРД: https://dashboard.testnet.pipe.network/node/$POP_ID"
        echo "💡 При следующем перезапуске POP ID сохранится!"
    else
        echo "⚠️  Не удалось получить POP ID. Логи:"
        docker logs popnode --tail 10
    fi
else
    echo "❌ Ошибка при создании контейнера!"
    exit 1
fi

echo ""
echo "🎯 Готово!"
