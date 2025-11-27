# =============================================================================
# ATTACHMENTS ROUTER
# =============================================================================
# Handles file uploads and downloads for task attachments.
# Supports both local storage and S3 based on configuration.

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from app.auth import get_current_active_user
from app.config import settings
from app.database import get_db
from app.models import Task, User, Attachment
from app.schemas import AttachmentResponse
from app.storage import get_storage

router = APIRouter(prefix="/tasks/{task_id}/attachments", tags=["Attachments"])


@router.get("", response_model=List[AttachmentResponse])
def get_attachments(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """List all attachments for a task."""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    return task.attachments


@router.post("", response_model=AttachmentResponse, status_code=status.HTTP_201_CREATED)
async def upload_attachment(
    task_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Upload a file attachment to a task.

    The file is stored either locally or in S3 based on the USE_S3 setting.
    """
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )

    # Get storage backend (local or S3)
    storage = get_storage()

    # Upload file
    folder = f"tasks/{task_id}"
    file_path, file_size = storage.upload_file(
        file=file.file,
        filename=file.filename,
        folder=folder,
        content_type=file.content_type
    )

    # Create attachment record
    attachment = Attachment(
        filename=file.filename,
        file_path=file_path,
        file_size=file_size,
        content_type=file.content_type,
        task_id=task_id
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)

    return attachment


@router.get("/{attachment_id}/download")
def download_attachment(
    task_id: int,
    attachment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Get a download URL for an attachment.

    For S3: Returns a pre-signed URL (temporary, secure access)
    For local: Redirects to the file serving endpoint
    """
    attachment = db.query(Attachment).filter(
        Attachment.id == attachment_id,
        Attachment.task_id == task_id
    ).first()

    if not attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Attachment not found"
        )

    storage = get_storage()
    download_url = storage.get_download_url(attachment.file_path)

    if settings.USE_S3:
        # Redirect to S3 pre-signed URL
        return RedirectResponse(url=download_url)
    else:
        # For local storage, return the URL
        return {"download_url": download_url, "filename": attachment.filename}


@router.delete("/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_attachment(
    task_id: int,
    attachment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Delete an attachment from a task."""
    attachment = db.query(Attachment).filter(
        Attachment.id == attachment_id,
        Attachment.task_id == task_id
    ).first()

    if not attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Attachment not found"
        )

    # Delete file from storage
    storage = get_storage()
    storage.delete_file(attachment.file_path)

    # Delete database record
    db.delete(attachment)
    db.commit()
