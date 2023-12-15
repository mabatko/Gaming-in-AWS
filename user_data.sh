#!/bin/bash

####
#### This script was last time checked on 4/15/2023 with Ubuntu 18.04 release 20230329.
#### Script output can be found in /var/log/cloud-init-output.log
####

MYUSER=ubuntu
PASS=SuperSecretPwd

set -x

####
#### Install AMD drivers on Linux instances
#### https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-amd-driver.html
####

sudo apt update
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo dpkg --add-architecture i386
aws s3 cp s3://ec2-amd-linux-drivers/latest/amdgpu-pro-20.20-1184451-ubuntu-18.04.tar.xz .
tar -xf amdgpu-pro*ubuntu*.xz
cd amdgpu-pro*/
sudo apt install linux-modules-extra-$(uname -r) -y
./amdgpu-pro-install -y --opencl=pal,legacy

sudo apt install xorg-dev ubuntu-mate-desktop -y 
sudo apt purge ifupdown -y

curl "https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/xorg.conf" -o "/etc/X11/xorg.conf"
sudo apt install ./amf-amdgpu-pro_20.20-*_amd64.deb -y
cd ..

####
#### Installing the NICE DCV Server
#### https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-prereq.html
#### https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-server.html
####

sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target 

sudo apt install mesa-utils

wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
gpg --import NICE-GPG-KEY

wget https://d1uj6qtbmh3dt5.cloudfront.net/2023.0/Servers/nice-dcv-2023.0-14852-ubuntu1804-x86_64.tgz
tar -xvzf nice-dcv-2023.0-14852-ubuntu1804-x86_64.tgz && cd nice-dcv-2023.0-14852-ubuntu1804-x86_64
sudo apt install ./nice-dcv-server_2023.0.14852-1_amd64.ubuntu1804.deb -y
sudo usermod -aG video dcv

sudo systemctl start dcvserver
sudo systemctl enable dcvserver

sudo useradd $MYUSER -m -s /bin/bash
sudo usermod -a -G adm,dialout,cdrom,floppy,sudo,audio,dip,video $MYUSER
printf "$PASS\n$PASS\n\n" | passwd $MYUSER

sed -i 's/#create-session = true/create-session = true/g' /etc/dcv/dcv.conf
sed -i 's/#owner = ""/owner = "'"$MYUSER"'"/g' /etc/dcv/dcv.conf
sed -i 's/#target-fps = 30/target-fps = 45/g' /etc/dcv/dcv.conf
sed -i 's/#enable-quic-frontend = true/enable-quic-frontend = true/g' /etc/dcv/dcv.conf
cd ..

####
#### Steam for Linux - launcher
#### https://repo.steampowered.com/steam/
####

sudo curl "https://repo.steampowered.com/steam/archive/stable/steam.gpg" -o "/usr/share/keyrings/steam.gpg"
sudo echo 'deb [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam' >> /etc/apt/sources.list.d/steam-stable.list
sudo echo 'deb-src [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam' >> /etc/apt/sources.list.d/steam-stable.list
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install --no-remove libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 libgl1-mesa-glx:amd64 libgl1-mesa-glx:i386 xdg-desktop-portal xdg-desktop-portal-gtk steam -y


####
#### Miscellaneous
####

sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/10periodic
sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades

curl "https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/termination_check.sh" -o "/home/$MYUSER/termination_check.sh"
chown $MYUSER:$MYUSER /home/$MYUSER/termination_check.sh
chmod 544 /home/$MYUSER/termination_check.sh

if [[ "$MYUSER" != "ubuntu" ]]
then
  echo "$MYUSER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/90-cloud-init-users
  mkdir /home/$MYUSER/.ssh
  cp /home/ubuntu/.ssh/authorized_keys /home/$MYUSER/.ssh/authorized_keys
  chown -R $MYUSER:$MYUSER /home/$MYUSER/.ssh
fi

sudo apt install fio -y
echo '#@reboot root fio --filename=/dev/nvme0n1 --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize >> /var/log/fio.log' >> /etc/crontab

sudo snap install nvtop

rm -rf NICE-GPG-KEY amdgpu-pro-*.tar.xz amdgpu-pro-*-ubuntu-18.04/ aws/ awscliv2.zip nice-dcv-2023.0-14852-ubuntu1804-x86_64/ nice-dcv-2023.0-14852-ubuntu1804-x86_64.tgz

sudo shutdown -r now