#!/usr/bin/env bash

# check if udev rules for sigrok are installed, download and install if not present

declare -A udev_files_and_urls=(
  ["/etc/udev/rules.d/60-libsigrok.rules"]="https://raw.githubusercontent.com/sigrokproject/libsigrok/refs/heads/master/contrib/60-libsigrok.rules"
  ["/etc/udev/rules.d/61-libsigrok-plugdev.rules"]="https://raw.githubusercontent.com/sigrokproject/libsigrok/refs/heads/master/contrib/61-libsigrok-plugdev.rules"
  ["/etc/udev/rules.d/61-libsigrok-uaccess.rules"]="https://raw.githubusercontent.com/sigrokproject/libsigrok/refs/heads/master/contrib/61-libsigrok-uaccess.rules"
)

RELOAD_RULES_REQUIRED=false
echo "Checking udev rules..."
for file in "${!udev_files_and_urls[@]}"; do
  if [ ! -e "$file" ]; then
    echo "udev file does not exist: $file"
    echo -n "downloading from ${udev_files_and_urls[$file]}..."
    sudo wget -q -O "$file" "${udev_files_and_urls[$file]}"
    if [ $? -eq 0 ]; then
      RELOAD_RULES_REQUIRED=true
      echo "done."
    else
      echo "failed."
    fi
  fi
done

if [ "$RELOAD_RULES_REQUIRED" = true ]; then
  echo -n "Applying new udev rules..."
  sudo udevadm control --reload-rules
  sudo udevadm trigger
  echo "done."
else
  echo "done. Nothing to do."
fi

# check if firmware file is present and download if not
# Required as FX2 controller does not store the firmware but loads it every time it boots.
FW_FILE="fx2lafw-sigrok-fx2-8ch.fw"
FW_LOCATIONS=(
  "/usr/share/sigrok-firmware/"
  "$HOME/.local/share/sigrok-firmware/"
  "$HOME/.local/share/flatpak/exports/share/sigrok-firmware/"
  "/var/lib/flatpak/exports/share/sigrok-firmware/"
  "/usr/local/share/sigrok-firmware/"
  "/var/lib/snapd/desktop/sigrok-firmware/"
  )
FW_DEF_INSTALL="$HOME/.local/share/sigrok-firmware/"
FW_ARCHIVE="sigrok-firmware-fx2lafw-bin-0.1.7.tar.gz"
FW_ARCHIVE_URL="https://sigrok.org/download/binary/sigrok-firmware-fx2lafw/"

echo "Checking if firmware file is present"
FW_FOUND=false
for FW_LOCATION in ${FW_LOCATIONS[@]}; do
  if [ -e "${FW_LOCATION}$FW_FILE" ]; then
    FW_FOUND=true
  fi
done
if [ "$FW_FOUND" = true ]; then
  echo "Firmware found. Nothing to do."
else
  echo "Firmware not found. Downloading to $FW_DEF_INSTALL"
  pushd /tmp > /dev/null
  mkdir sigrok-fw
  cd sigrok-fw
  wget -q -O "$FW_ARCHIVE" "${FW_ARCHIVE_URL}${FW_ARCHIVE}"
  tar -xf "${FW_ARCHIVE}" --strip-components 1 
  if [ -e "$FW_FILE" ]; then
    cp "$FW_FILE" "$FW_DEF_INSTALL"
  else
    echo "Error getting firmware. Please download firmware and copy files manually to $FW_DEF_INSTALL."
  fi
  cd ..
  rm -R sigrok-fw
  popd >/dev/null
fi

