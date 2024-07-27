## Customised OpenIPC firmware for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

I forked the OpenIPC repository and then I created this branch namend "wifi" (look at the web address, this is not the main repository, but a branch) to do my experiments.
![image](https://github.com/user-attachments/assets/226fbad1-3bf7-4fd5-a5b6-ad63b9eab8b4)

This branch, based on OpenIPC firmware, is specific board IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD module IPC-38x38-WIFI-IF V1.02 - ATBM603x (see following images for reference):

![02](https://github.com/user-attachments/assets/26a63724-caa8-4dd7-91f2-a11ff5306fbe)
![01](https://github.com/user-attachments/assets/023cc734-7e30-40a9-97f6-a4408ba3ab03)


## WHAT YOU NEED - HARDWARE
 - the ip camera with the additional wifi/SD board (buy on aliexpress), a 12V power supply and an ethernet cable.
 - an FTDI adapter for 3V3. My FTDI adapter has a mini-USB connection (not micro-USB!) so ensure that you also have the proper USB cable.
 - a clever hard-wired connection to the UART TX/RX pins and GND of the ip camera (e.g. see the following image):
![20240726_124051](https://github.com/user-attachments/assets/ac0ab764-4299-4e69-966c-97fbb0092130)
![Senza titolo](https://github.com/user-attachments/assets/35c97371-6608-45fc-ba23-1b52e78daeb6)
 - a computer (in my case an Hyper-V virtual machine running under Windows 11) with UBUNTU 22.04 to build the firmware.  FYI, I was not able to build the firmware with Raspbian running on rpi4 or rpi5.
 - a computer to run Putty, the TFTP server, connect the FTDI adapter. In my case it is a Windows 11 PC.
 - a LAN connection between the computer running the TFTP server and the ip camera to upload the new firmware. Since the camera is already wire connected to the computer via the FTDI adapter, for me the easiest way is to connect the computer directly to the ip camera with an ethernet cable, but you may decide to communicate between your computer and and the ip camera via a router. The ethernet cable is necessary since wifi is not yet activated.
   
## WHAT YOU NEED - SOFTWARE
- a TFTP software as for example [Tftpd64](https://pjo2.github.io/tftpd64/) (ensure firewall is not blocking the server)
- UBUNTU 22.04 to build the firmware (I was not able to build the firmware with a Raspbian running on rpi4 or rpi5)
- an SSH and telnet client [PuTTY](https://www.putty.org/)

## MY STORY FROM THE BEGINNING
I was looking for a cheap ip camera to monitor the car parking in front of my building. I searched for an image sensor suitable for low light conditions in order to discreetely see distant objects (up to 80 meters) without need of illumination (with infrared or visible light) during night.

Required features:
- a cheap ip camera
- no proprietary cloud service or proprietary app
- rtsp stream
- wifi connectivity
- suitable for (color) vision in low light conditions

I found these products:
- Hickvision Darkfighter (very expensive)
- Dahua Starlight (expensive)
- Arducam IMX462 STARVIS Camera Module (~40€, raspberry not included)
- a bare camera board GK7205V300 + 5MP IMX33 Sony Starvis sensor + wifi (33€ on Aliexpress). I salvaged a 12V power supply from an old router.

My choice was the GK7205V300 + IMX335. It was delivered with a stock firmware and a rich featured web interface, but I was completely disappointed when I realized that installing a browser plugin named "VideoPlayTool.exe" was mandatory. No chance to access the web interface via Android Chrome since plugin installation is not possible.

Hopefully the open source firmware OpenIPC was available for this board and the web interface doesn't require special plugins.


## FLASHING THE ORIGINAL FIRMWARE
Installing the OpenIPC firmware has been a more difficult process than expected mainly because the original firmware was password protected. Long story short... I was able to remove the lock with the [Debrick](https://github.com/OpenIPC/debrickDebrick) utility.
Installing wifi drivers and setup wifi connection was even more challenging and this is the reason because I decided to share my experience in this guide.

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

- modifies file [general/overlay/etc/network/interfaces.d/wlan0](general/overlay/etc/network/interfaces.d/wlan0) to (THIS IS A TEST - NOT FINALISED!):

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

- includes two sensor profiles with the Wide Dynamic range (WDR) enabled in the folder:
*5M_imx335.ini* and 
*imx335_i2c_4M.ini*
[/general/package/goke-osdrv-gk7205v200/files/sensor/config](/general/package/goke-osdrv-gk7205v200/files/sensor/config)

