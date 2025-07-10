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

# Копируем текущие данные контейнера в DATA_DIR, если контейнер существует
if docker ps -a | grep -q popnode; then
    echo "📦 Копируем данные из существующего контейнера..."
    docker cp popnode:/app/data $DATA_DIR 2>/dev/null || echo "⚠️ Нет данных для копирования"
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
    echo "⏳ Ожидание инициализации (20 секунд)..."
    sleep 20

    # Получаем POP ID - исправленная версия
    STATE_JSON=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null)
    POP_ID=$(echo "$STATE_JSON" | grep -o '"pop_id":"[^"]*"' | sed 's/"pop_id":"//g' | sed 's/"//g')

    if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
        echo "🎯 POP ID: $POP_ID"
        echo "📈 ДАШБОРД: https://dashboard.testnet.pipe.network/node/$POP_ID"
        echo "💾 Данные сохранены в: $DATA_DIR"
    else
        echo "⚠️  Не удалось получить POP ID. Возможно, нода еще инициализируется."
        echo "📊 Логи контейнера:"
        docker logs popnode --tail 10
        echo ""
        echo "💡 Попробуйте получить POP ID через несколько минут:"
        echo "   docker exec popnode curl -sk https://localhost/state | grep pop_id"
    fi
else
    echo "❌ Ошибка при создании нового контейнера!"
    exit 1
fi

echo ""
echo "🎯 Готово! При следующих перезапусках данные будут сохранены!"
