#!/system/bin/bash
#ZSHELL:AUTO

# Проверка авторства в module.prop
MODULE_PROP="/data/adb/modules/InformationCarrierDevice/module.prop"
AUTHOR_STRING="author=Rinker001, ZerxFox & 永遠先考慮自己"
if ! grep -q "^$AUTHOR_STRING$" "$MODULE_PROP"; then
    echo "Error: Invalid module.prop authentication"
    exit 1
fi

JSON_OUTPUT="/data/adb/modules/InformationCarrierDevice/webroot/collector.json"

collect_data() {
    while true; do
        # Получаем данные батареи
        capacity=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        [ -z "$capacity" ] && capacity=$(dumpsys battery | grep level | awk '{print $2}')

        status=$(cat /sys/class/power_supply/battery/status 2>/dev/null) 
        [ -z "$status" ] && status=$(dumpsys battery | grep status | awk '{print $2}')

        temp=$(cat /sys/class/power_supply/battery/temp 2>/dev/null)
        [ -z "$temp" ] && temp=$(dumpsys battery | grep temperature | awk '{print $2}')

        voltage=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
        [ -z "$voltage" ] && voltage=$(dumpsys battery | grep voltage | awk '{print $2}')

        current=$(cat /sys/class/power_supply/battery/current_now 2>/dev/null)
        [ -z "$current" ] && current=$(dumpsys battery | grep current | awk '{print $2}')

        technology=$(cat /sys/class/power_supply/battery/technology 2>/dev/null)
        [ -z "$technology" ] && technology=$(dumpsys battery | grep technology | awk '{print $2}')

        health=$(cat /sys/class/power_supply/battery/health 2>/dev/null)
        [ -z "$health" ] && health=$(dumpsys battery | grep health | awk '{print $2}')

        temp=$(echo "scale=1; $temp/10" | bc)
        voltage=$(echo "scale=1; $voltage/1000" | bc) 
        current=$(echo "scale=1; $current/1000" | bc)

        # Системная информация
        kernel_version=$(uname -r | cut -d'/' -f1 2>/dev/null || echo "Unknown")
        kernel_codename=$(uname -r | cut -d'/' -f3 2>/dev/null || echo "Unknown")
        kernel_identifier=$(uname -r | cut -d'/' -f5 2>/dev/null || echo "Unknown")
        device=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
        android=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        build=$(getprop ro.build.display.id 2>/dev/null || echo "Unknown")
        security_patch=$(getprop ro.build.version.security_patch 2>/dev/null || echo "Unknown")
        num_cores=$(nproc 2>/dev/null || echo "1")
        total_ram=$(free -m | grep Mem: | awk '{print $2}' 2>/dev/null || echo "N/A")
        used_ram=$(free -m | grep Mem: | awk '{print $3}' 2>/dev/null || echo "N/A")
        ram_percentage=$(awk "BEGIN {printf \"%.1f\", ($used_ram/$total_ram)*100}" || echo "N/A")

        # Сбор температур
        temp_data="{}"
        for zone in /sys/class/thermal/thermal_zone*; do
            if [ -f "$zone/temp" ] && [ -f "$zone/type" ]; then
                zone_type=$(cat "$zone/type" 2>/dev/null | tr -cd '[:alnum:]_-')
                temp_val=$(cat "$zone/temp" 2>/dev/null)
                if [ -n "$temp_val" ] && [ -n "$zone_type" ]; then
                    # Удаляем все нецифровые символы и пробелы
                    temp_val=$(echo "$temp_val" | tr -cd '0-9.-')
                    
                    # Конвертируем различные форматы в градусы Цельсия
                    # milli°C (пример: 40000)
                    if [ $(echo "$temp_val >= 1000" | bc -l) -eq 1 ] && [ $(echo "$temp_val < 100000" | bc -l) -eq 1 ]; then
                        temp_val=$(echo "scale=1; $temp_val/1000" | bc 2>/dev/null)
                    # micro°C (пример: 40000000) 
                    elif [ $(echo "$temp_val >= 100000" | bc -l) -eq 1 ] && [ $(echo "$temp_val < 100000000" | bc -l) -eq 1 ]; then
                        temp_val=$(echo "scale=1; $temp_val/1000000" | bc 2>/dev/null)
                    # deci°C (пример: 400)
                    elif [ $(echo "$temp_val > 200" | bc -l) -eq 1 ] && [ $(echo "$temp_val < 1000" | bc -l) -eq 1 ]; then
                        temp_val=$(echo "scale=1; $temp_val/10" | bc 2>/dev/null)
                    # Уже в °C (пример: 40)
                    elif [ $(echo "$temp_val <= 200" | bc -l) -eq 1 ] && [ $(echo "$temp_val >= -273" | bc -l) -eq 1 ]; then
                        temp_val=$(echo "scale=1; $temp_val" | bc 2>/dev/null)
                    else
                        # Некорректное значение
                        temp_val=""
                    fi
        
                    # Проверяем границы температур и форматируем вывод
                    if [ -n "$temp_val" ] && [ "$temp_val" != "0" ]; then
                        temp_float=$(echo "$temp_val" | bc 2>/dev/null)
                        # Проверка на физически возможные температуры
                        if (( $(echo "$temp_float < -273.15" | bc -l) )) || (( $(echo "$temp_float > 185" | bc -l) )); then
                            temp_val="<Going beyond>"
                        else
                            # Округляем до одного знака после запятой
                            temp_val=$(printf "%.1f°C" "$temp_float")
                        fi
                        temp_data=$(echo "$temp_data" | jq --arg key "$zone_type" --arg val "$temp_val" '. + {($key): $val}')
                    fi
                fi
            fi
        done

        # Сбор частот и губернаторов CPU
        freq_data="{}"
        gov_data="{}"
        for ((i=0; i<num_cores; i++)); do
            freq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq 2>/dev/null)
            if [ -n "$freq" ]; then
                freq=$(echo "scale=1; $freq/1000" | bc 2>/dev/null || echo "0")
                freq_data=$(echo "$freq_data" | jq --arg key "cpu$i" --arg val "$freq" '. + {($key): $val}')
            fi

            governor=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null)
            if [ -n "$governor" ]; then
                gov_data=$(echo "$gov_data" | jq --arg key "cpu$i" --arg val "$governor" '. + {($key): $val}')
            fi
        done

        # Формируем финальный JSON и сохраняем в файл
        jq -n \
            --arg capacity "$capacity" \
            --arg status "$status" \
            --arg temperature "$temp" \
            --arg voltage "$voltage" \
            --arg current "$current" \
            --arg technology "$technology" \
            --arg health "$health" \
            --arg kernel_version "$kernel_version" \
            --arg kernel_codename "$kernel_codename" \
            --arg kernel_identifier "$kernel_identifier" \
            --arg device "$device" \
            --arg android "$android" \
            --arg build "$build" \
            --arg security_patch "$security_patch" \
            --arg total_ram "$total_ram" \
            --arg used_ram "$used_ram" \
            --arg ram_percentage "$ram_percentage" \
            --arg num_cores "$num_cores" \
            --argjson cpu_temps "$temp_data" \
            --argjson cpu_freqs "$freq_data" \
            --argjson cpu_governors "$gov_data" \
            '{
                "battery": {
                    "capacity": $capacity,
                    "status": $status,
                    "temperature": $temperature,
                    "voltage": $voltage,
                    "current": $current,
                    "technology": $technology,
                    "health": $health
                },
                "system": {
                    "kernel_version": $kernel_version,
                    "kernel_codename": $kernel_codename,
                    "kernel_identifier": $kernel_identifier,
                    "device": $device,
                    "android": $android,
                    "build": $build,
                    "security_patch": $security_patch,
                    "cpu_temps": $cpu_temps,
                    "total_ram": $total_ram,
                    "used_ram": $used_ram,
                    "ram_percentage": $ram_percentage,
                    "cpu_freqs": $cpu_freqs,
                    "cpu_governors": $cpu_governors,
                    "num_cores": $num_cores
                }
            }' > "$JSON_OUTPUT"

    done
}

collect_data &