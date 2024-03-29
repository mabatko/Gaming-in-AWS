# Gaming in AWS

**TLDR:** This repository contains information on how I set up my low cost remote gaming environment in AWS and how you can do it too.

If you are not interested in how I came to final setup, you can skip the theory and jump right to [pre-requisites](#pre-requisites).

![KSP menu](ksp.png)

## Motivation

I don't have a lot of free time, but sometimes when I do, I want to play computer games. Problem is however that I don't have PC with GPU powerful enough to play modern-ish games. My current PC is OK for everything else though, so I don't want to spend ~800€ for a new PC comparable to what I can get in a cloud.

It is possible to play games on a VM which costs less than 20 cents per hour. Therefore, I would have to play more than 4000 hours to make buying a new PC more economical decision.

## Limitations

If this sounds too good to be true, you are right. There are some limitations to consider.
- Since your game is running hundreds (or maybe even thousands) of kilometers away, there is some latency which can make playing less enjoyable or even downright frustrating. FPS games where every millisecond counts, or online games are probably not good candidates for this sort of shenanigans.
- Cloud providers don't offer very wide range of GPUs and most of them are suitable for computing, not for 3D workloads. Even the most performant GPU I found in a cloud is only half as powerful as top-notch GeForce RTX 4090. Don't expect 4K max quality raytracing orgies any time soon.

## When this makes sense?

With services like [GeForce NOW](https://www.nvidia.com/en-eu/geforce-now/) (for 11€/month) there are only few niches which gaming in AWS can fill. For example:
- game you want to play is not availabe in such service
- you need access to operating system to do changes to the game (mods, etc.)
- you play so little and infrequently that you don't want to pay for month long membership
- you have AWS credits you want to burn

Let me know if you have other reason why to play games in AWS.

## Setup

After a lot of research, I settled to following setup:
- AWS g4ad.xlarge EC2 spot instance (4 vCPUs, 16GB RAM, Radeon PRO v520 GPU) running
- Ubuntu 18.04 AMI with 
  - AMD GPU driver
  - NICE DCV remote desktop
  - Steam client

### AWS

Let's start with the question "Why AWS?".

In a nutshell, AWS seems to provide the best GPU performance for your money. 

Azure of course also has instance families with GPUs which are suitable for gaming but those are either not as powerfull as AWS ones ([NCasT4_v3 family](https://learn.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series)) or are not cost competitive ([NVadsA10v5](https://learn.microsoft.com/en-us/azure/virtual-machines/nva10v5-series)).

I briefly had a look also on Google cloud, but as far as I can tell, they provide only GPU instances inferior to AWS and are more expensive.

### g4ad instance family

Why g4ad.xlarge EC2 instance?

There is also g4dn family in AWS with NVIDIA Tesla T4 GPU, but it is more expensive than g4ad (at least in my region at this time). Also, according to [this site](https://www.videocardbenchmark.net/gpu_list.php) Radeon GPU scores ~15% better in Passmark G3D benchmark. Moreover, [AWS also claims](https://aws.amazon.com/blogs/compute/deep-dive-on-the-new-amazon-ec2-g4ad-instances/) that *"the g4ad instance family has up to 40% better performance over g4dn for general-purpose graphics rendering, and gaming workloads in addition to 15%-25% lower cost."*

Another AWS EC2 family suitable for gaming is g5 with NVIDIA A10G GPU. [AWS says](https://aws.amazon.com/ec2/instance-types/g5/) that it delivers up to 3x better performance compared to g4dn. It scores ~50% better than Radeon PRO v520 in Passmark G3D benchmark, but costs three time as much.

### Ubuntu 18.04

Now, when we have instance type sorted out, it's time to decide operating system.

You can go the easy route and pick Windows server - there is even AMI from AWS with Windows Server 2019 and driver preinstalled. It works nicely and you can play all the games in a few minutes. What's the catch? On-demand Windows instances are ~50% more expensive than Linux instances and more than twice as expensive when it comes to spot instances (again, in my region). Since playing cheaply is my main objective, I go with Linux (also, being a former Unix admin may play a role). Downside is that many games in my Steam library don't run natively on Linux. Fortunately, there is Proton from Steam which partially plugs this hole for me (but you may be out of luck).

So why Ubuntu 18.04 which celebrates five years since release when these lines are being written? It's simple. AMD GPU driver for Ubuntu works only with Ubuntu 18.04. Newer Ubuntu versions are not supported (I tried and failed but give it a try and let me know :)).

Another reason to go with Ubuntu is that Steam supports it. I tried Amazon Linux 2 AMI which comes with GPU driver preinstalled and I even managed to start Steam client, but all windows were black so I couldn't install any game.

#### Spot EC2 instance

For those who don't know, AWS (usually) has more capacity than is needed to satisfy customer demand. This spare capacity is sold in the form of spot EC2 instances at a discount. Caveat is that AWS can take this capacity back with only little warning (2 minutes). This didn't happen to me yet, but there is always a chance.

For some, this inconvenience may not be worth the price (or rather saving). If your game doesn't allow you to save progress at any moment, spot instance is probably not for you. Games I play allow it, so I go with spot. Plus, in my region are g4ad.xlarge Linux spot instances sold with 70% discount. 

As a side note: Azure and Google cloud spot instances can be price competitive, but they warn you only 30 seconds before they stop your instance.

### NICE DCV

*NICE DCV is a high-performance remote display protocol. It lets you securely deliver remote desktops and application streaming from any cloud or data center to any device, over varying network conditions. By using NICE DCV with Amazon EC2, you can run graphics-intensive applications remotely on Amazon EC2 instances. You can then stream the results to more modest client machines, which eliminates the need for expensive dedicated workstations.*

NICE DCV is free if you run it on AWS EC2 instance. I guess (hope) that it is better than using RDP for Windows or VNC for Linux. I haven't done any research in this area. If you did, let me know how it fairs in comparison with other options. I'm particularly interested in network bandwidth consumption.

### Steam

I have most of my games from Steam, so it's a must-have for me. Fortunately, there is an installer for Ubuntu.

Apart from installation of Linux native games, Steam has some features which are relevant to our topic:
1. Already mentioned Proton, which is a compatibility layer allowing to run some Windows games on Linux.
2. Games can store saves in Steam cloud (at least games I play do). This is important if you want to terminate your instance and delete its disk in order to save as much money as possible.
3. You can enable FPS counter in Steam client, so you can easily determine if your setup is adequate. Of course, you can install another tool if you wish...

## Pre-requisites

### Region

If you want to try this setup yourself, first and foremost, you must select a region based on these criteria:
- it must have g4ad instances - not all regions have them
- it should be geographically close to you in order to have better latency
- if you are price sensitive, select more distant but cheaper region

There are web sites which [measure latency](https://www.cloudping.cloud/aws) from your browser to AWS regions. Take the results with a big grain of salt though. Real latency between EC2 instance and my PC measured by ping command was MUCH better than what the website says.

You can check instance type availability and pricing on these pages:
- [Amazon EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [Amazon EC2 Spot Instances Pricing](https://aws.amazon.com/ec2/spot/pricing/)

### Limits for g4ad family

My first attempt to launch g4ad.xlarge instance failed because default limit is set to 0 cores. You can check your limit this way:
1. go to region which you want to use
2. go to EC2 service
3. on the left-hand side menu select "Limits"
4. search for "all g" 

You should see two entries:
- All G and VT Spot Instance Requests
- Running On-Demand All G and VT instances

In my case, both were set to 0 vCPU. I requested increase to 4 vCPU (because g4ad.xlarge has 4 cores). At first my requests were auto-declined, because I didn't have high AWS bills (as a reason for decline AWS stated that they are protecting me from unexpectedly high invoice). I appealed the decision and re-opened the requests. I argued that I'm certified AWS solutions architect and developer (which I really am :)) and hopefully I know what I'm doing. Humans took over the requests and my limits were increased in about a day.

### VPC, subnet, instance profile, etc...

Before you launch anything, I suggest you have following resources created:
- VPC with network resources (internet gateway, routing table, ...)
- subnet(s)
  - not all availability zones in a region must have g4ad instances available (in my region only two out of three have them)
    - spot prices for instances don't have to be the same in all availability zones (there is a small difference in my region)
  - subnet should be public, i.e., you should be able to reach your instance over the Internet
- security group
  - for simplicity sake, I allowed all traffic incoming from my IP
    - if my IP changes, I will have to update this rule
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
- **Name:** name of the game
- **Application and OS Images (Amazon Machine Image)**: Ubuntu 18.04 is not offered by AWS in a drop-down menu anymore, because it is too old. However, Ubuntu 18.04 AMIs are still maintained and kept up to date by Canonical - company behind Ubuntu. You can find the most up-to-date AMI for your region on [this page](https://cloud-images.ubuntu.com/locator/ec2/). Copy AMI ID from there and search for it in AWS console. You will find the AMI under Community AMIs.
- **Instance type:** g4ad.xlarge
- **Key pair (login):** key pair created as a pre-requisite
- **Network settings:**
  - **Network:** VPC you created as a pre-requisite
  - **Subnet:** Subnet you created as a pre-requisite. If you have more subnets, pick the one with the cheapest spot price.
  - **Security groups:** Pick the one you created as a pre-requisite
- **Storage:** 
  - **Size:** ~10GB is taken by OS, so you definitely want more than that. Have a look on your game's Steam store page where disk requirements are usually mentioned.
  - **Volume type:** gp3 should be cheaper than gp2 and more performant
  - :warning: **Delete on termination:** Select "No". This is important if you use spot instance. By default, when EC2 instance is terminated, root disk is deleted. In our case it would mean that everything is lost when you shut down your EC2 (unless you always want to start from scratch).
- **Advanced details:**
  - **Request Spot Instances:** ☑
  - **IAM instance profile:** Pick the one you created as a pre-requisite
  - **User data:** this [bash script](https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/user_data.sh). You may want to change MYUSER/PASS variables.

If you are lost, [here is a screenshot](instance_creation.png).

### Connecting

When instance is running, you can connect to it as user `ubuntu` via SSH with the private key from your SSH key pair. It takes 20-ish minutes for *user data* script to finish. You can see the progress in log file `/var/log/cloud-init-output.log` on the OS.

Instance is rebooted when the script finishes. When it boots up again, you can connect to it in following ways:
- over SSH with user ubuntu and key defined during instance creation
- over SSH with user which was defined in variable MYUSER of *user data* script (unless `MYUSER=ubuntu`)
  - either with password or with key defined during instance creation
- using NICE DCV client
  - clients for Windows, Linux and MacOS can be downloaded from [here](https://download.nice-dcv.com/)
  - log in to the instance with username/password from the *user data* script
  - this is how you connect to play a game

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

Either way, disk performance of instances launched from AMI is abysmal. AMIs are just EBS snapshots stored in S3 and lazy loaded when read request is made. Therefore, it is necessary (or not, if you are patient) to initialize (or pre-warm) EBS volume. This is done by reading all disk blocks before an application really needs them. This can be done by good old dd command, but *user data* script installs utility called `fio`. Advantage of `fio` is that it can run multiple threads, so initialization is much faster. If you want this initialization to be triggered right after boot, uncomment following line in `/etc/crontab` file:
```
#@reboot root fio --filename=/dev/nvme0n1 --rw=read --bs=128k --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize >> /var/log/fio.log
```
You will suffer decreased performance after boot, but at least in my case games start DRASTICALLY faster. Unfortunately, read speeds vary. Slowest I saw was 34.5MB/s, fastest was 77 MB/s.

To give you a perspective of how long it takes, 30GB gp3 EBS with default settings can be initialized between 7 and 15 minutes. Subsequent executions of the command finish with average read speed of 126 MB/s (which is performance advertised by AWS).

## Tips and optional steps

### Termination check script

If you use spot instance, you may want to have a separate SSH or terminal session opened with running `termination_check.sh` script. The script is in home directory of user specified in *user data* script. It checks instance's metadata every 5 seconds for rebalance recommendation and interruption notice. If one is received, script tries to beep and prints out yellow or red timestamp when notice was issued. It didn't happen to me yet and AWS claims that 92% of all spot instances are terminated by the user, but just in case this happens to you, little heads-up (2 minutes) can be useful. 

### NICE DCV

If your mouse is bahaving weirdly in games, try to enable "Relative Mouse Position" in NICE DVC client settings. It locks your mouse pointer within NICE DCV window and you have to press Ctrl+Shift+F8 to free it. In Fallout: New Vegas and Fallout 4 was my camera pointing towards ground and only rotating - I wasn't able to look up. Enabling this option fixed the issue.

As far as I know, NICE DCV can't strech remote screen (e.g., I want to have remote instance's 1920x1080p stretched to fullscreen on my 4K screen). As a workaround, I decrease resolution of my local screen to 1920x1080p. I don't play games in 4K anyway and network bandwith decreases drastically (and so does data transfer costs).

Default NICE DCV frame rate limit is 25 which is pretty low for FPS games. I increased it to 45. If you play slow paced games and you don't need high frame rate and want to save some bandwith, set `target-fps` in `/etc/dcv/dcv.conf` to whatever you want and restart `dcvserver` service.

### Steam settings

After steam client is installed and you want to play Windows games on Linux, enable Steam play:
```
`Steam -> Settings -> Steam Play -> Enable Steam Play for all other titles
```

If your Windows game doesn't work properly, try to use different version of Proton:
```
Select game in Library -> Manage (gear icon on the right) -> Properties -> Compatibility -> Force the use of a specifit Steam Play compatibility tool
```

If you want to know what frame rates your Steam games are running at, enable FPS counter:
```
Steam -> Settings -> In-Game -> In-game FPS counter
```

### GPU utilization

If you want to check GPU utilization of your instance, CLI utility `nvtop` is installed.

### Costs

You are charged for following resources, so try to keep them at bay:
- EC2 instances
  - [Amazon EC2 On-Demand Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
  - [Amazon EC2 Spot Instances Pricing](https://aws.amazon.com/ec2/spot/pricing/)
- EBS volumes and snapshots (AMIs also fall under this category)
  - [Amazon EBS pricing](https://aws.amazon.com/ebs/pricing/)
  - If you use spot instances, don't keep EBS volumes. You can't use them anyway, so make EBS snapshots and delete the volumes.
- Data transfer
  - [Data Transfer pricing](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer)
  - AWS charges outgoing traffic from EC2 to the Internet (i.e. your remote desktop stream), however we get 100GB free each month, which should be enough for 20+ hours of playing at 45 FPS (give or take)
  - Incoming traffic (i.e. you downloading games) is free

#### Example

To give you some sense about how much money we talk, here is my setup:
- eu-central-1 (Franfurt) region - region with lowest latency
- euc1-az3 zone - zone with cheapest spot instances

For playing Fallout 4 I use:
- g4ad.xlarge EC2 instance - 4 vCPU and 16 GB RAM is enough
- 60 GB gp3 EBS volume with default IOPS and throughput
- snapshot of above volume from which I create new instance has ~50 GB

If I play for 20 hours in a 30 day month, I pay following:
- g4ad.xlarge spot instance: $0.142 per hour
  - 20 * $0.142 = $2.84
- gp3 EBS volume: $0.0952 per GB-month
  - 60 * 20 * $0.0952 / (30 * 24) = $0.16
- EBS snapshot: $0.054 per GB-Month
  - 50 * $0.054 = $2.7
- data transfer out of AWS: $0.09 per GB
  - 70 GB - within free tier
- 20% VAT

In total: **$6.84** per month or **$0.34** per gaming hour.

As you can see, almost half of the cost is for storage of AMI. If I'm patient, not lazy and deploy fresh instance for each gaming session, I would pay **$0.18** per hour + ~$0.18 per session as an overhead for instance bootstrap and game installation.


### AWS Budgets

I set up [AWS Budgets](https://aws.amazon.com/aws-cost-management/aws-budgets/) email notifications which let me know when I spend more than defined threshold. You will be glad you set it up when you forget to power off your gaming instance.

Two budgets are free, so why not use them?

## Feedback

If you have ideas how to improve this guide, open an issue.
