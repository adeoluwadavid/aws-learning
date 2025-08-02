# 🚀 FastAPI CI/CD with AWS EC2

This project demonstrates how to set up a CI/CD pipeline using **GitHub**, **AWS CodePipeline**, **CodeBuild**, and **EC2** to deploy a FastAPI application.

---

## 📁 Project Structure

aws-learning/
├── app/
│ └── main.py # FastAPI app
├── requirements.txt # Python dependencies
├── buildspec.yml # CodeBuild build instructions
├── ec2_deploy.sh # Bash script to deploy to EC2
├── .gitignore # Ignore unnecessary files
└── README.md # This file


---

## 🧪 Run Locally

### 1. Create a virtual environment (optional but recommended)
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload


API Root: http://127.0.0.1:8000

Swagger Docs: http://127.0.0.1:8000/docs
