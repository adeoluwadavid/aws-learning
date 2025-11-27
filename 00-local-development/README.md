# Phase 0: Local Development

This is the foundation of the TaskFlow application - a collaborative task management app built with React and FastAPI.

## What You'll Learn

- **Frontend**: React 18, TypeScript, Vite, TailwindCSS, React Query
- **Backend**: FastAPI, SQLAlchemy, Pydantic, JWT authentication
- **Local Development**: Docker Compose for consistent environments

## Project Structure

```
00-local-development/
├── backend/
│   ├── app/
│   │   ├── routers/          # API endpoints
│   │   │   ├── auth.py       # Authentication (register, login)
│   │   │   ├── tasks.py      # Task CRUD operations
│   │   │   ├── users.py      # User listing
│   │   │   └── attachments.py # File uploads
│   │   ├── main.py           # FastAPI app entry point
│   │   ├── models.py         # SQLAlchemy models
│   │   ├── schemas.py        # Pydantic schemas
│   │   ├── auth.py           # JWT authentication logic
│   │   ├── database.py       # Database connection
│   │   └── config.py         # App configuration
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/       # Reusable UI components
│   │   ├── pages/            # Page components
│   │   ├── hooks/            # Custom React hooks
│   │   ├── lib/              # API client, utilities
│   │   └── types/            # TypeScript types
│   ├── package.json
│   └── Dockerfile
└── docker-compose.yml
```

## Features

- User registration and authentication (JWT)
- Create, read, update, delete tasks
- Assign tasks to users
- Set task priority (low, medium, high)
- Set task status (todo, in_progress, done)
- Set due dates
- File attachments (stored locally for now)

## Getting Started

### Option 1: Using Docker (Recommended)

```bash
# Start both frontend and backend
docker compose up --build

# Frontend: http://localhost:5173
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### Option 2: Manual Setup

#### Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python -m uvicorn app.main:app --reload

# API available at http://localhost:8000
# Swagger docs at http://localhost:8000/docs
```

#### Frontend

```bash
cd frontend

# Install dependencies
pnpm install

# Run development server
pnpm dev

# App available at http://localhost:5173
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login (returns JWT token)
- `GET /auth/me` - Get current user

### Tasks
- `GET /tasks` - List all tasks (with optional filters)
- `POST /tasks` - Create a task
- `GET /tasks/{id}` - Get task details
- `PATCH /tasks/{id}` - Update a task
- `DELETE /tasks/{id}` - Delete a task

### Users
- `GET /users` - List all users

### Attachments
- `GET /tasks/{id}/attachments` - List task attachments
- `POST /tasks/{id}/attachments` - Upload attachment
- `DELETE /tasks/{id}/attachments/{attachment_id}` - Delete attachment

## Testing the API

```bash
# Register a user
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "username": "testuser", "password": "password123"}'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=password123"

# Create a task (use token from login response)
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title": "My first task", "description": "Testing the API", "priority": "high"}'
```

## Next Steps

After completing this phase, you'll have a working full-stack application. In the next phases, we'll:

1. **Phase 1**: Set up VPC and IAM basics
2. **Phase 2**: Move file attachments to S3
3. **Phase 3**: Migrate database to RDS/DynamoDB
4. **Phase 4**: Containerize and push to ECR
5. ...and more!

## Key Concepts to Understand

Before moving to AWS:

- [ ] How JWT authentication works
- [ ] How the frontend communicates with the backend (CORS, API calls)
- [ ] How SQLAlchemy ORM maps to database tables
- [ ] How React Query manages server state
- [ ] How Docker containers work
