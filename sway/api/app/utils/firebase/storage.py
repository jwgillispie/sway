# app/utils/firebase/storage.py
import firebase_admin
from firebase_admin import storage
import os
from fastapi import HTTPException
from .auth import initialize_firebase

def upload_file_to_storage(file_data: bytes, path: str, content_type: str = "image/jpeg"):
    """
    Upload a file to Firebase Storage
    
    Args:
        file_data: Raw file data
        path: Storage path
        content_type: MIME type
        
    Returns:
        str: Public URL of the uploaded file
        
    Raises:
        HTTPException: If upload fails
    """
    try:
        # Initialize Firebase if not already
        initialize_firebase()
        
        # Get bucket
        bucket = storage.bucket()
        
        # Create blob
        blob = bucket.blob(path)
        
        # Upload file
        blob.upload_from_string(
            file_data,
            content_type=content_type
        )
        
        # Make public
        blob.make_public()
        
        # Return public URL
        return blob.public_url
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload file: {str(e)}"
        )

def delete_file_from_storage(path: str):
    """
    Delete a file from Firebase Storage
    
    Args:
        path: Storage path
        
    Raises:
        HTTPException: If deletion fails
    """
    try:
        # Initialize Firebase if not already
        initialize_firebase()
        
        # Get bucket
        bucket = storage.bucket()
        
        # Delete blob
        blob = bucket.blob(path)
        blob.delete()
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to delete file: {str(e)}"
        )