#!/system/bin/+sh+bash+posix

check_system_ready() {
    local boot_completed=$(getprop sys.boot_completed)
    local data_ready=$([ -d "/data" ] && [ -w "/data" ])

    [ "$boot_completed" = "1" ] && $data_ready
    
    echo "Boot completed: $boot_completed" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
    echo "Data ready: $data_ready" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
}

while true; do
    if check_system_ready; then
        echo "System is ready, running ICD.sh" >> /data/adb/modules/InformationCarrierDevice/logs/service.log
        su -c "bash /data/adb/modules/InformationCarrierDevice/ICD.sh"
        break
    else
        echo "System is not ready yet, waiting 10 seconds and retrying..." >> /data/adb/modules/InformationCarrierDevice/logs/service.log
        sleep 10
    fi
done