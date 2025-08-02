#!/bin/bash

EC2_USER=ubuntu
EC2_HOST=your-ec2-ip
KEY_PATH=/root/.ssh/your-private-key.pem

scp -i $KEY_PATH -o StrictHostKeyChecking=no -r ./app $EC2_USER@$EC2_HOST:/home/ubuntu/

ssh -i $KEY_PATH -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'ENDSSH'
  cd /home/ubuntu/app
  pip3 install -r ../requirements.txt
  nohup uvicorn main:app --host 0.0.0.0 --port 80 --reload &
ENDSSH
