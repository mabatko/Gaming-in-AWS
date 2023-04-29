#!/bin/bash

###
###  This script checks metadata of an EC2 spot instance for:
###  - rebalance recommendation
###  - interruption notice
###
###  You can find latest version here:
###    https://raw.githubusercontent.com/mabatko/Gaming-in-AWS/main/termination_check.sh
###

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' 

while true; do
  TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`;
  INTERRUPTION=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/spot/instance-action 2>/dev/null`;
  REBALANCE=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/events/recommendations/rebalance 2>/dev/null`;

  if [[ "$INTERRUPTION" == *"Not Found"* ]]
  then
    if [[ "$REBALANCE" == *"Not Found"* ]]
    then
      echo -e "`date`: $GREEN OK $NC"
    else
      echo -e "`date`: $YELLOW NOTICE @ $REBALANCE $NC \007"
    fi
  else
    echo -e "`date`: $RED TERMINATION @ $INTERRUPTION $NC \007"
  fi

  sleep 5

done

