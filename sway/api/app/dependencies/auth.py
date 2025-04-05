# api/app/dependencies/auth.py
import firebase_admin
from firebase_admin import credentials, auth, storage
import os
from fastapi import HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from models import User

# Initialize Firebase with service account
# cred = credentials.Certificate("/Users/jordangillispie/development/sway/sway/sway/sway-6f710-firebase-adminsdk-fbsvc-79fde50652.json")
cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "/app/firebase-credentials.json")
cred = credentials.Certificate(cred_path)
firebase_app = firebase_admin.initialize_app(cred, {
    'storageBucket': 'sway-6f710.appspot.com'
})

# Initialize Firebase Storage
bucket = storage.bucket()

# Security utilities
security = HTTPBearer()


async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify Firebase ID token"""
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"Invalid authentication credentials: {str(e)}"
        )


async def get_current_user(token_data: dict = Depends(verify_token)):
    """Get current user document based on Firebase UID"""
    try:
        # Find user in MongoDB by firebase_uid
        user = await User.find_one({"firebase_uid": token_data["uid"]})
        
        if not user:
            # Create new user if not found
            firebase_user = auth.get_user(token_data["uid"])
            user = User(
                firebase_uid=token_data["uid"],
                email=firebase_user.email,
                username=firebase_user.display_name or "User",
                profile_photo=firebase_user.photo_url
            )
            await user.insert()
        
        return user
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving user: {str(e)}"
        )


async def upload_file_to_firebase(file_data: bytes, path: str, content_type: str):
    """Upload a file to Firebase Storage"""
    blob = bucket.blob(path)
    blob.upload_from_string(
        file_data,
        content_type=content_type
    )
    blob.make_public()
    return blob.public_url