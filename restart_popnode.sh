#!/bin/bash

echo "🔄 Скрипт перезапуска POP ноды с сохранением данных"
echo "================================================="

# Создаем директорию для данных ноды, если её нет
DATA_DIR="/root/popnode_data"
if [ ! -d "$DATA_DIR" ]; then
    echo "📁 Создаем директорию для данных ноды: $DATA_DIR"
    mkdir -p "$DATA_DIR"
fi

# Проверяем, есть ли запущенный контейнер popnode
if docker ps -a | grep -q popnode; then
    echo "📋 Найден существующий контейнер popnode"
    echo "🛑 Останавливаем старый контейнер..."
    docker stop popnode > /dev/null 2>&1
    
    # НЕ удаляем контейнер, чтобы сохранить данные
    echo "⏸️  Контейнер остановлен (данные сохранены)"
    
    # Запускаем существующий контейнер
    echo "🚀 Запускаем существующий контейнер..."
    docker start popnode
    
    if [ $? -eq 0 ]; then
        echo "✅ Контейнер успешно запущен!"
        
        # Ждем несколько секунд для инициализации
        echo "⏳ Ожидание инициализации (10 секунд)..."
        sleep 10
        
        # Получаем POP ID
        echo ""
        echo "🆔 Получаем POP ID..."
        POP_ID=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '"pop_id":"[^"]*"' | cut -d'"' -f4)
        
        if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
            echo "🎯 POP ID: $POP_ID"
            echo ""
            echo "📈 ДАШБОРД НОДЫ:"
            echo "🔗 https://dashboard.testnet.pipe.network/node/$POP_ID"
        else
            echo "⚠️  Не удалось получить POP ID. Попробуйте через несколько минут."
        fi
        
        echo ""
        echo "📊 Последние логи:"
        docker logs popnode --tail 10
        
        exit 0
    else
        echo "❌ Ошибка при запуске существующего контейнера!"
        echo "🔄 Попробуем создать новый контейнер..."
        docker rm popnode > /dev/null 2>&1
    fi
else
    echo "ℹ️  Контейнер popnode не найден"
fi

# Если мы здесь, значит нужно создать новый контейнер
echo ""
echo "🔑 Введите invite код для этого сервера:"
read -p "Invite код: " INVITE_CODE

# Проверяем, что invite код не пустой
if [ -z "$INVITE_CODE" ]; then
    echo "❌ Ошибка: Invite код не может быть пустым!"
    exit 1
fi

echo ""
echo "🚀 Создаем новый контейнер с постоянным хранилищем данных..."
echo "🌐 Порты: 80 (HTTP) и 443 (HTTPS) будут доступны извне"
echo "💾 Данные будут сохранены в: $DATA_DIR"

# Запускаем новый контейнер с volume для сохранения данных
docker run -d --name popnode --restart unless-stopped \
    -p 80:80 -p 443:443 \
    -v "$DATA_DIR:/app/data" \
    -e POP_INVITE_CODE="$INVITE_CODE" \
    popnode sh -c "./pop"

if [ $? -eq 0 ]; then
    echo "✅ Контейнер успешно запущен!"
    
    # Ждем несколько секунд для инициализации
    echo "⏳ Ожидание инициализации (15 секунд)..."
    sleep 15
    
    # Проверяем статус
    if docker ps | grep -q popnode; then
        echo "🎉 Контейнер работает!"
        
        # Показываем информацию о портах
        echo ""
        echo "🔌 Проброшенные порты:"
        docker port popnode
        
        echo ""
        echo "📊 Последние логи:"
        docker logs popnode --tail 10
        
        # Проверяем доступность снаружи
        echo ""
        echo "🌐 Проверяем доступность снаружи..."
        
        if curl -s --connect-timeout 3 http://localhost/ > /dev/null 2>&1; then
            echo "✅ HTTP (порт 80) доступен снаружи"
        else
            echo "❌ HTTP (порт 80) не доступен снаружи"
        fi
        
        if curl -sk --connect-timeout 3 https://localhost/ > /dev/null 2>&1; then
            echo "✅ HTTPS (порт 443) доступен снаружи"
        else
            echo "❌ HTTPS (порт 443) не доступен снаружи"
        fi
        
        # Получаем POP ID и показываем ссылку на дашборд
        echo ""
        echo "🆔 Получаем POP ID..."
        sleep 5
        
        POP_ID=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '"pop_id":"[^"]*"' | cut -d'"' -f4)
        
        if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
            echo "🎯 POP ID: $POP_ID"
            echo ""
            echo "📈 ДАШБОРД НОДЫ:"
            echo "🔗 https://dashboard.testnet.pipe.network/node/$POP_ID"
            echo ""
            echo "📋 Сохраните эту ссылку для мониторинга статистики вашей ноды!"
            echo "💾 Данные ноды сохраняются в $DATA_DIR"
        else
            echo "⚠️  Не удалось получить POP ID. Попробуйте через несколько минут:"
            echo "   docker exec popnode curl -sk https://localhost/state | grep pop_id"
        fi
        
    else
        echo "❌ Контейнер не работает. Логи:"
        docker logs popnode --tail 20
    fi
else
    echo "❌ Ошибка при запуске контейнера!"
    exit 1
fi

echo ""
echo "🎯 Готово! Ваша CDN нода теперь доступна извне на портах 80 и 443"
echo "💡 При следующем перезапуске POP ID и прогресс будут сохранены!"
