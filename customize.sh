#!/system/bin/sh

### SIMON - Counter-support of the "GHOST Project" hub

echo -e "
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ㅤInformationCarrierDeviceㅤㅤㅤㅤㅤㅤ SIMON
┃"

####################
### Universal testing tool
####################
echo -e "┃\n┣ Setting up test permissions..."
set_permissions() {
    set_perm_recursive $MODPATH/system 0 0 0777 0755
    set_perm $MODPATH/system/bin/bash 0 0 0755
    set_perm $MODPATH/system/bin/jq 0 0 0755
}
set_permissions && sleep 0.8
echo -e "┃\n┣ Setting permissions successfully...\n┃"

echo -e "┣ Checking the required utilities..."
BASH_VERSION=$(su -c "bash --version" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')
if [ "$BASH_VERSION" = "5.2.37" ]; then
    echo -e "┃>> [Success]: Bash version $BASH_VERSION found."
    rm -f "$MODPATH/system/bin/bash"
else
    echo -e "┃>> [Error]: Bash version $BASH_VERSION not supported or not found. A compatible version (5.2.37) will be installed."
fi
sleep 0.8

JQ_VERSION=$(su -c "jq --version" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+')
if [ "$JQ_VERSION" = "1.7.1" ]; then
    echo -e "┃>> [Success]: JQ version $JQ_VERSION found."
    rm -f "$MODPATH/system/bin/jq"
else
    echo -e "┃>> [Error]: JQ version $JQ_VERSION not supported or not found. A compatible version (1.7.1) will be installed."
fi

if [ "$BASH_VERSION" = "5.2.37" ] && [ "$JQ_VERSION" = "1.7.1" ]; then
    echo -e "┣ Verification completed..."
    echo -e "┃\n┣ Cleaning residual files..."
    
    for file in "$MODPATH/system/"*
    do
        if [ -f "$file" ]; then
            echo -e "┃>> [Removed]: $file"
            su -c "rm -f '$file'"
        elif [ -d "$file" ]; then
            echo -e "┃>> [Removed]: $file"
            su -c "rm -rf '$file'"
        fi
    done
    
    echo -e "┣ Residual files have been successfully removed...\n┃"
fi

sleep 0.8

#############################
### The main part of the installation
#############################
echo -e "┃\n┣ Setting permissions..."
set_permissions() {
    set_perm_recursive $MODPATH 0 0 0777 0755
    set_perm $MODPATH/service.sh 0 0 0755
    set_perm $MODPATH/collector.sh 0 0 0755
    set_perm $MODPATH/main.sh 0 0 0755
    set_perm $MODPATH/LICENCE 0 0 0000
    set_perm $MODPATH/LICENCE.v2 0 0 0000
}
set_permissions && sleep 0.8
echo -e "┣ Setting permissions successfully...\n┃"

echo -e "┃\n┗ Initialization script completed successfully!\n"
