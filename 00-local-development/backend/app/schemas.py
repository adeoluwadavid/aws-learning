from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr

from app.models import TaskStatus, TaskPriority


# User schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Auth schemas
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None


# Attachment schemas
class AttachmentBase(BaseModel):
    filename: str


class AttachmentResponse(AttachmentBase):
    id: int
    file_path: str
    file_size: int
    content_type: Optional[str]
    uploaded_at: datetime

    class Config:
        from_attributes = True


# Task schemas
class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[datetime] = None


class TaskCreate(TaskBase):
    assignee_id: Optional[int] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    due_date: Optional[datetime] = None
    assignee_id: Optional[int] = None


class TaskResponse(TaskBase):
    id: int
    status: TaskStatus
    created_at: datetime
    updated_at: datetime
    creator_id: int
    assignee_id: Optional[int]
    creator: UserResponse
    assignee: Optional[UserResponse]
    attachments: List[AttachmentResponse] = []

    class Config:
        from_attributes = True


class TaskListResponse(BaseModel):
    id: int
    title: str
    status: TaskStatus
    priority: TaskPriority
    due_date: Optional[datetime]
    created_at: datetime
    assignee: Optional[UserResponse]

    class Config:
        from_attributes = True
