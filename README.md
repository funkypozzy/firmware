![OpenIPC Logo](https://cdn.themactep.com/images/logo_openipc.png)

## OPENIPC for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

This fork is specific for IVG G6S (GK7205V300 + Sony IMX335) with the wifi/SD board IPC-38x38-WIFI-IF V1.02 - ATBM603x

In particular this fork will:
- modify the file **general/overlay/etc/wireless/usb** to include the required instruction to power on the wifi board based on the ATBM603x wifi chip. In particular the following lines have been added:
~~~ # GK7205V300 XM IVG-G6S
if [ "$1" = "atbm603x-gk7205v300-xm-g6s" ]; then
  devmem 0x100C0080 32 0x530
  set_gpio 7 0
	modprobe atbm603x_wifi_usb
	exit 0
fi
~~~ 
- modify the file "/br-ext-chip-goke/configs/gk7205v300_ultimate_defconfig" to add in the wifi section the following lines to add the necessary drivers for the specific wifi board:
~~~ 
BR2_PACKAGE_ATBM60XX=y
BR2_PACKAGE_ATBM60XX_MODEL_603X=y
BR2_PACKAGE_ATBM60XX_INTERFACE_USB=y
~~~


![01](https://github.com/user-attachments/assets/023cc734-7e30-40a9-97f6-a4408ba3ab03)
![02](https://github.com/user-attachments/assets/26a63724-caa8-4dd7-91f2-a11ff5306fbe)
