# Windows VM, RTX 3050 passthrough, and Looking Glass recovery runbook

This document records the working `win10-rtx3050` virtual-machine setup as it
existed on **2026-07-30**. It is intended to make the setup reproducible after
switching the laptop to a native Windows dual-boot installation.

The live VM and passthrough configuration were removed later on 2026-07-30.
Use `docs/restore-windows-vm-passthrough.sh` for a guarded host-side rebuild,
and use this document for the complete VM and guest-side details.

The live machine and live libvirt definition were inspected while writing this
document. Where older notes disagree with the values below, the live state in
this document is authoritative.

## Critical limitation: configuration is not a VM backup

This document can recreate the libvirt, VFIO, networking, and Looking Glass
configuration. It cannot recreate the installed Windows system or its data.

Before deleting the VM or repartitioning the Btrfs disk, preserve all four of
these items on storage that will survive the repartition:

```bash
sudo virsh -c qemu:///system dumpxml --inactive win10-rtx3050 \
  > win10-rtx3050.xml

sudo cp --sparse=always \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2 \
  /path/on/backup/storage/

sudo cp \
  /var/lib/libvirt/qemu/nvram/win10-rtx3050_VARS.fd \
  /path/on/backup/storage/

sudo cp -a \
  /var/lib/libvirt/swtpm/a3bde51b-fb5e-460a-ad43-8e27cd7ef322 \
  /path/on/backup/storage/
```

The qcow2 reports a 1,000 GiB virtual capacity but is sparse. At the time of
inspection:

```text
Virtual size:       1,073,741,824,000 bytes (1,000 GiB)
Apparent file size:   198,734,512,128 bytes (about 185 GiB)
Allocated disk use:   about 81.6 GiB
Cluster size:         2 MiB
```

Preserve sparseness when copying it. A destination filesystem must also support
sparse files. `qemu-img convert` is another safe option:

```bash
sudo qemu-img convert -p -f qcow2 -O qcow2 \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2 \
  /path/on/backup/storage/win10-rtx3050.qcow2
```

Verify any backup before destroying the original:

```bash
qemu-img info /path/on/backup/storage/win10-rtx3050.qcow2
sudo qemu-img check /path/on/backup/storage/win10-rtx3050.qcow2
```

If the intention is only to recreate a fresh passthrough VM later, rather than
recover this installed guest, the qcow2, NVRAM, and TPM state do not need to be
saved.

## Architecture at a glance

The Linux desktop stays on the AMD integrated GPU. The NVIDIA RTX 3050 Mobile
normally boots bound to `vfio-pci`, and can be moved dynamically between VFIO
and the NVIDIA Linux driver.

```text
AMD Cezanne iGPU (06:00.0)
  └─ amdgpu
     └─ Niri desktop, always

RTX 3050 Mobile (01:00.0) + HDMI audio (01:00.1)
  ├─ vfio-pci
  │  └─ win10-rtx3050
  │     ├─ RTX graphics and audio
  │     ├─ AMD USB controller 06:00.4
  │     ├─ optional RTL9210 USB device
  │     ├─ IVSHMEM framebuffer
  │     └─ SPICE input, clipboard, and fallback display
  └─ nvidia + snd_hda_intel
     └─ Linux PRIME offload while the VM is shut down
```

Looking Glass transfers the Windows framebuffer through IVSHMEM. SPICE remains
enabled on localhost for keyboard, mouse, and clipboard. QXL remains installed
as a recovery/fallback display.

## Host snapshot

```text
Hostname:            pico-cachyos
Distribution:        CachyOS / Arch Linux
CPU:                 AMD Ryzen 5 5600H
Host CPU topology:   6 cores, 12 threads
Host RAM:            approximately 15 GiB usable
Virtualization:      AMD-V
Boot loader:         systemd-boot
Firmware mode:       UEFI
Secure Boot:         disabled
Firmware TPM 2.0:    available
Linux root:          Btrfs, UUID 01adc9f3-9bbd-4c98-920a-f827823c8ab6
EFI system partition:/dev/nvme0n1p1, FAT32, 2 GiB, mounted at /boot
```

The currently booted kernel during the snapshot was:

```text
linux-cachyos-bore-lto 7.1.5-1
```

Version numbers will naturally change. They are recorded to distinguish the
known working environment, not as versions that must be permanently pinned.

### PCI devices and IOMMU groups

Host display GPU:

```text
06:00.0 AMD Cezanne integrated GPU
Vendor/device ID: 1002:1638
Driver: amdgpu
Render node used by Niri: /dev/dri/by-path/pci-0000:06:00.0-render
```

Passthrough GPU:

```text
01:00.0 NVIDIA GA107M GeForce RTX 3050 Mobile
Vendor/device ID: 10de:25a2
Subsystem: 103c:8a3d

01:00.1 NVIDIA GA107 High Definition Audio Controller
Vendor/device ID: 10de:2291
Subsystem: 103c:8a3d
```

Both NVIDIA functions are isolated together in IOMMU group 11:

```text
IOMMU group 11
  0000:01:00.0
  0000:01:00.1
```

The passed-through AMD USB controller is isolated in group 20:

```text
06:00.4 AMD Renoir/Cezanne USB 3.1 controller
Vendor/device ID: 1022:1639
IOMMU group 20:
  0000:06:00.4
Host driver when not assigned to the VM: xhci_hcd
```

No ACS override was observed or required. Recheck the groups after BIOS or
firmware updates because PCI topology can change.

Useful verification:

```bash
for device in 0000:01:00.0 0000:01:00.1 0000:06:00.4; do
  printf '%s: group %s\n' \
    "$device" \
    "$(basename "$(readlink -f "/sys/bus/pci/devices/$device/iommu_group")")"
done

lspci -nnk -s 01:00.0
lspci -nnk -s 01:00.1
lspci -nnk -s 06:00.4
```

## Source-of-truth files

Persistent configuration belongs in this repository:

```text
/home/radhey/code/dots-niri
```

Relevant tracked files:

```text
install/gpu-switch/usr-local-sbin/gpu-status
install/gpu-switch/usr-local-sbin/gpu-to-vfio
install/gpu-switch/usr-local-sbin/gpu-to-nvidia
install/gpu-switch/modprobe/vfio.conf
install/gpu-switch/modprobe/nvidia-vfio-blacklist.conf
install/gpu-switch/modprobe/nvidia.conf
install/gpu-switch/modules-load/nvidia-utils.conf
install/gpu-switch/udev/90-nvidia-no-seat.rules
install/gpu-switch/libvirt-hooks/qemu
install/looking-glass/tmpfiles/looking-glass.conf
.config/scripts/waybar-gpu-switch.sh
.config/scripts/waybar-nvidia.sh
.config/waybar/config.jsonc
.config/waybar/modules.jsonc
.config/waybar/style.css
.config/niri/config.kdl
.local/bin/prime-run
install/install.sh
install/upgrade.sh
```

`install/upgrade.sh` installs the root-owned helper/configuration files and
refreshes the libvirt networking support. It also updates the rest of the
dotfiles, so inspect its current contents and `git status` before running it.

For a narrowly scoped restore, install only the relevant files:

```bash
cd /home/radhey/code/dots-niri

sudo install -Dm755 install/gpu-switch/usr-local-sbin/gpu-status \
  /usr/local/sbin/gpu-status
sudo install -Dm755 install/gpu-switch/usr-local-sbin/gpu-to-vfio \
  /usr/local/sbin/gpu-to-vfio
sudo install -Dm755 install/gpu-switch/usr-local-sbin/gpu-to-nvidia \
  /usr/local/sbin/gpu-to-nvidia
sudo install -Dm755 install/gpu-switch/libvirt-hooks/qemu \
  /etc/libvirt/hooks/qemu

sudo install -Dm644 install/gpu-switch/modprobe/vfio.conf \
  /etc/modprobe.d/vfio.conf
sudo install -Dm644 install/gpu-switch/modprobe/nvidia-vfio-blacklist.conf \
  /etc/modprobe.d/nvidia-vfio-blacklist.conf
sudo install -Dm644 install/gpu-switch/modprobe/nvidia.conf \
  /etc/modprobe.d/nvidia.conf
sudo install -Dm644 install/gpu-switch/modules-load/nvidia-utils.conf \
  /etc/modules-load.d/nvidia-utils.conf
sudo install -Dm644 install/gpu-switch/udev/90-nvidia-no-seat.rules \
  /etc/udev/rules.d/90-nvidia-no-seat.rules

sudo install -Dm644 install/looking-glass/tmpfiles/looking-glass.conf \
  /etc/tmpfiles.d/looking-glass.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/looking-glass.conf
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=drm --action=change
```

## Host packages

The exact relevant package snapshot was:

```text
edk2-ovmf 202605-1
libvirt 12.5.0
looking-glass B7
nvidia-utils 610.43.03
nvidia-prime 1.0
qemu 11.0.2 split packages / qemu-desktop
spice 0.16.0
spice-gtk 0.42
swtpm 0.10.1
usbredir 0.15.0
virt-manager 5.1.0
virt-viewer 11.0
dnsmasq
iptables
nftables
```

On a future Arch/CachyOS installation, install the current equivalents rather
than these historical versions. A representative package command is:

```bash
paru -S \
  qemu-desktop libvirt virt-manager virt-viewer \
  edk2-ovmf swtpm dnsmasq iptables-nft \
  looking-glass spice-gtk usbredir \
  nvidia-open-dkms nvidia-utils nvidia-prime
```

Use the NVIDIA package compatible with the future kernel. DKMS is preferred
when multiple or custom kernels are installed.

The user must be in both `libvirt` and `kvm`:

```bash
sudo usermod -aG libvirt,kvm radhey
```

Log out and back in after changing group membership. At snapshot time:

```text
radhey was a member of libvirt and kvm
libvirt-qemu and qemu were members of kvm
```

## IOMMU, initramfs, and driver ownership

### Firmware

The known working host had AMD virtualization/IOMMU available and Secure Boot
disabled. In firmware setup, enable the equivalent of:

```text
SVM / AMD-V
IOMMU / AMD-Vi
```

The laptop firmware may use different labels.

### Kernel command line

Two systemd-boot entries explicitly contained:

```text
amd_iommu=on iommu=pt vfio-pci.ids=10de:25a2,10de:2291
```

The kernel entry that was actually booted on 2026-07-30 did not contain those
explicit parameters, but AMD IOMMU groups existed and both NVIDIA functions
were successfully owned by `vfio-pci`. The modprobe configuration below was
therefore sufficient with that kernel.

For a future rebuild, explicitly using `amd_iommu=on iommu=pt` is clearer.
Device binding may be done by the kernel parameter, the modprobe configuration,
or both.

Example systemd-boot `options` suffix:

```text
amd_iommu=on iommu=pt vfio-pci.ids=10de:25a2,10de:2291
```

### VFIO configuration

`/etc/modprobe.d/vfio.conf`:

```text
options vfio-pci ids=10de:25a2,10de:2291 disable_vga=1
softdep snd_hda_intel pre: vfio-pci
```

This makes both NVIDIA functions default to VFIO. Loading `vfio-pci` before
`snd_hda_intel` prevents the NVIDIA audio function from being claimed by the
host HDA driver.

`/etc/modprobe.d/nvidia-vfio-blacklist.conf`:

```text
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
```

The NVIDIA modules are deliberately loaded only when `gpu-to-nvidia` requests
Linux PRIME mode.

`/etc/modprobe.d/nvidia.conf`:

```text
options nvidia NVreg_InitializeSystemMemoryAllocations=0 NVreg_DynamicPowerManagement=0x02
```

This also shadows an incompatible distribution option that existed with the
NVIDIA 610 open kernel module. Reassess the exact options against the future
driver rather than assuming they remain necessary forever.

`/etc/modules-load.d/nvidia-utils.conf` is intentionally empty except for its
comment, so NVIDIA is not automatically loaded during boot.

### Initramfs

The working `/etc/mkinitcpio.conf` included:

```bash
MODULES=(amdgpu)
HOOKS=(base systemd autodetect microcode modconf block filesystems)
```

`/etc/mkinitcpio.conf.d/10-chwd.conf` prevented CachyOS hardware detection from
adding NVIDIA modules to the initramfs:

```text
# Managed locally: keep NVIDIA out of initramfs for faster boot.
# Desktop uses AMD iGPU; NVIDIA is PRIME/VFIO only (loaded later if needed).
# Original chwd line was: MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
# Re-run chwd may restore it — remove again if boot slows after driver profile changes.
```

After restoring modprobe, boot-loader, or mkinitcpio configuration:

```bash
sudo mkinitcpio -P
```

Then reboot and verify:

```bash
cat /proc/cmdline
find /sys/kernel/iommu_groups -mindepth 1 -maxdepth 1 -type d
lspci -nnk -s 01:00.0
lspci -nnk -s 01:00.1
```

Both NVIDIA functions should report:

```text
Kernel driver in use: vfio-pci
```

### Keep Niri on AMD

The tracked Niri configuration pins rendering to the AMD iGPU:

```kdl
debug {
    render-drm-device "/dev/dri/by-path/pci-0000:06:00.0-render"
    disable-direct-scanout
}
```

The no-seat udev rule prevents logind/Niri from adopting the dynamically
rebound NVIDIA DRM card:

```text
ACTION!="remove", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ENV{ID_PATH}=="pci-0000:01:00.0", TAG-="seat", TAG-="master-of-seat", TAG-="uaccess"
```

This separation is essential: Niri must not lose its rendering device when the
RTX is moved to the VM.

## Dynamic GPU switching

The live helper scripts are installed at:

```text
/usr/local/sbin/gpu-status
/usr/local/sbin/gpu-to-vfio
/usr/local/sbin/gpu-to-nvidia
```

Their tracked copies are in `install/gpu-switch/usr-local-sbin/`.

All switching is serialized using:

```text
/run/lock/gpu-switch.lock
```

### Switch to VFIO

`gpu-to-vfio`:

1. Requires root.
2. Refuses to proceed if another switch holds the lock.
3. Confirms both PCI devices exist.
4. Checks that `win10-rtx3050` is not already running or paused.
5. Stops `nvidia-persistenced` and `nvidia-powerd` if present.
6. Refuses to proceed if a process is still using `/dev/nvidia*`.
7. Binds audio first, then graphics, to `vfio-pci`.
8. Unloads the NVIDIA modules in reverse dependency order.

Manual workflow:

```bash
sudo /usr/local/sbin/gpu-to-vfio
virsh -c qemu:///system start win10-rtx3050
```

### Switch back to Linux NVIDIA PRIME

The VM must be completely shut off. Paused or suspended is not sufficient.

`gpu-to-nvidia`:

1. Refuses to run while the VM is running or paused.
2. Attempts a PCI function reset when available.
3. Re-enables the PCI device.
4. Loads `nvidia`, `nvidia_modeset`, `nvidia_uvm`, and `nvidia_drm`.
5. Binds `01:00.0` to `nvidia`.
6. Binds `01:00.1` to `snd_hda_intel`.
7. Starts `nvidia-powerd` if present.

Manual workflow:

```bash
virsh -c qemu:///system shutdown win10-rtx3050
watch virsh -c qemu:///system domstate win10-rtx3050

sudo /usr/local/sbin/gpu-to-nvidia
prime-run nvidia-smi
```

The tracked `.local/bin/prime-run` deliberately clears `DRI_PRIME` and selects
the NVIDIA GLX/Vulkan implementation:

```sh
unset DRI_PRIME

NODEVICE_SELECT=1 \
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
VK_LOADER_DRIVERS_SELECT='*nvidia*' \
exec "$@"
```

## Libvirt daemon setup

This system uses modular libvirt daemon sockets. The following sockets were
enabled:

```text
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
```

Restore them with:

```bash
sudo systemctl enable --now \
  virtqemud.socket \
  virtqemud-ro.socket \
  virtqemud-admin.socket \
  virtnetworkd.socket \
  virtnetworkd-ro.socket \
  virtnetworkd-admin.socket \
  virtstoraged.socket \
  virtstoraged-ro.socket \
  virtstoraged-admin.socket \
  virtnodedevd.socket \
  virtnodedevd-ro.socket \
  virtnodedevd-admin.socket
```

Do not blindly enable monolithic `libvirtd.service` as well. It was inactive in
the snapshot; the modular sockets were active.

## Exact virtual-machine configuration

```text
Name:                 win10-rtx3050
UUID:                 a3bde51b-fb5e-460a-ad43-8e27cd7ef322
Autostart:            disabled
Machine:              pc-q35-11.0
Firmware:             OVMF UEFI
Secure Boot:          disabled
Enrolled keys:        disabled
Guest RAM:            6 GiB (6,291,456 KiB)
Guest vCPUs:          8
CPU mode:             host-passthrough
CPU topology:         1 socket, 1 die, 1 cluster, 4 cores, 2 threads
Guest clock:          localtime
TPM:                  emulated TPM 2.0, CRB model
Primary virtual disk: SATA qcow2
Network adapter:      virtio on libvirt network "default"
Fallback display:     QXL
Remote display:       SPICE, localhost only, auto-assigned port
Audio:                ICH9 through SPICE
Memory balloon:       disabled
Watchdog:             iTCO, reset action
```

The older intended values of 8 GiB RAM, 6 vCPUs, 3 cores/2 threads, and a
64 MiB Looking Glass region were **not** the live values. The live values above
are the recovery baseline.

### Firmware and machine details

```xml
<os firmware='efi'>
  <type arch='x86_64' machine='pc-q35-11.0'>hvm</type>
  <firmware>
    <feature enabled='no' name='enrolled-keys'/>
    <feature enabled='no' name='secure-boot'/>
  </firmware>
  <loader readonly='yes' type='pflash' format='raw'>/usr/share/edk2/x64/OVMF_CODE.4m.fd</loader>
  <nvram template='/usr/share/edk2/x64/OVMF_VARS.4m.fd'
         templateFormat='raw'
         format='raw'>/var/lib/libvirt/qemu/nvram/win10-rtx3050_VARS.fd</nvram>
  <boot dev='hd'/>
  <bootmenu enable='yes'/>
</os>
```

QEMU machine versions and OVMF paths can change. If `pc-q35-11.0` no longer
exists, use a supported Q35 version. If restoring the original NVRAM, retain a
compatible OVMF build and make a copy before allowing it to migrate.

### CPU and hypervisor features

```xml
<vcpu placement='static'>8</vcpu>

<cpu mode='host-passthrough' check='none' migratable='on'>
  <topology sockets='1' dies='1' clusters='1' cores='4' threads='2'/>
  <feature policy='require' name='topoext'/>
</cpu>

<features>
  <acpi/>
  <apic/>
  <hyperv mode='custom'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='8191'/>
    <vpindex state='on'/>
    <runtime state='on'/>
    <synic state='on'/>
    <stimer state='on'/>
    <frequencies state='on'/>
    <tlbflush state='on'/>
    <ipi state='on'/>
    <avic state='on'/>
  </hyperv>
  <kvm>
    <hidden state='on'/>
  </kvm>
  <vmport state='off'/>
</features>
```

The VM uses shared memfd backing, which Looking Glass needs:

```xml
<memory unit='KiB'>6291456</memory>
<currentMemory unit='KiB'>6291456</currentMemory>
<memoryBacking>
  <source type='memfd'/>
  <access mode='shared'/>
</memoryBacking>
```

### Virtual disk

```xml
<disk type='file' device='disk'>
  <driver name='qemu'
          type='qcow2'
          cache='writeback'
          io='threads'
          discard='unmap'
          detect_zeroes='off'/>
  <source file='/var/lib/libvirt/images-nocow/win10-rtx3050.qcow2'/>
  <target dev='sda' bus='sata'/>
</disk>
```

The directory and image both had Btrfs NOCOW (`chattr +C`) set. When creating a
new image on Btrfs:

```bash
sudo install -d -m755 /var/lib/libvirt/images-nocow
sudo chattr +C /var/lib/libvirt/images-nocow
sudo qemu-img create -f qcow2 \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2 1000G
sudo chown libvirt-qemu:libvirt-qemu \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
sudo chmod 0640 \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
```

Set NOCOW on an empty directory/file before filling it. Do not assume applying
`chattr +C` to an already populated file rewrites existing extents.

Installation media recorded on the host:

```text
/var/lib/libvirt/images/iso/Win10_22H2_English_x64v1.iso
/var/lib/libvirt/images/virtio-win.iso
```

The ISOs were no longer attached to the VM. The installed system disk uses a
SATA virtual controller, so it does not depend on a VirtIO storage driver to
boot. The network adapter does use VirtIO.

### Passthrough devices

GPU:

```xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
  </source>
</hostdev>
```

GPU audio:

```xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
  </source>
</hostdev>
```

Isolated AMD USB controller:

```xml
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    <address domain='0x0000' bus='0x06' slot='0x00' function='0x4'/>
  </source>
</hostdev>
```

Optional USB device:

```xml
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source startupPolicy='optional'>
    <vendor id='0x0bda'/>
    <product id='0x9210'/>
  </source>
</hostdev>
```

At snapshot time `0bda:9210` was a Realtek RTL9210 M.2 NVMe adapter. Because
`startupPolicy` is optional, the VM can start without it. Ensure any filesystem
on that USB device is unmounted from Linux before giving it to Windows.

### TPM state

```xml
<tpm model='tpm-crb'>
  <backend type='emulator' version='2.0'>
    <profile name='default-v1'/>
  </backend>
</tpm>
```

The state was stored under:

```text
/var/lib/libvirt/swtpm/a3bde51b-fb5e-460a-ad43-8e27cd7ef322/tpm2/
```

If BitLocker or another guest feature seals keys to this virtual TPM, losing
the TPM state can make encrypted guest data unrecoverable. Preserve the
BitLocker recovery key separately before dismantling the VM.

## Guest disk access through NBD

The host can expose Windows partition 3 from the qcow2 at `/dev/nbd0p3`.
`/etc/fstab` contained:

```fstab
/dev/nbd0p3 /mnt/windows ntfs3 noauto,nofail,uid=1000,gid=1000,dmask=000,fmask=000,acl=0,force 0 0
```

The libvirt hook at `/etc/libvirt/hooks/qemu` protects the image from being
opened by both the host and guest:

- Before VM start, it unmounts any mount backed by `/dev/nbd0p3`.
- It disconnects `/dev/nbd0`.
- If unmount/disconnect fails, it refuses VM start.
- After VM shutdown, it reconnects the qcow2 to `/dev/nbd0`.
- It waits for `/dev/nbd0p3` to appear but does not automatically mount it.
- Messages are logged with the tag `libvirt-nbd-hook[win10-rtx3050]`.

Manual connection while the VM is off:

```bash
sudo modprobe nbd max_part=16
sudo qemu-nbd --cache=none \
  --connect=/dev/nbd0 \
  /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
sudo blockdev --rereadpt /dev/nbd0
sudo udevadm settle
lsblk /dev/nbd0
sudo mount /mnt/windows
```

