#!/bin/bash

VPN_NAME="Freebox-Maison"

if nmcli connection show --active | grep -q "$VPN_NAME"; then
    nmcli connection down "$VPN_NAME"
else
    nmcli connection up "$VPN_NAME"
fi
