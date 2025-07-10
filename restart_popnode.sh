#!/bin/bash

echo "🔄 Восстановление POP ноды с сохранением старого POP ID"
echo "====================================================="

# Проверяем, есть ли запущенный контейнер
if docker ps | grep -q popnode; then
    echo "⚠️  Контейнер popnode уже запущен"
    echo "🆔 Текущий POP ID:"
    docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '"pop_id":"[^"]*"' | cut -d'"' -f4
    exit 0
fi

# Проверяем, есть ли остановленный контейнер
if docker ps -a | grep -q popnode; then
    echo "📋 Найден остановленный контейнер popnode"
    echo "🚀 Запускаем существующий контейнер..."
    
    docker start popnode
    
    if [ $? -eq 0 ]; then
        echo "✅ Контейнер успешно запущен!"
        
        # Ждем инициализации
        echo "⏳ Ожидание инициализации (10 секунд)..."
        sleep 10
        
        # Получаем POP ID
        echo ""
        echo "🆔 Получаем POP ID..."
        POP_ID=$(docker exec popnode curl -sk https://localhost/state 2>/dev/null | grep -o '"pop_id":"[^"]*"' | cut -d'"' -f4)
        
        if [ ! -z "$POP_ID" ] && [ "$POP_ID" != "null" ]; then
            echo "🎯 Восстановленный POP ID: $POP_ID"
            echo ""
            echo "📈 ДАШБОРД НОДЫ:"
            echo "🔗 https://dashboard.testnet.pipe.network/node/$POP_ID"
            echo ""
            echo "✅ Ваш старый POP ID и прогресс восстановлены!"
        else
            echo "⚠️  Не удалось получить POP ID. Попробуйте через несколько минут."
        fi
        
        echo ""
        echo "📊 Последние логи:"
        docker logs popnode --tail 10
        
    else
        echo "❌ Ошибка при запуске контейнера!"
        exit 1
    fi
else
    echo "❌ Контейнер popnode не найден. Возможно, он был удален."
    echo "💡 Используйте ./restart_popnode.sh для создания нового контейнера"
    exit 1
fi

echo ""
echo "🎯 Готово! Ваша нода восстановлена с сохранением POP ID!"