Manual safe disconnection:

```bash
sudo umount /mnt/windows
sudo qemu-nbd --disconnect /dev/nbd0
```

Never start the VM while its qcow2 partitions are mounted. Never use
`--force-share` to bypass this exclusivity.

## Network configuration

The VM uses libvirt's default NAT network:

```text
Network name:        default
Bridge:              virbr0
Network:             192.168.122.0/24
Host/gateway/DNS:    192.168.122.1
DHCP range:          192.168.122.2 - 192.168.122.254
VM MAC:              52:54:00:1a:cd:bd
Reserved guest IP:   192.168.122.50
Network autostart:   enabled
```

VM interface:

```xml
<interface type='network'>
  <mac address='52:54:00:1a:cd:bd'/>
  <source network='default'/>
  <model type='virtio'/>
</interface>
```

Restore or update the DHCP reservation:

```bash
sudo virsh -c qemu:///system net-update default add ip-dhcp-host \
  '<host mac="52:54:00:1a:cd:bd" name="win10-rtx3050" ip="192.168.122.50"/>' \
  --live --config

sudo virsh -c qemu:///system net-autostart default
sudo virsh -c qemu:///system net-start default
```

If the reservation already exists, use `modify` rather than adding a duplicate.

The relevant UFW rules were:

```text
ALLOW IN  on virbr0 from 192.168.122.0/24 to 192.168.122.1 port 53/udp
ALLOW IN  on virbr0 from 192.168.122.0/24 to 192.168.122.1 port 53/tcp
ALLOW IN  on virbr0 to any port 67/udp
ALLOW FWD from 192.168.122.0/24 on virbr0 to anywhere on wlan0
```

Representative restore commands:

```bash
sudo ufw allow in on virbr0 from 192.168.122.0/24 \
  to 192.168.122.1 proto udp port 53
sudo ufw allow in on virbr0 from 192.168.122.0/24 \
  to 192.168.122.1 proto tcp port 53
sudo ufw allow in on virbr0 proto udp to any port 67
sudo ufw route allow in on virbr0 out on wlan0 \
  from 192.168.122.0/24 comment 'libvirt NAT VM egress via host wlan0'
```

The outbound interface may not be named `wlan0` on a future installation.
Check `ip route` and substitute the actual interface.

Validation:

```bash
virsh -c qemu:///system net-info default
virsh -c qemu:///system net-dhcp-leases default
ip addr show virbr0
sudo ufw status numbered
```

## Looking Glass

### Linux shared-memory file

Tracked tmpfiles configuration:

```text
f /dev/shm/looking-glass 0660 radhey kvm -
```

It creates:

```text
/dev/shm/looking-glass
mode 0660
owner radhey
group kvm
```

Apply and verify:

```bash
sudo systemd-tmpfiles --create /etc/tmpfiles.d/looking-glass.conf
stat -c '%n mode=%a owner=%U:%G' /dev/shm/looking-glass
```

### VM IVSHMEM device

The live VM uses **256 MiB**, not 64 MiB:

```xml
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>256</size>
  <address type='pci' domain='0x0000' bus='0x10' slot='0x01' function='0x0'/>
</shmem>
```

The guest PCI address is recorded for completeness but can be assigned
automatically when rebuilding.

### SPICE and fallback devices

The VM retains these devices:

```xml
<channel type='spicevmc'>
  <target type='virtio' name='com.redhat.spice.0'/>
</channel>

<input type='tablet' bus='usb'/>
<input type='mouse' bus='ps2'/>
<input type='keyboard' bus='ps2'/>

<graphics type='spice' autoport='yes' listen='127.0.0.1'>
  <listen type='address' address='127.0.0.1'/>
  <image compression='off'/>
</graphics>

<sound model='ich9'/>
<audio id='1' type='spice'/>

<video>
  <model type='qxl'
         ram='65536'
         vram='65536'
         vgamem='16384'
         heads='1'
         primary='yes'/>
</video>
```

There are also two SPICE USB redirection devices. Keeping QXL and SPICE is
intentional: Looking Glass provides the fast picture, while SPICE provides
input, clipboard, and a recovery console.

### Windows guest requirements

The following must be done inside Windows:

1. Install the NVIDIA driver for the passed-through RTX 3050 Mobile.
2. Install the VirtIO network driver.
3. Install the IVSHMEM driver supplied through the VirtIO/Looking Glass setup.
4. Install a Looking Glass Host version compatible with the Linux B7 client.
5. Configure Looking Glass Host to start after login.
6. Ensure Windows renders a desktop on the NVIDIA GPU. A physical output,
   dummy plug, or virtual display solution may be required if Windows considers
   the GPU headless.

