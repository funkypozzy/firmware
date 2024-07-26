![OpenIPC Logo](https://cdn.themactep.com/images/logo_openipc.png)

## OPENIPC for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

This branch is specific for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

![01](https://github.com/user-attachments/assets/023cc734-7e30-40a9-97f6-a4408ba3ab03)
![02](https://github.com/user-attachments/assets/26a63724-caa8-4dd7-91f2-a11ff5306fbe)

## THESE ARE STILL EXPERIMENTAL SETTINGS FOR MY PERSONAL USE!

In particular this branch:
- modifies the file [general/overlay/etc/wireless/usb](general/overlay/etc/wireless/usb)  to include the required instruction to power on my wifi board based on the ATBM603x wifi chip (see images above). In particular the following lines have been added:
~~~ # GK7205V300 XM IVG-G6S
if [ "$1" = "atbm603x-gk7205v300-xm-g6s" ]; then
  devmem 0x100C0080 32 0x530
  set_gpio 7 0
  modprobe atbm603x_wifi_usb
  exit 0
fi
~~~ 
- modifies the wifi secion in the file [/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig](/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig) to include drivers for generic ATBM603x wifi chip (it is necessary to re-build the firmware):
~~~ 
BR2_PACKAGE_ATBM60XX=y
BR2_PACKAGE_ATBM60XX_MODEL_603X=y
BR2_PACKAGE_ATBM60XX_INTERFACE_USB=y
~~~

- modifies file [/overlay/etc/network/interfaces.d/wlan0](/overlay/etc/network/interfaces.d/wlan0) to (THIS IS A TEST - NOT FINALISED!):

~~~
iface wlan0 inet dhcp
    pre-up wpa_passphrase SSID WiFipassword > /tmp/wpa_supplicant.conf
    pre-up sed -i 's/#psk.*/scan_ssid=1/g' /tmp/wpa_supplicant.conf
    pre-up wpa_supplicant -B -i wlan0 -D nl80211,wext -c /tmp/wpa_supplicant.conf
    post-down killall -q wpa_supplicant
    post-down echo 1 > /sys/class/gpio/gpio7/value
    post-down echo 7 > /sys/class/gpio/unexport
~~~

- modifies the ethernet ip address in file [/general/overlay/etc/init.d/S40network](/general/overlay/etc/init.d/S40network) from 192.168.2.1 (which is outside my subnet ip range) to 192.168.1.20 which is inside my subnet range and not in conflict with other devices connected to my LAN.

- a fixed value is assigned to the variable *dev* (i.e. dev=atbm603x-gk7205v300-xm-g6s) in file [/general/overlay/etc/init.d/S40network](/general/overlay/etc/init.d/S40network) to avoid to assign a value to the U-boot variable.

- includes two sensor profiles with Wide Dynamic range (WDR) enabled in the folder:
*general/package/goke-osdrv-gk7205v200/files/sensor/config/5M_imx335.ini
general/package/goke-osdrv-gk7205v200/files/sensor/config/imx335_i2c_4M.ini*

