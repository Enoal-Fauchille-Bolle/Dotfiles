#!/usr/bin/env python3
"""
Zelotes F-36 – Sniper hold daemon (GNOME Wayland)
Recherche le device par nom + reconnexion automatique
"""

import asyncio
import subprocess
import evdev
from evdev import InputDevice, ecodes

# Cherche le device input-remapper forwarded qui contient KEY_F15
SNIPER_BUTTON = ecodes.KEY_F15
SNIPER_SPEED  = "-0.8"
GSETTINGS_KEY = ("org.gnome.desktop.peripherals.mouse", "speed")
RETRY_DELAY   = 3  # secondes entre chaque tentative


def gsettings_get() -> str:
    return subprocess.check_output(
        ["gsettings", "get", *GSETTINGS_KEY]
    ).decode().strip()


def gsettings_set(value: str) -> None:
    subprocess.run(["gsettings", "set", *GSETTINGS_KEY, value], check=True)


def find_device() -> InputDevice | None:
    """Trouve input-remapper keyboard (device générique d'injection)."""
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
            name = dev.name.lower()
            # Device générique keyboard d'input-remapper, pas un forwarded
            if name == "input-remapper keyboard":
                caps = dev.capabilities()
                keys = caps.get(ecodes.EV_KEY, [])
                if SNIPER_BUTTON in keys:
                    return dev
        except Exception:
            continue
    return None


async def watch(original_speed: str) -> None:
    while True:
        dev = find_device()
        if not dev:
            print(f"[sniper] Device introuvable, retry dans {RETRY_DELAY}s...")
            await asyncio.sleep(RETRY_DELAY)
            continue

        print(f"[sniper] Connecté : {dev.name} ({dev.path})")
        try:
            async for event in dev.async_read_loop():
                if event.type != ecodes.EV_KEY or event.code != SNIPER_BUTTON:
                    continue
                if event.value == 1:
                    gsettings_set(SNIPER_SPEED)
                    print("[sniper] ON")
                elif event.value == 0:
                    gsettings_set(original_speed)
                    print("[sniper] OFF")
        except OSError as e:
            print(f"[sniper] Device déconnecté ({e}), reconnexion dans {RETRY_DELAY}s...")
            gsettings_set(original_speed)
            await asyncio.sleep(RETRY_DELAY)


async def main() -> None:
    original_speed = gsettings_get()
    print(f"[sniper] Vitesse normale : {original_speed}")
    try:
        await watch(original_speed)
    except asyncio.CancelledError:
        pass
    finally:
        gsettings_set(original_speed)
        print("[sniper] Vitesse restaurée.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass