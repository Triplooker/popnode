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
echo "🚀 Запускаем новый контейнер с invite кодом и пробросом портов..."
echo "🌐 Порты: 80 (HTTP) и 443 (HTTPS) будут доступны извне"

# Запускаем новый контейнер с пробросом портов
docker run -d --name popnode --restart unless-stopped \
    -p 80:80 -p 443:443 \
    -e POP_INVITE_CODE="$INVITE_CODE" \
    popnode sh -c "rm -f .pop.lock 2>/dev/null; ./pop"

if [ $? -eq 0 ]; then
    echo "✅ Контейнер успешно запущен!"
    
    # Ждем несколько секунд для инициализации
    echo "⏳ Ожидание инициализации (5 секунд)..."
    sleep 5
    
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
        
        echo ""
        echo "🔍 Проверка работы:"
        echo "  Внутри контейнера: docker exec popnode curl -sk https://localhost/"
        echo "  Снаружи (HTTP):    curl -s http://localhost/"
        echo "  Снаружи (HTTPS):   curl -sk https://localhost/"
        
        # Проверяем доступность снаружи
        echo ""
        echo "🌐 Проверяем доступность снаружи..."
        
        if curl -s --connect-timeout 3 http://localhost/ >/dev/null 2>&1; then
            echo "✅ HTTP (порт 80) доступен снаружи"
        else
            echo "❌ HTTP (порт 80) не доступен снаружи"
        fi
        
        if curl -sk --connect-timeout 3 https://localhost/ >/dev/null 2>&1; then
            echo "✅ HTTPS (порт 443) доступен снаружи"
        else
            echo "❌ HTTPS (порт 443) не доступен снаружи"
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
