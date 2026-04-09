#!/bin/bash

set -e

MONITOR_BUS=10

function monitor_present() {
  ddcutil getvcp --bus "$MONITOR_BUS" 10 &>/dev/null
}

function set_normal() {
  if monitor_present; then
    ddcutil --bus "$MONITOR_BUS" setvcp 10 70
    ddcutil --bus "$MONITOR_BUS" setvcp 12 70
  else
    echo "Monitor not detected on bus $MONITOR_BUS, skipping ddcutil commands."
  fi
  gdbus call --session --dest org.gnome.SettingsDaemon.Power \
    --object-path /org/gnome/SettingsDaemon/Power \
    --method org.freedesktop.DBus.Properties.Set \
    org.gnome.SettingsDaemon.Power.Screen Brightness "<int32 100>"
}

function set_baby() {
  if monitor_present; then
    ddcutil --bus "$MONITOR_BUS" setvcp 10 5
    ddcutil --bus "$MONITOR_BUS" setvcp 12 5
  else
    echo "Monitor not detected on bus $MONITOR_BUS, skipping ddcutil commands."
  fi
  gdbus call --session --dest org.gnome.SettingsDaemon.Power \
    --object-path /org/gnome/SettingsDaemon/Power \
    --method org.freedesktop.DBus.Properties.Set \
    org.gnome.SettingsDaemon.Power.Screen Brightness "<int32 5>"
}

case "$1" in
  normal)
    set_normal
    ;;
  baby)
    set_baby
    ;;
  *)
    echo "Usage: $0 {normal|baby}"
    exit 1
    ;;
esac
