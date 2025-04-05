# app/dependencies/auth.py
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from datetime import datetime
from app.models.user import User
from app.utils.firebase import verify_firebase_token, get_firebase_user, upload_file_to_storage

# Security utilities
security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify Firebase ID token and return decoded token data"""
    token = credentials.credentials
    return verify_firebase_token(token)

async def get_current_user(token_data: dict = Depends(verify_token)):
    """Get current user document based on Firebase UID"""
    try:
        # Find user in MongoDB by firebase_uid
        user = await User.find_one({"firebase_uid": token_data["uid"]})
        
        if not user:
            # Create new user if not found
            firebase_user = get_firebase_user(token_data["uid"])
            
            user = User(
                firebase_uid=token_data["uid"],
                email=firebase_user.email or "",
                username=firebase_user.display_name or f"user_{token_data['uid'][:8]}",
                profile_photo=firebase_user.photo_url,
                created_at=datetime.now()
            )
            
            await user.insert()
        
        return user
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving user: {str(e)}"
        )

async def upload_file_to_firebase(file_data: bytes, path: str, content_type: str = "image/jpeg"):
    """Upload a file to Firebase Storage and return the public URL"""
    return upload_file_to_storage(file_data, path, content_type)