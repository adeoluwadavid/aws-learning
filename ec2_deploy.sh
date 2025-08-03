#!/bin/bash

set -e  # Exit if any command fails

EC2_USER=ubuntu
EC2_HOST=44.203.172.65
KEY_PATH=/root/.ssh/my-key.pem

echo "➡️ Copying app and requirements.txt to EC2..."
scp -i $KEY_PATH -o StrictHostKeyChecking=no -r ./app requirements.txt $EC2_USER@$EC2_HOST:/home/ubuntu/

echo "✅ Files copied"

echo "🚀 Deploying on EC2..."
ssh -i $KEY_PATH -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'ENDSSH'
  set -e
  cd /home/ubuntu/app

  echo "🛠️ Creating virtual environment..."
  python3 -m venv venv
  source venv/bin/activate

  echo "📦 Installing dependencies..."
  pip install -r /home/ubuntu/requirements.txt

  echo "🔁 Restarting FastAPI server..."
  pkill -f uvicorn || true
  nohup venv/bin/uvicorn main:app --host 0.0.0.0 --port 80 > /home/ubuntu/fastapi.log 2>&1 &

  echo "✅ FastAPI is running on port 80"
ENDSSH
