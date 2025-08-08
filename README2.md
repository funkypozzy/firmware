
# Customised OpenIPC Firmware for IVG G6S (GK7205V300 + Sony IMX335)
### with the IPC-38x38-WIFI-IF V1.02 WiFi/SD Board (ATBM603x chipset)

---

## Overview

This guide explains how to customize and build the OpenIPC firmware for the IVG G6S IP camera model featuring the GK7205V300 SoC and Sony IMX335 image sensor. The customization focuses on enabling WiFi connectivity using the IPC-38x38-WIFI-IF V1.02 board (ATBM603x chipset), allowing the camera to connect to your home WiFi network **without requiring a wired Ethernet or UART connection after the initial firmware flash**.

This enables convenient wireless access and further configuration via SSH or CLI.

---

## Repository Setup and Branch Strategy

1. **Fork** the official OpenIPC firmware repository to your own GitHub account.
2. Create a new branch named `wifi` from your fork.  
   This keeps your changes isolated and easy to track, while preserving the original repository.
3. Use this branch for your WiFi-related customizations and testing.

![OpenIPC Firmware Branch Diagram](https://github.com/user-attachments/assets/226fbad1-3bf7-4fd5-a5b6-ad63b9eab8b4)

---

## Hardware Requirements

- **IVG G6S IP Camera** with the **IPC-38x38-WIFI-IF V1.02** WiFi/SD expansion board (based on ATBM603x chip).  
- **12V power supply** for the camera.
- **Ethernet cable** (for initial flashing only).
- **FTDI USB-to-Serial adapter** (3.3V logic level, mini-USB connector recommended).  
- **Wiring tools** to connect FTDI adapter TX, RX, and GND to the camera UART pins.  
  ![UART Connection Example](https://github.com/user-attachments/assets/ac0ab764-4299-4e69-966c-97fbb0092130)  
- **A computer running Ubuntu 22.04** (physical or VM) to build the firmware.  
  *Note:* Firmware build on Raspbian (RPi4/5) is not supported.
- **A computer running Windows or Linux** to run PuTTY (or equivalent terminal emulator) and a TFTP server.  
- **Network setup:** Ethernet connection between the computer running the TFTP server and the camera for firmware upload.

![WiFi/SD Board Images](https://github.com/user-attachments/assets/26a63724-caa8-4dd7-91f2-a11ff5306fbe)  
![Camera Board](https://github.com/user-attachments/assets/023cc734-7e30-40a9-97f6-a4408ba3ab03)

---

## Software Requirements

- **TFTP server software** (e.g., [Tftpd64](https://pjo2.github.io/tftpd64/)) configured correctly with firewall exceptions.  
  ![TFTPD64](https://github.com/user-attachments/assets/f0898e11-57f6-47f5-b634-25aad02b4c9f)
- **Ubuntu 22.04** with at least 20GB free storage for building the firmware.
- **PuTTY or similar SSH/telnet client** for serial console and remote access.  
  ![PuTTY](https://github.com/user-attachments/assets/1998ea98-33e3-4eb8-b1b7-8c46bc77c10f)

---

## Background and Motivation

I needed a **low-cost IP camera** with **good low-light color vision** for discreet monitoring of a parking area up to 80m away, without using infrared or white light.

**Requirements:**  
- Affordable IP camera  
- No proprietary cloud or app lock-in  
- RTSP streaming support  
- Built-in WiFi connectivity  
- Sony IMX335 sensor for low-light performance  

After researching options like Hikvision Darkfighter and Dahua Starlight (both expensive), I chose the **GK7205V300 + Sony IMX335 board** with WiFi module (~33€ from AliExpress). The stock Chinese firmware required a Windows-only plugin, so I switched to **OpenIPC open source firmware** for better flexibility.

---

## Flashing the Original Firmware

The stock firmware was password-protected, so I used the [Debrick utility](https://github.com/OpenIPC/debrickDebrick) to remove the lock. Installing OpenIPC was challenging because the WiFi drivers are not included by default—you must rebuild the firmware with WiFi enabled.

OpenIPC documentation is incomplete and not always logically ordered, so expect a learning curve.

---

## Restoring Stock Chinese Firmware (If Needed)

If you need to revert to the original firmware, run these commands **one line at a time** in the U-Boot console:  
```sh
setenv ipaddr 192.168.137.2
setenv serverip 192.168.137.1
setenv ethaddr 9a:5b:06:f5:cb:c6
saveenv
run uknor16m
run urnor16m
sf erase 0xD50000 0x2b0000
reset
```

---

## Customizing Firmware for WiFi Support

### Required modifications before building:

- The initial USB WiFi power-on script modification in `general/overlay/etc/wireless/usb` has been merged upstream (August 2024), but you still need to rebuild firmware to enable WiFi drivers.

- Add WiFi driver packages to the defconfig file `/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig` by enabling:  
  ```
  BR2_PACKAGE_ATBM60XX=y
  BR2_PACKAGE_ATBM60XX_MODEL_603X=y
  BR2_PACKAGE_ATBM60XX_INTERFACE_USB=y
  ```

- Update the WiFi network interface config file `general/overlay/etc/network/interfaces.d/wlan0` with:  
  ```
  iface wlan0 inet dhcp
      pre-up wpa_passphrase SSID WiFipassword > /tmp/wpa_supplicant.conf
      pre-up sed -i 's/#psk.*/scan_ssid=1/g' /tmp/wpa_supplicant.conf
      pre-up wpa_supplicant -B -i wlan0 -D nl80211,wext -c /tmp/wpa_supplicant.conf
      post-down killall -q wpa_supplicant
      post-down echo 1 > /sys/class/gpio/gpio7/value
      post-down echo 7 > /sys/class/gpio/unexport
  ```  
  > **Note:** Replace `SSID` and `WiFipassword` with your WiFi network’s SSID and password.

- Change the Ethernet fallback IP address in `general/overlay/etc/init.d/S40network` from `192.168.2.1` (outside my LAN subnet) to an unused IP within your subnet, e.g., `192.168.1.200`. This allows Ethernet access if WiFi fails.

- Set the WiFi device variable in the same `S40network` script:  
  ```sh
  dev=atbm603x-gk7205v300-xm-g6s
  ```  
  Without this, you'd have to manually set it in U-Boot:  
  ```sh
  fw_setenv wlandev atbm603x-gk7205v300-xm-g6s
  ```

- Optionally, use the `yaml-cli` utility to adjust sensor profiles and settings in `majestic.yaml`:  
  ```sh
  cli -s .isp.iqProfile /etc/sensors/iq/imx335.ini
  cli -s .isp.sensorConfig /etc/sensors/5M_imx335.ini
  cli -s .isp.drc 400
  cli -s .isp.slowShutter high
  cli -s .isp.exposure 100000
  cli -s .isp.aGain 16384
  cli -s .isp.dGain 2048
  cli -s .isp.ispGain 8192
  ```  
  Restart the streamer to apply:  
  ```sh
  killall -1 majestic
  ```

---

## Building the Customized Firmware

1. Open Ubuntu terminal.
2. Install required packages if missing:  
   ```sh
   sudo apt update
   sudo apt install git make
   ```
3. Clone your forked repository’s `wifi` branch:  
   ```sh
   git clone --branch wifi https://github.com/funkypozzy/firmware.git openipc-firmware
   cd openipc-firmware
   ```
4. Install build dependencies:  
   ```sh
   sudo make deps
   ```
5. **Before building**, edit `general/overlay/etc/network/interfaces.d/wlan0` to replace placeholders `SSID` and `WiFipassword` with your actual WiFi credentials.
6. Build the firmware:  
   ```sh
   make BOARD=gk7205v300_ultimate
   ```
7. On successful build, firmware images will be in `output/images` folder.

---

## First-Time Firmware Installation

1. Connect the camera’s UART pins and Ethernet cable to your PC.
2. Run PuTTY to open the serial console to the camera.
3. Start your TFTP server pointed at the `output/images` folder.
4. Power on the camera and **interrupt boot by pressing CTRL+C** to enter U-Boot console.
5. Set IP addresses:  
   ```sh
   setenv ipaddr 192.168.137.2
   setenv serverip 192.168.137.1
   ```
6. For NOR 16MB flash memory (write one partition at a time):  
   ```sh
   mw.b ${baseaddr} 0xff 0x300000
   tftp ${baseaddr} uImage.${soc}
   sf probe 0
   sf erase 0x50000 0x300000
   sf write ${baseaddr} 0x50000 ${filesize}

   mw.b ${baseaddr} 0xff 0x500000
   tftp ${baseaddr} rootfs.squashfs.${soc}
   sf probe 0
   sf erase 0x350000 0xa00000
   sf write ${baseaddr} 0x350000 ${filesize}
   ```
7. Disconnect Ethernet cable from the camera.
8. Reboot the camera:  
   ```sh
   reset
   ```
9. Wait for Linux to boot.  
   Default login:  
   - Username: `root`  
   - Password: `12345`  
10. Access the web interface at `http://<camera_ip>:85/` and set your own password.

Congratulations! You now have OpenIPC firmware with WiFi enabled.

---

## Updating Firmware Over WiFi

Once your camera is connected to WiFi, you can update firmware remotely without UART or Ethernet cable.

1. Copy firmware files to the camera:  
   ```sh
   cd output/images/
   scp uImage* rootfs* root@<camera_ip>:/tmp/
   ```
2. SSH into the camera and run:  
   ```sh
   soc=$(fw_printenv -n soc)
   sysupgrade --kernel=/tmp/uImage.${soc} --rootfs=/tmp/rootfs.squashfs.${soc} -z
   ```
   Add `-n` flag to reset overlays if needed. The camera will reboot automatically.
3. After reboot, connect via SSH and run (to reset all settings):  
   ```sh
   firstboot
   ```

**Note:** User credentials usually reset to default (`root/12345`) after upgrade.

---

## References and Resources

- [OpenIPC Firmware Repository](https://github.com/OpenIPC/firmware)
- [OpenIPC Telegram Channel](https://t.me/openipc)
- [Debrick Utility](https://github.com/OpenIPC/debrickDebrick)
- [Tftpd64 TFTP Server](https://pjo2.github.io/tftpd64/)
- [PuTTY SSH/Telnet Client](https://www.putty.org/)

---

*This guide is based on personal experience customizing OpenIPC firmware for the IVG G6S camera with IPC-38x38-WIFI-IF V1.02 WiFi/SD board (ATBM603x chipset). It aims to provide a clearer, step-by-step process for enthusiasts and developers wanting to enable WiFi on this platform.*
