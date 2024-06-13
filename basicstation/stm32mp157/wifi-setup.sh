#!/bin/bash

check_internet() {
    wget -q --spider http://google.com
    return $?
}

setup_wifi() {
    while true; do
        echo "Have you set up Wi-Fi on this device before and just need to change the SSID/Password? Type 'Y' for YES or 'N' for NO and then press ENTER"
        read response
        if [ "$response" != "N" -a "$response" != "Y" -a "$response" != "n" -a "$response" != "y" ]; then
            echo "Entry must be Y or N"
            continue # Go to the top of the loop
        fi
        break # Valid input given so exit the loop.
    done

    if [ "$response" == "Y" -o "$response" == "y" ]; then
        systemctl stop wpa_supplicant@wlan0.service
        systemctl disable wpa_supplicant@wlan0.service
        rm -r /etc/wpa_supplicant
    fi

    ifconfig wlan0 up
    echo "[Match]" > /lib/systemd/network/51-wireless.network
    echo "Name=wlan0" >> /lib/systemd/network/51-wireless.network
    echo "[Network]" >> /lib/systemd/network/51-wireless.network
    echo "DHCP=ipv4" >> /lib/systemd/network/51-wireless.network
    mkdir -p /etc/wpa_supplicant/
    echo "ctrl_interface=/var/run/wpa_supplicant" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "eapol_version=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "ap_scan=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "fast_reauth=1" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo "" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

    while true; do
        echo "Please type your wireless network name, also known as the SSID, and press ENTER"
        read ssid
        if [ -z "$ssid" ]; then
            echo "SSID cannot be empty"
            continue # Go to the top of the loop
        fi
        break # Valid input given so exit the loop.
    done

    while true; do
        echo "Please type the password of this SSID and press ENTER"
        read -s password
        if [ -z "$password" ]; then
            echo "Password cannot be empty"
            continue # Go to the top of the loop
        fi
        break # Valid input given so exit the loop.
    done

    wpa_passphrase "$ssid" "$password" >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    systemctl enable wpa_supplicant@wlan0.service
    systemctl restart systemd-networkd.service
    systemctl restart wpa_supplicant@wlan0.service
}

main() {
    if check_internet; then
        echo "Internet connection is available."
    else
        echo "No internet connection detected."
        while true; do
            echo "Do you want to set up Wi-Fi? Type 'Y' for YES or 'N' for NO and then press ENTER"
            read setup_response
            if [ "$setup_response" != "N" -a "$setup_response" != "Y" -a "$setup_response" != "n" -a "$setup_response" != "y" ]; then
                echo "Entry must be Y or N"
                continue # Go to the top of the loop
            fi
            break # Valid input given so exit the loop.
        done

        if [ "$setup_response" == "Y" -o "$setup_response" == "y" ]; then
            setup_wifi
        else
            echo "Internet setup skipped."
            exit 1
        fi
    fi

    # Run the station script
    /home/root/basicstation/projects/iotc/start-station.sh -l lns-iotc
}

main
