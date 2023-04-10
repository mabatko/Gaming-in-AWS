#!/bin/bash

USER=<YOURUSERNAME>
PASS=<USERSPASSWORD>

####
#### Install AMD drivers on Linux instances
#### https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-amd-driver.html
####

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo dpkg --add-architecture i386
aws s3 cp --recursive s3://ec2-amd-linux-drivers/latest/ .
tar -xf amdgpu-pro*ubuntu*.xz
cd amdgpu-pro*/
sudo apt install linux-modules-extra-$(uname -r) -y
./amdgpu-pro-install -y --opencl=pal,legacy

sudo apt install xorg-dev ubuntu-mate-desktop -y 
sudo apt purge ifupdown -y

curl "https://github.com/mabatko/Gaming-on-AWS/blob/main/xorg.conf" -o "/etc/X11/xorg.conf"
sudo apt install ./amf-amdgpu-pro_20.20-*_amd64.deb
cd ..

####
#### Installing the NICE DCV Server
#### https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-prereq.html
#### https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-server.html
####

sudo apt update
sudo apt install ubuntu-desktop
sudo apt install lightdm

sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target 

sudo apt install mesa-utils

wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
gpg --import NICE-GPG-KEY

wget https://d1uj6qtbmh3dt5.cloudfront.net/2023.0/Servers/nice-dcv-2023.0-14852-ubuntu1804-x86_64.tgz
tar -xvzf nice-dcv-2023.0-14852-ubuntu1804-x86_64.tgz && cd nice-dcv-2023.0-14852-ubuntu1804-x86_64
sudo apt install ./nice-dcv-server_2023.0.14852-1_amd64.ubuntu1804.deb
sudo usermod -aG video dcv

sudo systemctl start dcvserver
sudo systemctl enable dcvserver

sudo useradd $USER -m -s /bin/bash
sudo usermod -a -G adm,dialout,cdrom,floppy,sudo,audio,dip,video $USER
printf "$PASS\n$PASS\n\n" | passwd $USER

sed -i 's/#create-session=true/create-session=true/g' /etc/dcv/dcv.conf
sed -i "s/#owner=''/owner=$USER/g" /etc/dcv/dcv.conf

####
#### Steam for Linux - launcher
#### https://repo.steampowered.com/steam/
####

sudo curl "https://repo.steampowered.com/steam/archive/stable/steam.gpg" -o "/usr/share/keyrings/steam.gpg"
sudo echo 'deb [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam' >> /etc/apt/sources.list.d/steam-stable.list
sudo echo 'deb-src [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam' >> /etc/apt/sources.list.d/steam-stable.list
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1-mesa-glx:amd64 libgl1-mesa-glx:i386 steam-launcher

####
#### Miscellaneous
####

curl "https://github.com/mabatko/Gaming-on-AWS/blob/main/termination_check.sh" -o "/home/$USER/termination_check.sh"
chown $USER:$USER /home/$USER/termination_check.sh
chmod 544 /home/$USER/termination_check.sh


sudo shutdown -r now