The current guest-side Looking Glass Host version, configuration, and startup
entry could not be verified while the VM was shut down. If the client says the
host application is not running, that is normally a guest-side Host/IVSHMEM
problem, not a Linux client rendering problem.

### Linux client command

The Waybar launcher discovers the current SPICE port and runs:

```bash
looking-glass-client \
  -F \
  app:shmFile=/dev/shm/looking-glass \
  spice:host=127.0.0.1 \
  spice:port="$SPICE_PORT" \
  spice:input=yes \
  spice:clipboard=yes \
  spice:captureOnStart=yes \
  input:captureOnFocus=yes \
  input:escapeKey=KEY_RIGHTCTRL
```

The fallback port is 5900. Query the actual dynamically assigned port with:

```bash
virsh -c qemu:///system domdisplay win10-rtx3050 --type spice
```

Right Ctrl releases captured input.

## Waybar and Niri integration

Niri defines workspace 5 as `vm`. These application IDs open there:

```text
virt-manager
remote-viewer
virt-viewer
looking-glass-client
```

Waybar uses `custom/gpu-switch`:

```jsonc
"custom/gpu-switch": {
  "exec": "$HOME/.config/scripts/waybar-gpu-switch.sh status",
  "return-type": "json",
  "interval": 5,
  "signal": 9,
  "format": "{}",
  "tooltip": true,
  "on-click": "$HOME/.config/scripts/waybar-gpu-switch.sh menu",
  "on-click-right": "$HOME/.config/scripts/waybar-gpu-switch.sh to-linux",
  "on-click-middle": "$HOME/.config/scripts/waybar-gpu-switch.sh toggle-vm"
}
```

Controls:

```text
Left click:    fuzzel menu
Right click:   shut down guest if needed, then switch RTX to Linux PRIME
Middle click:  start or shut down the Windows VM
Menu:          Linux PRIME, start/shutdown VM, Looking Glass, virt-manager, status
```

Starting Windows from the script:

1. Bind the GPU/audio to VFIO if necessary, using `pkexec`.
2. Start `win10-rtx3050`.
3. Refresh Waybar through real-time signal 9.

Switching to Linux:

1. Request graceful guest shutdown.
2. Wait up to 180 seconds for `shut off`.
3. Refuse to rebind if shutdown does not complete.
4. Run `gpu-to-nvidia` through `pkexec`.

Reload Waybar after restoring the configuration:

```bash
pkill -SIGUSR2 waybar || true
```

If the reload is stale:

```bash
pkill -TERM waybar || true
setsid -f waybar >/tmp/waybar.log 2>&1
```

## Recreating or restoring the VM

### Restore the exact installed guest

1. Install QEMU, libvirt, OVMF, swtpm, VirtIO/SPICE, and Looking Glass.
2. Restore the GPU switching configuration and reboot.
3. Restore the qcow2 to
   `/var/lib/libvirt/images-nocow/win10-rtx3050.qcow2`.
4. Restore its ownership to `libvirt-qemu:libvirt-qemu`, mode `0640`.
5. Restore the NVRAM file to
   `/var/lib/libvirt/qemu/nvram/win10-rtx3050_VARS.fd`.
6. Restore the swtpm UUID directory under `/var/lib/libvirt/swtpm/`.
7. Restore the inactive libvirt XML and check all paths.
8. Define it:

```bash
sudo virsh -c qemu:///system define /path/to/win10-rtx3050.xml
```

9. Confirm that the VM remains non-autostarting:

```bash
sudo virsh -c qemu:///system autostart --disable win10-rtx3050
```

10. Restore the NAT reservation, firewall rules, tmpfiles entry, and Waybar
    integration.

Before first boot:

```bash
sudo virsh -c qemu:///system domstate win10-rtx3050
sudo virsh -c qemu:///system dumpxml --inactive win10-rtx3050 \
  | less
sudo /usr/local/sbin/gpu-status
qemu-img info /var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
```

### Build a fresh Windows guest

If the original VM disk is not retained:

1. Create a Q35/OVMF VM with SPICE/QXL first.
2. Use 6 GiB RAM and 8 vCPUs with 4 cores/2 threads to reproduce the snapshot,
   or choose new values appropriate to the host workload.
3. Use host-passthrough CPU mode and TPM 2.0.
4. Install Windows and VirtIO drivers before adding passthrough devices.
5. Shut Windows down fully.
6. Add `01:00.0`, `01:00.1`, and optionally `06:00.4`.
7. Add the 256 MiB IVSHMEM device.
8. Keep QXL, SPICE, and the virtual tablet.
9. Install NVIDIA, IVSHMEM, and Looking Glass Host inside Windows.
10. Validate Looking Glass before removing or changing any fallback display.

