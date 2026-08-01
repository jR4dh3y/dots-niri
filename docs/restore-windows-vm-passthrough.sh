#!/usr/bin/env bash
#
# Rebuild the host side of the former win10-rtx3050 VFIO/Looking Glass setup.
#
# This script DOES NOT recreate the deleted Windows qcow2, NVRAM, TPM state,
# Windows installation, or Looking Glass Host configuration inside Windows.
# Read windows-vm-passthrough-looking-glass.md before applying it.
#
# Safe default: without --apply this script performs validation and prints what
# it would do. It never contains or stores a sudo password.

set -euo pipefail
IFS=$'\n\t'

VM_NAME="win10-rtx3050"
GPU_PCI="0000:01:00.0"
GPU_ID="10de:25a2"
AUDIO_PCI="0000:01:00.1"
AUDIO_ID="10de:2291"
USB_CONTROLLER_PCI="0000:06:00.4"
SHM_USER="radhey"
SHM_GROUP="kvm"
SHM_SIZE_MIB="256"
VM_MAC="52:54:00:1a:cd:bd"
VM_IP="192.168.122.50"
VM_NETWORK="192.168.122.0/24"
VM_GATEWAY="192.168.122.1"
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

APPLY=0
CONFIGURE_BOOT=0
VM_XML=""
OUTBOUND_INTERFACE=""
TEMP_DIR=""

msg() {
	printf '==> %s\n' "$*"
}

warn() {
	printf 'WARNING: %s\n' "$*" >&2
}

die() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage:
  restore-windows-vm-passthrough.sh [options]

Options:
  --apply                 Make changes. Without this, only validate and preview.
  --configure-boot        Add AMD IOMMU/VFIO flags to systemd-boot entries.
  --vm-xml PATH           Define a previously exported inactive libvirt XML.
  --outbound-interface IF Interface used for libvirt NAT, e.g. wlan0.
  -h, --help              Show this help.

Examples:
  ./docs/restore-windows-vm-passthrough.sh
  ./docs/restore-windows-vm-passthrough.sh --apply --configure-boot
  ./docs/restore-windows-vm-passthrough.sh --apply \
    --vm-xml /path/to/win10-rtx3050.xml --outbound-interface wlan0

The exact former setup is documented in:
  docs/windows-vm-passthrough-looking-glass.md
EOF
}

cleanup() {
	if [[ -n ${TEMP_DIR:-} && -d $TEMP_DIR ]]; then
		rm -r -- "$TEMP_DIR"
	fi
}

trap cleanup EXIT

