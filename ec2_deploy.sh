#!/bin/bash

EC2_USER=ubuntu
EC2_HOST=44.203.172.65
KEY_PATH=/root/.ssh/my-key.pem

# Upload app and requirements.txt
scp -i $KEY_PATH -o StrictHostKeyChecking=no -r ./app $EC2_USER@$EC2_HOST:/home/ubuntu/
scp -i $KEY_PATH -o StrictHostKeyChecking=no ./requirements.txt $EC2_USER@$EC2_HOST:/home/ubuntu/

# SSH and run commands

ssh -i $KEY_PATH -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'ENDSSH'
  cd /home/ubuntu/app
  python3 -m venv venv
  source venv/bin/activate
  pip install -r /home/ubuntu/requirements.txt
  nohup venv/bin/uvicorn main:app --host 0.0.0.0 --port 80 --reload > /home/ubuntu/fastapi.log 2>&1 &
ENDSSH
