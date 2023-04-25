# Gaming in AWS

**TLDR:** This repository contains information on how I set up my low cost gaming environment in AWS and how you can do it too.

![KSP menu](ksp.png)

## Motivation

I don't have a lot of free time, but sometimes when I do, I want to play games. Problem is however that I don't have PC powerful enough to play modern-ish games. My current PC is OK for everything else though, so I don't want to spend ~1000 euro for a new decent PC. 

It is possible to play games on a VM which costs less than 20 cents per hour. Therefore, I would have to play more than 5000 hours to make buying a new PC more economical decision.

## Limitations

If this sounds too good to be true, you are right. There are some limitations to consider.
- Since your game is (potentially) running hundreds of kilometers away, there is some latency which can make playing less enjoyable or even downright frustrating. FPS games where every millisecond counts, or online games are probably not good candidates for this sort of shenanigans.
- Cloud providers don't offer very wide range of GPUs and most of them are suitable for computing, not for 3D workloads. Even the most performant GPU I found in a cloud is only half as powerful as top-notch GeForce RTX 4090. Don't expect 4K max quality raytracing orgies any time soon.

## Setup

My setup is following:
- g4ad.xlarge EC2 spot instance (4 vCPUs, 16GB RAM, Radeon PRO v520 GPU) running
- Ubuntu 18.04 AMI with 
  - AMD GPU driver
  - NICE DCV remote desktop
  - Steam client

### g4ad.xlarge instance

Why g4ad.xlarge EC2 instance?

Let's start with the question "Why AWS?". AWS seems to provide the best GPU performance for your money. Azure of course also provides GPU accelerated instances suitable for gaming, but their small sized VMs have access only to a fraction of a GPU. If you want to have e.g., half of NVIDIA A10, you must launch instance with 18 vCPUs and 220GB of RAM (Standard_NV18ads_A10_v5). That's bit of an overkill for playing a game and it also isn't cheap. I briefly had a look also on Google cloud, but as far as I can tell, they provide only GPU instances inferior to AWS and are more expensive.

So why g4ad family?

