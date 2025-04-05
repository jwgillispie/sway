# app/utils/firebase/auth.py
import firebase_admin
from firebase_admin import credentials, auth
import os
from fastapi import HTTPException

# Initialize Firebase Admin SDK if not already initialized
def initialize_firebase():
    """Initialize Firebase Admin SDK if not already initialized"""
    try:
        # Check if already initialized
        firebase_admin.get_app()
    except ValueError:
        # Not initialized, so initialize
        cred_path = os.getenv("FIREBASE_CREDENTIALS", "/app/firebase-credentials.json")
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred, {
            'storageBucket': os.getenv('FIREBASE_STORAGE_BUCKET', 'sway-6f710.appspot.com')
        })

def verify_firebase_token(token: str):
    """
    Verify Firebase ID token and return decoded token
    
    Args:
        token: Firebase ID token
        
    Returns:
        dict: Decoded token data
        
    Raises:
        HTTPException: If token is invalid
    """
    try:
        # Initialize Firebase if not already
        initialize_firebase()
        
        # Verify token
        decoded_token = auth.verify_id_token(token)
        
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication credentials: {str(e)}"
        )

def get_firebase_user(uid: str):
    """
    Get Firebase user by UID
    
    Args:
        uid: Firebase UID
        
    Returns:
        dict: User data
        
    Raises:
        HTTPException: If user not found
    """
    try:
        # Initialize Firebase if not already
        initialize_firebase()
        
        # Get user
        user = auth.get_user(uid)
        
        return user
    except Exception as e:
        raise HTTPException(
            status_code=404,
            detail=f"User not found: {str(e)}"
        )