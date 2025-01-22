#!/bin/bash
#ZSHELL:AUTO

# Проверка авторства в module.prop
MODULE_PROP="/data/adb/modules/InformationCarrierDevice/module.prop"
AUTHOR_STRING="author=Rinker001, ZerxFox & 永遠先考慮自己"
if ! grep -q "^$AUTHOR_STRING$" "$MODULE_PROP"; then
    echo "Error: Invalid module.prop authentication"
    exit 1
fi

JSON_OUTPUT="/data/adb/modules/InformationCarrierDevice/webroot/collector.json"

MODULE_DIR="/data/adb/modules/InformationCarrierDevice"
WEBROOT_DIR="$MODULE_DIR/webroot"
HTML_FILE="$WEBROOT_DIR/index.html"

su -c "mkdir -p $WEBROOT_DIR"

# Запускаем collector.sh в фоне если еще не запущен
if ! pgrep -f "collector.sh" > /dev/null; then
    su -c "bash -c /data/adb/modules/InformationCarrierDevice/collector.sh" &
fi

generate_html() {
    # Проверяем существование и читаемость JSON файла
    if [ ! -f "$JSON_FILE" ] || [ ! -r "$JSON_FILE" ]; then
        echo "Error: Cannot read collector.json"
        sleep 1
        return
    fi

    # Читаем данные из JSON файла
    local json_data=$(cat "$JSON_FILE")
    local battery_info=$(echo "$json_data" | jq '.battery')
    local system_info=$(echo "$json_data" | jq '.system')
    
    cat > "$HTML_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Device Monitor</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>Device Monitor</h1>
            <div class="theme-switcher">
                <input type="checkbox" id="theme-toggle">
                <label for="theme-toggle" class="theme-toggle-label"></label>
            </div>
        </header>

        <div class="cards-grid">
            <div class="card">
                <div class="title">Battery Information</div>
                <div class="battery-indicator">
                    <div class="battery-level" style="width: $(echo "$battery_info" | jq -r .capacity)%"></div>
                </div>
                <div class="info-item">
                    <span class="label">Capacity:</span>
                    <span class="value" id="battery-capacity">$(echo "$battery_info" | jq -r .capacity)%</span>
                </div>
                <div class="info-item">
                    <span class="label">Status:</span>
                    <span class="value" id="battery-status">$(echo "$battery_info" | jq -r .status)</span>
                </div>
                <div class="info-item">
                    <span class="label">Temperature:</span>
                    <span class="value" id="battery-temp">$(echo "$battery_info" | jq -r .temperature)°C</span>
                </div>
                <div class="info-item">
                    <span class="label">Voltage:</span>
                    <span class="value" id="battery-voltage">$(echo "$battery_info" | jq -r .voltage)V</span>
                </div>
                <div class="info-item">
                    <span class="label">Current:</span>
                    <span class="value" id="battery-current">$(echo "$battery_info" | jq -r .current)mA</span>
                </div>
                <div class="info-item">
                    <span class="label">Technology:</span>
                    <span class="value" id="battery-tech">$(echo "$battery_info" | jq -r .technology)</span>
                </div>
                <div class="info-item">
                    <span class="label">Health:</span>
                    <span class="value" id="battery-health">$(echo "$battery_info" | jq -r .health)</span>
                </div>
            </div>
            
            <div class="card">
                <div class="title">System Information</div>
                <div class="tabs">
                    <button class="tab-button active" data-tab="device">Device</button>
                    <button class="tab-button" data-tab="kernel">Kernel</button>
                    <button class="tab-button" data-tab="performance">Performance</button>
                </div>
                
                <div class="tab-content active" id="device">
                    <div class="info-item">
                        <span class="label">Device:</span>
                        <span class="value" id="device-model">$(echo "$system_info" | jq -r .device)</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Android Version:</span>
                        <span class="value" id="android-version">$(echo "$system_info" | jq -r .android)</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Build Number:</span>
                        <span class="value" id="build-number">$(echo "$system_info" | jq -r .build)</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Security Patch:</span>
                        <span class="value" id="security-patch">$(echo "$system_info" | jq -r .security_patch)</span>
                    </div>
                </div>
                
                <div class="tab-content" id="kernel">
                    <div class="info-item">
                        <span class="label">Kernel Version:</span>
                        <span class="value" id="kernel-version">$(echo "$system_info" | jq -r .kernel_version)</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Kernel Codename:</span>
                        <span class="value" id="kernel-codename">$(echo "$system_info" | jq -r .kernel_codename)</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Kernel Identifier:</span>
                        <span class="value" id="kernel-identifier">$(echo "$system_info" | jq -r .kernel_identifier)</span>
                    </div>
                </div>
                
                <div class="tab-content" id="performance">
                    <div class="info-item">
                        <span class="label">Number of CPU Cores:</span>
                        <span class="value" id="cpu-cores">$(echo "$system_info" | jq -r .num_cores)</span>
                    </div>
                    
                    <div class="cpu-details">
                        <h3>CPU Temperatures</h3>
                        $(echo "$system_info" | jq -r '.cpu_temps | to_entries[] | "<div class=\"info-item\"><span class=\"label\">\(.key):</span><span class=\"value\" id=\"temp-\(.key)\">\(.value)</span></div>"')
                    </div>
                
                    <div class="cpu-details">
                        <h3>CPU Frequencies</h3>
                        $(echo "$system_info" | jq -r '.cpu_freqs | to_entries[] | "<div class=\"info-item\"><span class=\"label\">\(.key):</span><span class=\"value\" id=\"freq-\(.key)\">\(.value)MHz</span></div>"')
                    </div>
                
                    <div class="cpu-details">
                        <h3>CPU Governors</h3>
                        $(echo "$system_info" | jq -r '.cpu_governors | to_entries[] | "<div class=\"info-item\"><span class=\"label\">\(.key):</span><span class=\"value\" id=\"gov-\(.key)\">\(.value)</span></div>"')
                    </div>
                    
                    <div class="info-item">
                        <span class="label">Total RAM:</span>
                        <span class="value" id="ram-total">$(echo "$system_info" | jq -r .total_ram)MB</span>
                    </div>
                    <div class="info-item">
                        <span class="label">Used RAM:</span>
                        <span class="value" id="ram-usage">$(echo "$system_info" | jq -r .used_ram)MB ($(echo "$system_info" | jq -r .ram_percentage)%)</span>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="refresh-info">Last updated: <span id="last-update">$(date '+%Y-%m-%d %H:%M:%S')</span></div>
    </div>
    <script src="main.js"></script>
</body>
</html>
EOF

    su -c "chmod 644 $HTML_FILE"
}

while true; do
    generate_html
    sleep 1
done