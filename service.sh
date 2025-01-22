#!/system/bin/bash
#ZHELL:AUTO

# Проверка авторства в module.prop
MODULE_PROP="/data/adb/modules/InformationCarrierDevice/module.prop"
AUTHOR_STRING="author=Rinker001, ZerxFox & 永遠先考慮自己"

if ! grep -q "^$AUTHOR_STRING$" "$MODULE_PROP"; then
    echo "Error: Invalid module.prop authentication"
    exit 1
fi

mkdir -p /data/adb/modules/InformationCarrierDevice/logs

while [[ -z $(ls /sdcard) ]]; do
  sleep 5
done

sleep 10

create_collector_json() {
    local collector_json="/data/adb/modules/InformationCarrierDevice/webroot/collector.json"
    if [ ! -f "$collector_json" ]; then
        echo "{}" > "$collector_json"
        echo "Created $collector_json" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
    fi
}

start_collector() {
    su -c "bash /data/adb/modules/InformationCarrierDevice/collector.sh" &
    echo "Started collector.sh" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
}

start_main() {
    su -c "bash /data/adb/modules/InformationCarrierDevice/main.sh" &
    echo "Started main.sh" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
}

create_collector_json
start_collector
start_main

echo "Script finished successfully" >> /data/adb/modules/InformationCarrierDevice/logs/service.log