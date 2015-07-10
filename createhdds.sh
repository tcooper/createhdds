#!/bin/bash
echo "Creating disk_full.img..."
guestfish <<_EOF_
sparse disk_full.img 10G
run
part-init /dev/sda mbr
part-add /dev/sda p 1 10485760
part-add /dev/sda p 10485761 -1
mkfs ext4 /dev/sda1
mkfs ext4 /dev/sda2
mount /dev/sda1 /
write /testfile "Hello, world!"
umount /
mount /dev/sda2 /
write /testfile "Oh, hi Mark"
umount /
_EOF_

echo "Creating disk_freespace.img..."
guestfish <<_EOF_
sparse disk_freespace.img 10G
run
part-init /dev/sda mbr
part-add /dev/sda p 4096 2097152
mkfs ext4 /dev/sda1
mount /dev/sda1 /
write /testfile "Hello, world!"
_EOF_

echo "Creating disk_f21_minimal.img..."
virt-builder fedora-21 -o disk_f21_minimal.img --update --selinux-relabel --root-password password:weakpassword > /dev/null
expect <<_EOF_
log_user 0
set timeout -1

spawn qemu-kvm -m 2G -nographic disk_f21_minimal.img

expect "localhost login:"
send "root\r"
expect "Password:"
send "weakpassword\r"
expect "~]#"
send "poweroff\r"
expect "reboot: Power down"
_EOF_

echo "Creating disk_ks.img..."
curl --silent -o "/tmp/root-user-crypted-net.ks" "https://jskladan.fedorapeople.org/kickstarts/root-user-crypted-net.ks" > /dev/null
guestfish <<_EOF_
sparse disk_ks.img 100MB
run
part-init /dev/sda mbr
part-add /dev/sda p 4096 -1
mkfs ext4 /dev/sda1
mount /dev/sda1 /
upload /tmp/root-user-crypted-net.ks /root-user-crypted-net.ks
_EOF_