## Validation checklist

Host:

```bash
sudo /usr/local/sbin/gpu-status
virsh -c qemu:///system domstate win10-rtx3050
virsh -c qemu:///system net-info default
stat /dev/shm/looking-glass
```

Expected before VM start:

```text
GPU driver:   vfio-pci
Audio driver: vfio-pci
VM state:     shut off
```

Start and inspect:

```bash
virsh -c qemu:///system start win10-rtx3050
virsh -c qemu:///system domstate win10-rtx3050
virsh -c qemu:///system domdisplay win10-rtx3050 --type spice
virsh -c qemu:///system net-dhcp-leases default
journalctl -t 'libvirt-nbd-hook[win10-rtx3050]' -n 50
```

Then open Looking Glass from the Waybar menu or with the explicit client
command.

Return the RTX to Linux:

```bash
virsh -c qemu:///system shutdown win10-rtx3050
watch virsh -c qemu:///system domstate win10-rtx3050
sudo /usr/local/sbin/gpu-to-nvidia
prime-run nvidia-smi
```

Switch it back to the default VM-ready state when finished:

```bash
sudo /usr/local/sbin/gpu-to-vfio
```

## Troubleshooting

### `gpu-to-vfio` says the NVIDIA device is in use

Close Linux games, CUDA applications, monitoring tools, and anything else
holding `/dev/nvidia*`. Check:

```bash
sudo fuser -v /dev/nvidia*
```

### Niri freezes or disappears when switching

Confirm Niri still uses:

```text
/dev/dri/by-path/pci-0000:06:00.0-render
```

Confirm the NVIDIA no-seat rule is installed and that the AMD GPU remains on
`amdgpu`.

### VM refuses to start because of NBD

Check for a host mount and disconnect NBD:

```bash
findmnt -S /dev/nbd0p3
sudo umount /mnt/windows
sudo qemu-nbd --disconnect /dev/nbd0
journalctl -t 'libvirt-nbd-hook[win10-rtx3050]' -n 50
```

Do not bypass the hook; the purpose is to prevent qcow2 corruption.

### VM starts but NVIDIA does not appear in Windows

Verify both functions are on VFIO and present in the inactive XML:

```bash
lspci -nnk -s 01:00.0
lspci -nnk -s 01:00.1
virsh -c qemu:///system dumpxml --inactive win10-rtx3050 \
  | rg -n -C 5 hostdev
```

Both `01:00.0` and `01:00.1` must be passed together.

### Looking Glass shows “host application is not running”

Check:

```bash
stat /dev/shm/looking-glass
virsh -c qemu:///system dumpxml win10-rtx3050 | rg -n -C 4 shmem
```

If those are correct, start or repair Looking Glass Host and the IVSHMEM driver
inside Windows.

### Looking Glass has no input or clipboard

Keep SPICE listening on `127.0.0.1`, retain the `spicevmc` channel, and launch
the client with:

```text
spice:input=yes
spice:clipboard=yes
```

### VM has no internet

```bash
virsh -c qemu:///system net-info default
virsh -c qemu:///system net-dhcp-leases default
ip addr show virbr0
sudo ufw status numbered
```

Confirm the default network is active, the MAC reservation exists, DNS/DHCP is
allowed on `virbr0`, and forwarding uses the host's current outbound interface.

### GPU will not return to NVIDIA

The guest must report `shut off`, not paused:

```bash
virsh -c qemu:///system domstate win10-rtx3050
```

Then inspect:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/enable
readlink -f /sys/bus/pci/devices/0000:01:00.0/driver
sudo dmesg | tail -n 100
```

A full host reboot with the VFIO configuration restored is the safest recovery
if dynamic reattachment fails.

## Files to preserve if dismantling the setup

For future recovery, keep this repository and, if the installed guest matters,
an external backup of:

```text
/var/lib/libvirt/images-nocow/win10-rtx3050.qcow2
/var/lib/libvirt/qemu/nvram/win10-rtx3050_VARS.fd
/var/lib/libvirt/swtpm/a3bde51b-fb5e-460a-ad43-8e27cd7ef322/
inactive libvirt XML from virsh dumpxml
Windows BitLocker recovery key, if BitLocker is enabled
Windows-side Looking Glass Host installer/configuration, if available
```

Also record any future change to:

```text
PCI addresses and IDs
IOMMU groups
VM UUID
VM disk path
VM MAC and reserved IP
Looking Glass shared-memory size
OVMF/NVRAM paths
Windows guest encryption state
```

That is the complete dependency chain needed to return from native dual boot to
the current single-host Niri + Windows passthrough architecture.
