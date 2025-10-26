#!/bin/bash
set -e

echo "=== Arch Linux EFI Boot Repair Script ==="

# Detect main partitions
echo "[*] Detecting partitions..."
ROOT=$(lsblk -o NAME,MOUNTPOINT,SIZE,TYPE -nr | grep part | awk '{print "/dev/"$1}' | fzf --prompt="Select your ROOT partition: ")
BOOT=$(lsblk -o NAME,MOUNTPOINT,SIZE,TYPE -nr | grep part | awk '{print "/dev/"$1}' | fzf --prompt="Select your /boot partition (if any, or press Enter to skip): ")
EFI=$(lsblk -o NAME,MOUNTPOINT,SIZE,TYPE -nr | grep part | awk '{print "/dev/"$1}' | fzf --prompt="Select your EFI partition: ")

# Mount root
mount "$ROOT" /mnt

if [ -n "$BOOT" ]; then
  mkdir -p /mnt/boot
  mount "$BOOT" /mnt/boot
fi

mkdir -p /mnt/boot/efi
mount "$EFI" /mnt/boot/efi

echo "[*] Entering chroot..."
arch-chroot /mnt /bin/bash <<'EOF'
set -e
echo "[*] Syncing packages and kernel..."
pacman -Sy --noconfirm linux grub

echo "[*] Rebuilding initramfs..."
mkinitcpio -P

echo "[*] Reinstalling GRUB for EFI..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

echo "[*] Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "[*] Checking kernel file..."
file /boot/vmlinuz-linux || echo "⚠️ Kernel file check failed!"

echo "[*] Done inside chroot."
EOF

echo "[*] Running filesystem checks on EFI..."
umount /mnt/boot/efi || true
fsck.vfat -a "$EFI" || true
mount "$EFI" /mnt/boot/efi

echo "[*] Unmounting all..."
umount -R /mnt

echo "✅ Repair complete. You can now reboot."