while (($#)); do
	case "$1" in
		--apply)
			APPLY=1
			shift
			;;
		--configure-boot)
			CONFIGURE_BOOT=1
			shift
			;;
		--vm-xml)
			[[ $# -ge 2 ]] || die "--vm-xml requires a path"
			VM_XML=$2
			shift 2
			;;
		--outbound-interface)
			[[ $# -ge 2 ]] || die "--outbound-interface requires a name"
			OUTBOUND_INTERFACE=$2
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown option: $1"
			;;
	esac
done

require_command() {
	command -v "$1" >/dev/null 2>&1 || die "required command is missing: $1"
}

pci_id() {
	local device=$1
	local vendor product

	[[ -r /sys/bus/pci/devices/$device/vendor ]] ||
		die "PCI device is missing: $device"
	[[ -r /sys/bus/pci/devices/$device/device ]] ||
		die "PCI device ID is unreadable: $device"

	vendor=$(<"/sys/bus/pci/devices/$device/vendor")
	product=$(<"/sys/bus/pci/devices/$device/device")
	printf '%s:%s\n' "${vendor#0x}" "${product#0x}"
}

iommu_group() {
	local device=$1
	local link="/sys/bus/pci/devices/$device/iommu_group"

	[[ -L $link ]] || die "$device has no IOMMU group"
	basename "$(readlink -f "$link")"
}

validate_hardware() {
	local actual_gpu actual_audio gpu_group audio_group

	actual_gpu=$(pci_id "$GPU_PCI")
	actual_audio=$(pci_id "$AUDIO_PCI")
	[[ $actual_gpu == "$GPU_ID" ]] ||
		die "$GPU_PCI is $actual_gpu, expected $GPU_ID"
	[[ $actual_audio == "$AUDIO_ID" ]] ||
		die "$AUDIO_PCI is $actual_audio, expected $AUDIO_ID"

	gpu_group=$(iommu_group "$GPU_PCI")
	audio_group=$(iommu_group "$AUDIO_PCI")
	[[ $gpu_group == "$audio_group" ]] ||
		die "GPU and audio are no longer in the same IOMMU group"

	msg "RTX GPU and audio IDs match the former setup"
	msg "GPU/audio IOMMU group: $gpu_group"

	if [[ -d /sys/bus/pci/devices/$USB_CONTROLLER_PCI ]]; then
		msg "Optional USB controller group: $(iommu_group "$USB_CONTROLLER_PCI")"
	else
		warn "optional USB controller $USB_CONTROLLER_PCI is missing"
	fi

	if command -v bootctl >/dev/null 2>&1; then
		bootctl status 2>/dev/null |
			grep -E 'Firmware:|Secure Boot:|TPM2 Support:' || true
	fi
}

preview() {
	cat <<EOF

This will restore:
  - VFIO default binding for $GPU_PCI and $AUDIO_PCI
  - dynamic gpu-to-vfio / gpu-to-nvidia helpers
  - NVIDIA no-seat rule while dynamically rebound
  - libvirt modular sockets and default NAT network
  - DHCP reservation $VM_IP for $VM_MAC
  - Looking Glass shared memory: ${SHM_SIZE_MIB} MiB in the VM XML,
    with /dev/shm/looking-glass owned by $SHM_USER:$SHM_GROUP
  - the qcow2/NBD exclusivity hook

It will not restore:
  - the deleted Windows qcow2
  - OVMF NVRAM or virtual TPM state
  - Windows, GPU drivers, IVSHMEM driver, or Looking Glass Host in the guest
  - the old Waybar VM button
EOF

	if [[ $CONFIGURE_BOOT -eq 1 ]]; then
		printf '%s\n' \
			"  - systemd-boot entries WILL receive AMD IOMMU and VFIO flags"
	else
		printf '%s\n' \
			"  - systemd-boot entries will not be edited (no --configure-boot)"
	fi

	if [[ -n $VM_XML ]]; then
		printf '  - libvirt XML to define: %s\n' "$VM_XML"
	fi
}

write_payloads() {
	TEMP_DIR=$(mktemp -d)

	cat >"$TEMP_DIR/vfio.conf" <<EOF
# Bind the RTX GPU and its HDMI audio function to VFIO by default.
options vfio-pci ids=$GPU_ID,$AUDIO_ID disable_vga=1
softdep snd_hda_intel pre: vfio-pci
EOF

	cat >"$TEMP_DIR/nvidia-vfio-blacklist.conf" <<'EOF'
# NVIDIA is loaded explicitly by gpu-to-nvidia when PRIME mode is requested.
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
EOF

	cat >"$TEMP_DIR/90-nvidia-no-seat.rules" <<EOF
# Keep the dynamically rebound NVIDIA DRM card away from the desktop seat.
ACTION!="remove", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-${GPU_PCI}", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess"
EOF

	cat >"$TEMP_DIR/looking-glass.conf" <<EOF
f /dev/shm/looking-glass 0660 $SHM_USER $SHM_GROUP -
EOF

	cat >"$TEMP_DIR/gpu-status" <<EOF
#!/usr/bin/env bash
set -euo pipefail
GPU="$GPU_PCI"
AUDIO="$AUDIO_PCI"
VM="$VM_NAME"
driver_for() {
  if [[ -L "/sys/bus/pci/devices/\$1/driver" ]]; then
    basename "\$(readlink -f "/sys/bus/pci/devices/\$1/driver")"
  else
    echo none
  fi
}
echo "GPU driver:   \$(driver_for "\$GPU")"
echo "Audio driver: \$(driver_for "\$AUDIO")"
if command -v virsh >/dev/null 2>&1; then
  state=\$(virsh -c qemu:///system domstate "\$VM" 2>/dev/null || true)
  [[ -n \$state ]] && echo "VM state:     \$state"
fi
lspci -nnk -s "\${GPU#0000:}"
lspci -nnk -s "\${AUDIO#0000:}"
EOF

	cat >"$TEMP_DIR/gpu-to-vfio" <<EOF
#!/usr/bin/env bash
set -euo pipefail
GPU="$GPU_PCI"
AUDIO="$AUDIO_PCI"
VM="$VM_NAME"
LOCK="/run/lock/gpu-switch.lock"
driver_for() {
  if [[ -L "/sys/bus/pci/devices/\$1/driver" ]]; then
    basename "\$(readlink -f "/sys/bus/pci/devices/\$1/driver")"
  else
    echo none
  fi
}
unbind() {
  [[ -L "/sys/bus/pci/devices/\$1/driver" ]] &&
    echo "\$1" >"/sys/bus/pci/devices/\$1/driver/unbind"
}
bind_vfio() {
  modprobe vfio_pci
  echo vfio-pci >"/sys/bus/pci/devices/\$1/driver_override"
  if [[ \$(driver_for "\$1") != vfio-pci ]]; then
    unbind "\$1"
    echo "\$1" >/sys/bus/pci/drivers_probe || true
  fi
  [[ \$(driver_for "\$1") == vfio-pci ]] ||
    echo "\$1" > /sys/bus/pci/drivers/vfio-pci/bind
  [[ \$(driver_for "\$1") == vfio-pci ]] ||
    { echo "Failed to bind \$1 to vfio-pci" >&2; exit 1; }
}
[[ \${EUID:-\$(id -u)} -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
exec 9>"\$LOCK"
flock -n 9 || { echo "Another GPU switch is running." >&2; exit 1; }
state=\$(virsh -c qemu:///system domstate "\$VM" 2>/dev/null || true)
[[ \$state != running && \$state != paused ]] ||
  { echo "\$VM is already \$state." >&2; exit 0; }
systemctl stop nvidia-persistenced.service nvidia-powerd.service 2>/dev/null || true
if compgen -G "/dev/nvidia*" >/dev/null && fuser /dev/nvidia* >/dev/null 2>&1; then
  fuser -v /dev/nvidia* >&2 || true
  echo "NVIDIA is still in use." >&2
  exit 1
fi
bind_vfio "\$AUDIO"
bind_vfio "\$GPU"
for module in nvidia_drm nvidia_uvm nvidia_modeset nvidia; do
  modprobe -r "\$module" 2>/dev/null || true
done
udevadm settle --timeout=10 || true
echo "Switched RTX GPU and audio to VFIO."
EOF

	cat >"$TEMP_DIR/gpu-to-nvidia" <<EOF
#!/usr/bin/env bash
set -euo pipefail
GPU="$GPU_PCI"
AUDIO="$AUDIO_PCI"
VM="$VM_NAME"
LOCK="/run/lock/gpu-switch.lock"
driver_for() {
  if [[ -L "/sys/bus/pci/devices/\$1/driver" ]]; then
    basename "\$(readlink -f "/sys/bus/pci/devices/\$1/driver")"
  else
    echo none
  fi
}
unbind() {
  [[ -L "/sys/bus/pci/devices/\$1/driver" ]] &&
    echo "\$1" >"/sys/bus/pci/devices/\$1/driver/unbind"
}
enable_device() {
  echo on >"/sys/bus/pci/devices/\$1/power/control" 2>/dev/null || true
  echo 1 >"/sys/bus/pci/devices/\$1/enable" 2>/dev/null || true
}
[[ \${EUID:-\$(id -u)} -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }
exec 9>"\$LOCK"
flock -n 9 || { echo "Another GPU switch is running." >&2; exit 1; }
state=\$(virsh -c qemu:///system domstate "\$VM" 2>/dev/null || true)
[[ \$state != running && \$state != paused ]] ||
  { echo "Shut down \$VM before rebinding NVIDIA." >&2; exit 1; }
if [[ \$(driver_for "\$GPU") == vfio-pci && -w /sys/bus/pci/devices/\$GPU/reset ]]; then
  echo 1 >"/sys/bus/pci/devices/\$GPU/reset" || true
fi
echo nvidia >"/sys/bus/pci/devices/\$GPU/driver_override"
unbind "\$GPU"
enable_device "\$GPU"
modprobe nvidia
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia_drm
echo "\$GPU" >/sys/bus/pci/drivers_probe || true
[[ \$(driver_for "\$GPU") == nvidia ]] ||
  echo "\$GPU" >/sys/bus/pci/drivers/nvidia/bind
echo snd_hda_intel >"/sys/bus/pci/devices/\$AUDIO/driver_override"
unbind "\$AUDIO"
enable_device "\$AUDIO"
modprobe snd_hda_intel
echo "\$AUDIO" >/sys/bus/pci/drivers_probe || true
[[ \$(driver_for "\$AUDIO") == snd_hda_intel ]] ||
  echo "\$AUDIO" >/sys/bus/pci/drivers/snd_hda_intel/bind
udevadm settle --timeout=10 || true
systemctl start nvidia-powerd.service 2>/dev/null || true
echo "Switched RTX GPU and audio to Linux NVIDIA PRIME."
EOF

	cat >"$TEMP_DIR/qemu-hook" <<'EOF'
#!/usr/bin/env bash
# Keep the guest qcow2 exclusive: detach host NBD before VM start.
set -euo pipefail
VM="${1:-}"
OP="${2:-}"
PHASE="${3:-}"
[[ "$VM" == "win10-rtx3050" ]] || exit 0
case "$OP:$PHASE" in
  prepare:begin|release:end|prepare:|release:) ;;
  *) exit 0 ;;
esac
NBD=/dev/nbd0
PART=/dev/nbd0p3
QCOW=/var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
connected() { [[ -s /sys/class/block/nbd0/pid ]]; }
if [[ $OP == prepare ]]; then
  while IFS= read -r target; do
    [[ -n $target ]] && umount "$target"
  done < <(findmnt -rn -S "$PART" -o TARGET 2>/dev/null || true)
  connected && qemu-nbd --disconnect "$NBD"
elif [[ -f $QCOW ]]; then
  modprobe nbd max_part=16
  connected || qemu-nbd --cache=none --connect="$NBD" "$QCOW"
  blockdev --rereadpt "$NBD" || true
  udevadm settle --timeout=10 || true
fi
EOF

	cat >"$TEMP_DIR/default-network.xml" <<EOF
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='$VM_GATEWAY' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
      <host mac='$VM_MAC' name='$VM_NAME' ip='$VM_IP'/>
    </dhcp>
  </ip>
</network>
EOF
}

install_packages() {
	local -a packages=(
		qemu-desktop
		libvirt
		virt-manager
		virt-viewer
		edk2-ovmf
		swtpm
		dnsmasq
		iptables-nft
		looking-glass
		spice-gtk
		usbredir
		virtio-win
		nvidia-open-dkms
		nvidia-utils
		nvidia-prime
	)

	require_command paru
	msg "Installing current virtualization, Looking Glass, and NVIDIA packages"
	paru -S --needed "${packages[@]}"
}

install_host_files() {
	sudo install -Dm644 "$TEMP_DIR/vfio.conf" /etc/modprobe.d/vfio.conf
	sudo install -Dm644 "$TEMP_DIR/nvidia-vfio-blacklist.conf" \
		/etc/modprobe.d/nvidia-vfio-blacklist.conf
	sudo install -Dm644 "$TEMP_DIR/90-nvidia-no-seat.rules" \
		/etc/udev/rules.d/90-nvidia-no-seat.rules
	sudo install -Dm644 "$TEMP_DIR/looking-glass.conf" \
		/etc/tmpfiles.d/looking-glass.conf
	sudo install -Dm755 "$TEMP_DIR/gpu-status" /usr/local/sbin/gpu-status
	sudo install -Dm755 "$TEMP_DIR/gpu-to-vfio" /usr/local/sbin/gpu-to-vfio
	sudo install -Dm755 "$TEMP_DIR/gpu-to-nvidia" \
		/usr/local/sbin/gpu-to-nvidia
	sudo install -Dm755 "$TEMP_DIR/qemu-hook" /etc/libvirt/hooks/qemu

	if [[ -f $REPO_DIR/install/nvidia/modprobe/nvidia.conf ]]; then
		sudo install -Dm644 "$REPO_DIR/install/nvidia/modprobe/nvidia.conf" \
			/etc/modprobe.d/nvidia.conf
	fi

	sudo systemd-tmpfiles --create /etc/tmpfiles.d/looking-glass.conf
	sudo udevadm control --reload-rules
}

configure_boot() {
	local entry
	local flags="amd_iommu=on iommu=pt vfio-pci.ids=$GPU_ID,$AUDIO_ID"

	[[ -d /boot/loader/entries ]] ||
		die "--configure-boot currently supports systemd-boot entries only"

	while IFS= read -r entry; do
		if sudo grep -q 'vfio-pci\.ids=' "$entry"; then
			msg "VFIO flags already exist in $entry"
			continue
		fi
		sudo sed -i -E "/^options / s|\$| $flags|" "$entry"
		msg "Added VFIO flags to $entry"
	done < <(sudo find /boot/loader/entries -maxdepth 1 -type f \
		-name '*.conf' -print)
}

enable_libvirt() {
	local -a sockets=(
		virtqemud.socket
		virtqemud-ro.socket
		virtqemud-admin.socket
		virtnetworkd.socket
		virtnetworkd-ro.socket
		virtnetworkd-admin.socket
		virtstoraged.socket
		virtstoraged-ro.socket
		virtstoraged-admin.socket
		virtnodedevd.socket
		virtnodedevd-ro.socket
		virtnodedevd-admin.socket
	)

	sudo systemctl enable --now "${sockets[@]}"
	sudo usermod -aG libvirt,kvm "$SHM_USER"

	if ! sudo virsh -c qemu:///system net-info default >/dev/null 2>&1; then
		sudo virsh -c qemu:///system net-define "$TEMP_DIR/default-network.xml"
	fi
	sudo virsh -c qemu:///system net-autostart default
	if ! sudo virsh -c qemu:///system net-info default |
		grep -q 'Active:.*yes'; then
		sudo virsh -c qemu:///system net-start default
	fi
}

configure_firewall() {
	command -v ufw >/dev/null 2>&1 || {
		warn "ufw is not installed; skipping libvirt firewall rules"
		return
	}

	sudo ufw allow in on virbr0 from "$VM_NETWORK" \
		to "$VM_GATEWAY" proto udp port 53
	sudo ufw allow in on virbr0 from "$VM_NETWORK" \
		to "$VM_GATEWAY" proto tcp port 53
	sudo ufw allow in on virbr0 proto udp to any port 67

	if [[ -n $OUTBOUND_INTERFACE ]]; then
		ip link show "$OUTBOUND_INTERFACE" >/dev/null 2>&1 ||
			die "outbound interface does not exist: $OUTBOUND_INTERFACE"
		sudo ufw route allow in on virbr0 out on "$OUTBOUND_INTERFACE" \
			from "$VM_NETWORK" comment 'libvirt NAT VM egress'
	else
		warn "no --outbound-interface supplied; NAT forwarding rule was skipped"
	fi
}

define_vm() {
	[[ -n $VM_XML ]] || return 0
	[[ -f $VM_XML ]] || die "VM XML does not exist: $VM_XML"

	if sudo virsh -c qemu:///system dominfo "$VM_NAME" >/dev/null 2>&1; then
		die "$VM_NAME is already defined; refusing to replace it"
	fi

	sudo virsh -c qemu:///system define "$VM_XML"
	sudo virsh -c qemu:///system autostart --disable "$VM_NAME"
}

validate_result() {
	printf '\n'
	msg "Host-side restore complete; checking configuration"
	sudo /usr/local/sbin/gpu-status || true
	sudo virsh -c qemu:///system net-info default
	stat /dev/shm/looking-glass
	printf '\n'
	warn "Reboot before assigning the RTX to a VM."
	warn "After reboot, verify both NVIDIA functions use vfio-pci."
	warn "Log out/in so the libvirt group membership takes effect."
	warn "The VM XML still needs a valid qcow2, NVRAM, and TPM state."
	warn "Use the recovery Markdown for the 256 MiB IVSHMEM and guest setup."
}

main() {
	require_command lspci
	require_command readlink
	validate_hardware
	preview

	if [[ $APPLY -ne 1 ]]; then
		printf '\nDry run only. Re-run with --apply to make changes.\n'
		exit 0
	fi

	printf '\nType RESTORE-PASSTHROUGH to continue: '
	read -r confirmation
	[[ $confirmation == RESTORE-PASSTHROUGH ]] ||
		die "confirmation did not match"

	sudo -v
	write_payloads
	install_packages
	install_host_files
	if [[ $CONFIGURE_BOOT -eq 1 ]]; then
		configure_boot
	fi
	enable_libvirt
	configure_firewall
	define_vm
	sudo mkinitcpio -P
	validate_result
}

main "$@"
