:local pingTo1 "8.8.8.8";
:local pingTo2 "77.88.8.8";
:local pingCount 5;
:local stableConnectFrom 30;
:local gwList [:toarray "176.113.127.1, 172.16.128.1"]
:global routeComment "ROUTE"

# Функция возвращает шлюз маршрута по-умолчанию
:local GetDefaultRoute do={
    :global routeComment
    :return [/ip route get [find comment=$routeComment] gateway]
}

# Функция добавляет маршрут по-умолчанию с указанным шлюзом
# Формат вызова $AddDefaultRoute "192.168.66.1"
:local AddDefaultRoute do={
    :global routeComment
    /ip route add dst-address="0.0.0.0/0" gateway=$1 comment=$routeComment
}

# Функция удаляет маршрут по-умолчанию
# Формат вызова $RemDefaultRoute
:local RemDefaultRoute do={
    :global routeComment
    /ip route remove [find comment=$routeComment]
}

# Получив адрес шлюза мы поймем какой
# из каналов в данный момент активен
:local currentGW 
:do {
    :set currentGW [$GetDefaultRoute]
} on-error={ :set currentGW [:tostr [:pick $gwList 0]] }

# Максимальное количество итераций цикла
# должно быть равно количеству шлюзов
:local loopCount [:len $gwList]

# Счеткик цикла
:local counter 0

# Проверяем доступность хостов 
:local pingStatus1 [/ping $pingTo1 count=$pingCount];
:local pingStatus2 [/ping $pingTo2 count=$pingCount];
# Получаем общий статут доступности 
:local pingStatus (($pingStatus1 + $pingStatus2) * 100 / ($pingCount * 2) );
# Получаем процент потерь 
:if (($pingStatus1=0 and $pingStatus2=$pingCount) or ($pingStatus1=$pingCount and $pingStatus2=0)) do={
        :set pingStatus 100;
    }
# Проверяем на допустимость значения потерь 
:if ( $pingStatus <= $stableConnectFrom) do={
    while ($counter<$loopCount) do={
        # Получаем адрес шлюза из массива
        :local gwAddress [:tostr [:pick $gwList $counter]]
        # Проверять будем только шлюз,
        # отличный от активного
         if ($gwAddress!=$currentGW) do={
            # Удаляем не рабочий маршрут
            $RemDefaultRoute
            # Добавляем рабочий маршрут
            $AddDefaultRoute $gwAddress
         }
        :set counter ($counter + 1)
    }
}