There is also g4dn family in AWS with NVIDIA Tesla T4 GPU, but it is more expensive than g4ad (at least in my region at this time). Also, according to [this site](https://www.videocardbenchmark.net/gpu_list.php) Radeon GPU scores ~15% better in Passmark G3D benchmark (I wasn't able to verify that myself though).

Another AWS EC2 family suitable for gaming is g5 with NVIDIA A10G GPU which scores ~50% better than Radeon PRO v520, but costs three time as much.

### Ubuntu 18.04

Now, when we have instance type sorted out, it's time to decide operating system.

You can go the easy route and pick Windows server - there is even AMI from AWS with Windows Server 2019 and driver preinstalled. It works nicely and you can play all the games in a few minutes. What's the catch? On-demand Windows instances are ~50% more expensive than Linux instances and more than twice as expensive when it comes to spot instances (again, in my region). Since playing cheaply is my main driver, I go with Linux (also, being a former Unix admin may play a role). Downside is that many games in my Steam library don't run natively on Linux. Fortunately, there is Proton from Steam which partially plugs this hole for me (but you may be out of luck).

So why Ubuntu 18.04 which celebrates five years since release when these lines are written? It's simple. AMD GPU driver for Ubuntu works only with Ubuntu 18.04. Newer Ubuntu versions are not supported (I tried and failed but give it a try and let me know :)).

Another reason to go with Ubuntu is that Steam supports it. I tried Amazon Linux 2 AMI which comes with GPU driver preinstalled and I even managed to start Steam client, but all windows where black.

#### Spot EC2 instance

For those who don't know, AWS (usually) has more capacity than is needed to satisfy customer demand. This spare capacity is sold in the form of spot EC2 instances at a discount. Caveat is that AWS can take this capacity back with only little warning (2 minutes). This didn't happen to me yet, but there is always a chance.

For some, this inconvenience may not be worth the price (or rather saving). If your game doesn't allow you to save progress at any moment, spot instance is probably not for you. Kerbal space program does allow it, so I go with it. Plus, in my region are g4ad.xlarge Linux spot instances sold with 70% discount. 

As a side note: Azure spot instances can be price competitive, but Microsoft warns you only 30 seconds before they stop your instance.

### NICE DCV

*NICE DCV is a high-performance remote display protocol. It lets you securely deliver remote desktops and application streaming from any cloud or data center to any device, over varying network conditions. By using NICE DCV with Amazon EC2, you can run graphics-intensive applications remotely on Amazon EC2 instances. You can then stream the results to more modest client machines, which eliminates the need for expensive dedicated workstations. *

NICE DCV is free if you run it on AWS EC2 instance. I guess (hope) that it is better than using RDP for Windows or VNC for Linux. I haven't done any research in this area. If you did, let me know how it fairs in comparison with other options. I'm particularly interested in network bandwidth consumption.

### Steam

I have most of my games from Steam, so it's a must-have for me. Fortunately, there is an installer for Ubuntu.

Apart from installation of Linux native games, Steam has some features which are relevant to our topic:
1. Already mentioned Proton, which is a compatibility layer allowing to run some Windows games on Linux.
2. Games can store saves in Steam cloud (at least games I play do). This is important if you want to terminate your instance and delete its disk in order to save as much money as possible.
3. You can enable FPS counter in Steam client, so you can easily determine if your setup is adequate. Of course, you can install another tool if you wish...

## Pre-requisites

### Region

First and foremost, you must select a region based on these criteria:
- it must have g4ad instances - not all regions have them
- it should be geographically close to you in order to have better latency
- if you are price sensitive, select more distant but cheaper region

There are web sites which [measure latency](https://www.cloudping.cloud/aws) from your browser to AWS regions. Take the results with a big grain of salt though. Real latency between EC2 instance and my PC measured by ping command was MUCH better than what the website says.

You can check instance type availability and pricing on these pages:
- [Amazon EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [Amazon EC2 Spot Instances Pricing](https://aws.amazon.com/ec2/spot/pricing/)

### Limits for g4ad family

My first attempt to launch g4ad.xlarge instance failed because default limit is 0 cores. You can check your limit this way:
1. go to region which you want to use
2. go to EC2 service
3. on the left-hand side menu select "Limits"
4. search for "all g" 

You should see two entries:
- All G and VT Spot Instance Requests
- Running On-Demand All G and VT instances

In my case, both were set to 0 vCPU. I requested increase to 4 vCPU (because g4ad.xlarge has 4 cores). At first my requests were auto-declined, because I don't have high AWS bills (as a reason for decline AWS stated that they are protecting me from unexpectedly high invoice). I appealed the decision and re-opened the requests. I argued that I'm certified AWS solutions architect and developer (which I really am :)) and hopefully I know what I'm doing. Humans took over the requests and my limits were increased in about a day.

### VPC, subnet, instance profile, etc...

Before you launch anything, I suggest you have following resources created:
- VPC
- subnet
  - not all availability zones in a region must have g4ad instances available (in my region only two out of three have them)
    - spot prices for instances don't have to be the same in all availability zones (there is a small difference in my region)
  - subnet should be public, i.e., you should be able to reach your instance over the Internet
- security group
  - I allowed all traffic incoming from my IP
    - if your IP changes, you will have to update this rule
- key pair
- role for instance (instance profile)
  - your EC2 instance's instance profile must allow it to get objects from S3 buckets
  - I created a new role which has AWS managed policy "AmazonS3ReadOnlyAccess"
  - this instance profile is assigned to EC2 instance during creation
  - it needs it to:
    1. download GPU driver
    2. download NICE DCV license

## Implementation

### Launching EC2 (spot) instance

When I launch my gaming instance, I select following options:
- **Name:** whatever
- **Application and OS Images (Amazon Machine Image)**: Ubuntu 18.04 is not offered by AWS in a drop-down menu anymore, because it is too old. However, Ubuntu 18.04 AMIs are still maintained and kept up to date by Canonical - company behind Ubuntu. You can find the most up-to-date AMI for your region on [this page](https://cloud-images.ubuntu.com/locator/ec2/). Copy AMI ID from there and search for it in AWS console. You will find the AMI under Community AMIs.
- **Instance type:** g4ad.xlarge
- **Key pair (login):** key pair created as a pre-requisite
- **Network settings:**
  - **Network:** VPC you created as a pre-requisite
  - **Subnet:** Subnet you created as a pre-requisite. If you have more subnets, pick the one with cheapest spot instance.
  - **Security groups:** Pick the one you created as a pre-requisite
- **Storage:** 
  - **Size:** ~10GB is taken by OS, so you definitely want more than that
  - **Volume type:** gp3 should be cheaper than gp2 and more performant
  - :warning: **Delete on termination:** Select "No". This is important if you use spot instance. By default, when EC2 instance is terminated, root disk is deleted. In our case it would mean that everything is lost when you shut down your EC2.
- **Advanced details:**
  - **Request Spot Instances:** ☑
  - **IAM instance profile:** Pick the one you created as a pre-requisite
  - **User data:** this [bash script](https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/user_data.sh). You may want to change MYUSER/PASS variables.

If you are lost, [here is a screenshot](instance_creation.png).

### Connecting

At this stage, you can connect to the instance as user 'ubuntu' via SSH with the private key from your SSH key pair. It takes 20-ish minutes for *user data* script to finish. You can see the progress in log file /var/log/cloud-init-output.log on the OS.

Instance is rebooted when the script finishes. When it boots up again, you can connect to it in following ways:
- over SSH with user ubuntu
- over SSH with user which was defined in variable MYUSER of *user data* script (unless MYUSER=ubuntu)
- using NICE DCV client
  - clients for Windows, Linux and MacOS can be downloaded from [here](https://download.nice-dcv.com/)
  - log in to the instance with username/password from the *user data* script

### Steam

Steam launcher is already installed on the instance, but you need to configure it for your user. Click on the "Start" button in the top left corner and search Steam. If everything goes well, Steam launcher downloads Steam client into user's home directory and login window appears.

That should be it. Happy gaming!

## Preserving root disk

At this point you should be able to install and play Linux games from Steam. When you are done though, you may (or may not) want to preserve root disk where everything is stored.

![possibilities what to do with the instance](chart.svg)

Broadly speaking, you have following options:
- if you run on-demand or persistent spot instance and you don't mind paying for EBS volume when instance is powered off, you can stop/start the instance at will
- if you don't mind re-deploying a new instance from scratch and installing game(s) manually, you can just terminate your instance after you are done playing
- if you don't want to always start from scratch and you don't want to pay for EBS volume of stopped instance (or you can't stop your one-time spot instance), you have to create an AMI from the instance before you terminate it.

### Living with AMIs

Since AMIs are immutable, if you want to always preserve latest changes to the disk, you must create new AMI after every gaming session. If you don't need it (e.g. because game saves are in Steam cloud), you can create *golden AMI* and always start your instance from it.

Either way, disk performance of instances launched from AMI is abysmal. AMIs are just EBS snapshots stored in S3 and lazy loaded when read request is made. Therefore, it is necessary (or not, if you are patient) to initialize (or pre-warm) EBS volume. This is done by reading all disk blocks before an application really needed them. This can be done by good old dd command, but *user data* script installs utility called fio. Advantage of fio is that it can run multiple threads, so initialization is much faster. If you want this initialization to be triggered right after boot, uncomment following line in /etc/crontab file:
```
#@reboot root fio --filename=/dev/nvme0n1 --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize >> /var/log/fio.log
```
You will suffer decreased performance for a few minutes after boot, but at least in my case games start DRASTICALLY faster. To give you a perspective of how long it takes, 30GB gp3 EBS with default settings was initialized in 7 minutes.

## Tips

### Termination check script

If you use spot instance, you may want to have a separate SSH session opened with running `termination_check.sh` script. It didn't happen to me yet and AWS claims that 92% of all spot instances are terminated by the user, but just in case this happens to you, little heads-up (2 minutes) can be useful. The script is in home directory of user specified in *user data* script. It checks instance's metadata every 5 seconds for rebalance recommendation and interruption notice.

### Costs

You are charged for following resources, so try to keep them at bay:
- EC2 instances
- EBS volumes
- EBS snapshots (AMIs fall under this category)
- data transfer

### AWS Budgets

I set up [AWS Budgets](https://aws.amazon.com/aws-cost-management/aws-budgets/) email notifications which let me know when I spend more than defined threshold. You will be glad you set it up when you forget to power off your gaming instance.

Two budgets are free, so why not use them?









