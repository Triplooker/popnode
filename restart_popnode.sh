#!/bin/bash

echo "🔄 Полное пересоздание POP ноды с сохранением данных"
echo "=================================================="

# Определяем данные
DATA_DIR="/root/popnode_data"

# Создаем директорию для данных, если её нет
if [ ! -d "$DATA_DIR" ]; then
    echo "📁 Создаем директорию для сохранения данных: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# Копируем текущие данные контейнера в DATA_DIR, если существует
if docker ps -a | grep -q popnode; then
    echo "📦 Копируем данные контейнера..."
    docker cp popnode:/app/data $DATA_DIR 2>/dev/null || echo "⚠️ Нет файла /app/data для копирования."
fi

# Удаляем старый контейнер
echo "🗑 Удаляем старый контейнер..."
docker rm -f popnode

# Спрашиваем invite код
echo "🔑 Введите invite код для нового контейнера:"
read -p "Invite код: " INVITE_CODE

if [ -z "$INVITE_CODE" ]; then
    echo "❌ Ошибка: Invite код не может быть пустым!"
    exit 1
fi

# Создаем и запускаем новый контейнер
echo "🚀 Создаем новый контейнер..."

docker run -d --name popnode --restart unless-stopped \
    -p 80:80 -p 443:443 \
    -v "$DATA_DIR:/app/data" \
    -e POP_INVITE_CODE="$INVITE_CODE" \
    popnode sh -c "rm -f .pop.lock 2>/dev/null; ./pop"

if [ $? -eq 0 ]; then
    echo "✅ Новый контейнер успешно создан и запущен!"
    echo "⏳ Ожидание инициализации (15 секунд)..."
    sleep 15

    # Получаем POP ID
    POP_INFO=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null)
    POP_ID=$(echo $POP_INFO | grep -o '"pop_id":"[^"]*"' | cut -d':' -f2 | tr -d '"')

    if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
        echo "🎯 POP ID: $POP_ID"
        echo "📈 ДАШБОРД: https://dashboard.testnet.pipe.network/node/$POP_ID"
    else
        echo "⚠️  Не удалось получить POP ID. Логи:"
        docker logs popnode --tail 10
    fi
else
    echo "❌ Ошибка при создании нового контейнера!"
    exit 1
fi

echo ""
echo "🎯 Готово!"
