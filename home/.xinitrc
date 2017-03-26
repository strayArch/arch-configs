# export environment variables
export ABS="${HOME}/abs"
export CHROOT="${HOME}/chroot"
export CHROOT32="${HOME}/chroot32"
export REPO="${HOME}/repo"
export XMODMAP="${HOME}/.xmodmap"
export XRESRC="${HOME}/.xresources"

# set X properties
[[ -f "${XRESRC}" ]] && xrdb -merge -I"${HOME}" "${XRESRC}"

# create directories if they don't already exist
prep_directories() { [[ ! -d "$1" ]] && mkdir "$1"; }
prep_directories "${ABS}"
prep_directories "${CHROOT}"
prep_directories "${CHROOT32}"
prep_directories "${REPO}"

# associate version with case statement patterns
declare -rA VERSION=(['ab41']="hhkb"
                     ['0111']="hhkb"
                     ['ab83']="chrm")
# assign variables with readonly property
declare -rA DEVICE=(['hhkb']="Topre Corporation HHKB Professional" 
                    ['chrm']="AT Translated Set 2 keyboard")
# xmodmap configuration functions
set_hhkb() { 
  cat > "${XMODMAP}" << EOF
keycode 102 = Super_L
keycode 100 = Super_R
keycode 119 = BackSpace
keycode 22  = Delete
EOF
}
set_chrm() { 
  cat > "${XMODMAP}" << EOF
keycode 133 = Super_L
keycode 68 = Next
keycode 67 = Prior
EOF
}
set_empty() { > "${XMODMAP}"; }

# keymap helper functions
pass() { return 0; }
get_checksum() { md5sum "${XMODMAP}" | awk '{ print $1 }'; }
get_file_hash() { [[ -f "$1" ]] && get_checksum; }
get_device_key() { 
  declare -r PROC_INPUT="/proc/bus/input/devices"
  for KEY in ${!DEVICE[@]}; do
    KVER=$(grep -B1 "${DEVICE[$KEY]}" "${PROC_INPUT}" | sed -n "s/^.*Version=\(.*\)$/\1/p")
    if [[ -n "${KVER}" ]] && [[ -n "${VERSION[$KVER]}" ]]; then
       echo "${VERSION[$KVER]}" 
       return 0
    fi
  done
  echo "empty"
}
# set configs if keyboard w/ preferred map is present
set_xmodmap() {
  case "$1" in
    hhkb)
      set_hhkb
      ;;
    chrm)
      set_chrm
      ;;
    empty)
      set_empty
      ;;
  esac
}
mykeymap() { 
  [[ ! -f "${XMODMAP}" ]] && set_empty
  HASH=$(get_file_hash "${XMODMAP}")
  DEVICE_KEY=$(get_device_key)
  [[ -z ${DEVICE_KEY} ]] && DEVICE_KEY="none"
  case "${HASH}" in
    5e25b643ad2513ea149dd872a40e114a) # HHKB
      [[ "${DEVICE_KEY}" == "hhkb" ]] && pass || set_xmodmap "${DEVICE_KEY}"
      ;;
    259872dbb21a931bc1412d641114e1ae) # CHRM
      [[ "${DEVICE_KEY}" == "chrm" ]] && pass || set_xmodmap "${DEVICE_KEY}"
      ;;
    d41d8cd98f00b204e9800998ecf8427e) # NONE
      [[ "${DEVICE_KEY}" == "empty" ]] && pass || set_xmodmap "${DEVICE_KEY}"
      ;; 
  esac
}
# map keys when necessary conditions are satisfied
mykeymap
#
autocutsel -fork &
autocutsel -selection PRIMARY -fork &
xmodmap "${XMODMAP}"
pulseaudio --start
xscreensaver -nosplash &
exec awesome
# vim: syntax=bash