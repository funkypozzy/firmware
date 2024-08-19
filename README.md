## Customised OpenIPC firmware for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

I forked the OpenIPC repository and then I created branch named "wifi" to do my experiments.

![image](https://github.com/user-attachments/assets/226fbad1-3bf7-4fd5-a5b6-ad63b9eab8b4)

This branch, based on OpenIPC firmware, is mainly to enable the wifi connection at first boot, without need of additional manual input. The wifi/SD module is the IPC-38x38-WIFI-IF V1.02 - ATBM603x (see following images for reference) for my board IVG G6S (GK7205V300 + Sony IMX335).

![02](https://github.com/user-attachments/assets/26a63724-caa8-4dd7-91f2-a11ff5306fbe)
![01](https://github.com/user-attachments/assets/023cc734-7e30-40a9-97f6-a4408ba3ab03)


## WHAT YOU NEED - HARDWARE
 - the ip camera with the additional wifi/SD board (buy on aliexpress), a 12V power supply and an ethernet cable.
 - an FTDI adapter for 3V3. My FTDI adapter has a mini-USB connection (not micro-USB!) so ensure that you also have the proper USB cable.
 - a clever hard-wired connection to the UART TX/RX pins and GND of the ip camera (e.g. see the following image):
![20240726_124051](https://github.com/user-attachments/assets/ac0ab764-4299-4e69-966c-97fbb0092130)
![Senza titolo](https://github.com/user-attachments/assets/35c97371-6608-45fc-ba23-1b52e78daeb6)
 - a computer (in my case an Hyper-V virtual machine running under Windows 11) with UBUNTU 22.04 to build the firmware.  FYI, I was not able to build the firmware with Raspbian running on rpi4 or rpi5.
 - a computer to run Putty, the TFTP server and connect the FTDI adapter via usb. In my case it is a Windows 11 PC.
 - a LAN connection between the computer running the TFTP server and the ip camera in order to upload the new firmware. Since the camera is already wire connected to the computer via the FTDI adapter, for me the easiest way is to connect also the computer directly to the ip camera with an ethernet cable, but you may decide to communicate between your computer and and the ip camera via a router. The ethernet cable is necessary since wifi is not yet activated before uploading the customized firmware.
   
## WHAT YOU NEED - SOFTWARE
- a TFTP software as for example [Tftpd64](https://pjo2.github.io/tftpd64/) (ensure firewall is not blocking the server)

  ![image](https://github.com/user-attachments/assets/f0898e11-57f6-47f5-b634-25aad02b4c9f)
- UBUNTU 22.04 to build the firmware (I was not able to build the firmware with a Raspbian running on rpi4 or rpi5)
- an SSH and telnet client [PuTTY](https://www.putty.org/)
  ![image](https://github.com/user-attachments/assets/1998ea98-33e3-4eb8-b1b7-8c46bc77c10f)


## MY STORY FROM THE BEGINNING
I was looking for a cheap ip camera to monitor the car parking in front of my building. I searched for an image sensor suitable for low light conditions in order to discreetely see distant objects (up to 80 meters) without need of illumination (no infrared or white light) during night.

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

My choice was the GK7205V300 + IMX335. It was delivered with a chinese looking stock firmware and a rich featured web interface, but I was completely disappointed when I realized that installing a browser plugin named "VideoPlayTool.exe" was mandatory. No chance to access the web interface via Android Chrome since plugin installation is not possible.

Hopefully the open source firmware OpenIPC was available for this board.


## FLASHING THE ORIGINAL FIRMWARE
Installing the OpenIPC firmware has been a more difficult process than expected mainly because the original firmware was password protected. Long story short... I was able to remove the lock with the [Debrick](https://github.com/OpenIPC/debrickDebrick) utility.
Installing wifi drivers and setup the wifi connection was even more challenging and this is the reason because I decided to share my experience in this guide.
OpenIPC website instructions look straightforward, but they are incompleted. OpenIPC github repository together with telegram channel are the main resources, but also here topics are not presented in a logical order so you need some days/weeks (depending on your skills) to figure out how the system works and where to look. For example, the forst time I was able to install the OpenIPC firmware and access the web ui, I immediatly search for a button to activate the wifi, but then I realise that there are many other steps to be done before at code level ...

## CUSTOMIZED FILES

In particular this branch:
- modifies the file [general/overlay/etc/wireless/usb](general/overlay/etc/wireless/usb)  to include the required instruction to power on the wifi board based on the ATBM603x wifi chip (see images above). In particular the following lines have been added:
~~~ # GK7205V300 XM IVG-G6S
if [ "$1" = "atbm603x-gk7205v300-xm-g6s" ]; then
  devmem 0x100C0080 32 0x530
  set_gpio 7 0
  modprobe atbm603x_wifi_usb
  exit 0
fi
~~~
Since August 2024, this modification has been merged to the master repository of OpenIPC.
- modifies the wifi secion in the file [/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig](/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig) to include drivers for generic ATBM603x wifi chip. After file modification, it is necessary to re-build the firmware:
~~~ 
BR2_PACKAGE_ATBM60XX=y
BR2_PACKAGE_ATBM60XX_MODEL_603X=y
BR2_PACKAGE_ATBM60XX_INTERFACE_USB=y
~~~
Wifi drivers are not included by default in OpenIPC firmware.
- modifies file [general/overlay/etc/network/interfaces.d/wlan0](general/overlay/etc/network/interfaces.d/wlan0) to include specific instruction to power on/off the wifi board:

~~~
see file
~~~
Note: SSID and Wifipassword are placeholder to be modified with your actual SSID and password.

- modifies the ethernet ip address in file [/general/overlay/etc/init.d/S40network](/general/overlay/etc/init.d/S40network) from 192.168.2.1 (which is outside my subnet ip range) to 192.168.1.20 which is inside my subnet range and not in conflict with other devices connected to my LAN.

- a fixed value is assigned to the variable *dev* (i.e. dev=atbm603x-gk7205v300-xm-g6s) in file [/general/overlay/etc/init.d/S40network](/general/overlay/etc/init.d/S40network) Without this modification you should manually assign a value to the U-boot variable with command fw_setenv wlandev = atbm603x-gk7205v300-xm-g6s .

- modifies the majestic.yaml file to activate sensor profiles specific for 5 mega pixel resolution and Wide Dynamic range (WDR):

~~~
cli -s .isp.lowDelay true
cli -s .isp.iqProfile /etc/sensors/iq/imx335.ini
cli -s .isp.sensorConfig /etc/sensors/5M_imx335.ini

killall majestic
sleep 3
majestic
~~~

