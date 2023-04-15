# Gaming in AWS

**TLDR:** This repository contains information on how I set up my gaming environment in AWS and how you can do it too.

## Motivation
I don't have much of a free time, but sometimes when I do, I want to play games. Problem is however, that I don't have PC powerful enough to play modern-ish games. My current PC is OK for everything else though, so I don't want to spend ~1000 euro for a new decent PC. 

It is possible to play games on a VM which costs less than 20 cents per hour. Therefore, I would have to play more than 5000 hours to make buying a new PC more economical decision.

## Setup

My setup is following:
- g4ad.xlarge EC2 spot instance (4 vCPUs, 16GB RAM, Radeon PRO v520 GPU) running
- Ubuntu 18.04 AMI with 
  - AMD GPU driver
  - NICE DCV remote desktop
  - Steam client

### g4ad.xlarge instance

Why g4ad.xlarge EC2 instance?

Let's start with the question "Why AWS?". AWS seems to provide the best GPU performance for your money. Azure of course also provides GPU accelerated instances suitable for gaming, but their small sized VMs have access only to a fraction of a GPU. If you want to have e.g. half of NVIDIA A10, you must launch instance with 18 vCPUs and 220GB of RAM (Standard_NV18ads_A10_v5). That's bit of an overkill for playing a game and it also isn't cheap. I briefly had a look also on Google cloud, but as far as I can tell, they provide only GPU instances inferior to AWS and are more expensive.

So why g4ad family?

There is also g4dn family in AWS with NVIDIA Tesla T4 GPU, but it is more expensive than g4ad. Also, according to site https://www.videocardbenchmark.net/gpu_list.php Radeon GPU scores ~20% better in Passmark G3D benchmark.

Another AWS EC2 family suitable for gaming is g5 with NVIDIA A10G GPU which scores ~60% better than Radeon PRO v520, but costs three time as much.

### Ubuntu 18.04

Now, when we have instance type sorted out, it's time to decide operating system.

You can go the easy route and pick Windows server - there is even AMI from AWS with Windows Server 2019 and driver preinstalled. It works nicely and you can play all the games in a few minutes. What's the catch? On-demand Windows instances are ~50% more expensive than Linux instances and more than twice as expensive when it comes to spot instances. Since playing cheaply is my main driver, I go with Linux (also, being a former Unix admin may play a role). Downside is that many games in my Steam library don't run on Linux.

So why Ubuntu 18.04 which celebrates five years since release when these lines are written? It's simple. AMD GPU driver for Ubuntu works only with Ubuntu 18.04. Newer Ubuntu versions are not supported (I tried and failed, but give it a try and let me know :)).

Another reason to go with Ubuntu is that Steam supports it. I tried Amazon Linux 2 AMI which comes with GPU driver preinstalled and I even managed to start Steam client, but all windows where black.

#### Spot EC2 instance

For those who don't know, AWS (usualy) has more capacity than is needed to satify customer demand. This spare capacity is sold in the form of spot EC2 instances at a discount. Caveat is that AWS can take this capacity back with only little warning (2 minutes). This didn't happen to me yet, but there is always a chance.

For some, this inconveniece may not be worth the price (or rather saving). If your game doesn't allow you to save progress at any moment, spot instance is probably not for you. Kerbal space program does allow it, so I go with it. Plus, in my region are g4ad.xlarge Linux spot instances sold with 70% discount. 

### NICE DCV

*NICE DCV is a high-performance remote display protocol. It lets you securely deliver remote desktops and application streaming from any cloud or data center to any device, over varying network conditions. By using NICE DCV with Amazon EC2, you can run graphics-intensive applications remotely on Amazon EC2 instances. You can then stream the results to more modest client machines, which eliminates the need for expensive dedicated workstations.*

NICE DCV is free if you run it on AWS EC2 instance. I guess (hope) that it is better than using RDP for Windows of VNC for Linux. I haven't done any research in this area. If you did, let me know how it fairs in comparison with other options. I'm particularly interested in network bandwidth consumption.

### Steam

I have most of my games from Steam, so it's a must-have for me. Fortunately there is an installer for Ubuntu.

Apart from installation of games, Steam has some features which are relevant to our topic:
1. Games can store saves in Steam cloud (at least games I play do). This is important if you want to terminate your instance and delete its disk in order to save as much money as possible.
2. You can enable FPS counter in Steam client, so you can easily determine if your setup is adequate. Of course you can install other tool if you wish...

## Pre-requisites

### Region

First and foremost you must select a region based on these criteria:
- it must have g4ad instances - not all regions have them
- it should be geograficaly close to you in order to have better latency
- if you are price sensitive, select more distant but cheaper region

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

In my case, both were set to 0 vCPU. I requested increase to 4 vCPU (because g4ad.xlarge has 4 cores). At first my requests were auto-declined, because I don't have high AWS bills (as a reason for decline AWS stated that they are protecting me from unexpectedly high bill). I appealed the decision and re-opened the requests. I argued that I'm certified AWS solutions architect and developer (which I really am :)) and hopefully I know what I'm doing. Humans took over the requests and my limits were increased in about a day.

### VPC, subnet, instance profile, etc...

Before you launch anything, I suggest you to have following resources created:
- VPC
- subnet
  - not all availability zones in a region must have g4ad instaces available (in my region only two out of three have them)
    - spot prices for instances don't have to be the same in all availability zones (there is a small difference in my region)
  - subnet should be public, i.e. you should be able to reach your instance over the Internet
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

### Launching EC2 instance

When I launch my gaming instance, I select following options:
- **Name:** whatever
- **Application and OS Images (Amazon Machine Image)**: Ubuntu 18.04 is not offered by AWS in a drop-down menu anymore, because it is too old. However, Ubuntu 18.04 AMIs are still maintained and kept up to date by Canonical - company behind Ubuntu. You can find the most up-to-date AMI for your region on this page: https://cloud-images.ubuntu.com/locator/ec2/ . Copy AMI ID from there and search for it in AWS console. You will find the AMI under Community AMIs.
- **Instance type:** g4ad.xlarge
- **Key pair (login):** key pair created as a pre-requisite
- **Network settings:**
  - **Network:** VPC you created as a pre-requisite
  - **Subnet:** Subnet you created as a pre-requisite. If you have more subnets, pick the one with cheapest spot instance.
  - **Security groups:** Pick the one you created as a pre-requisite
- **Storage:** 
  - **Size:** ~10GB is taken by OS, so you definitely want more than that
  - **Volume type:** gp3 should be cheaper than gp2 and more performant
  - :warning: **Delete on temination:** Select "No". This is important if you use spot instance. By default, when EC2 instance is terminated, root disk is deleted. In our case it would mean that everything is lost when you shut down your EC2.
- **Advanced details:**
  - **Request Spot Instances:** ☑
  - **IAM instance profile:** Pick the one you created as a pre-requisite
  - **User data:** this [bash script](https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/user_data.sh)










## how to connetct
 windows nice dcv client
  ubuntu with key
  user with pass















