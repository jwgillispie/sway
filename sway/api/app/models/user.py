# app/models/user.py
from datetime import datetime
from typing import List, Optional
from pydantic import Field
from beanie import Document

class User(Document):
    firebase_uid: str = Field(..., description="Firebase User ID")
    username: str = Field(..., description="User's display name")
    email: str = Field(..., description="User's email address")
    profile_photo: Optional[str] = Field(default=None, description="URL to profile photo in Firebase Storage")
    bio: Optional[str] = Field(default=None, description="User's bio or description")
    favorite_spots: List[str] = Field(default_factory=list, description="List of favorite HammockSpot IDs")
    created_spots: List[str] = Field(default_factory=list, description="List of HammockSpot IDs created by user")
    is_premium: bool = Field(default=False, description="Whether user has premium subscription")
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None

    class Settings:
        name = "users"
        
    def to_response_model(self) -> dict:
        """Convert to a dictionary that can be used in API responses"""
        return {
            "id": str(self.id),  # Convert ObjectId to string
            "firebase_uid": self.firebase_uid,
            "username": self.username,
            "email": self.email,
            "profile_photo": self.profile_photo,
            "bio": self.bio,
            "favorite_spots": self.favorite_spots,
            "created_spots": self.created_spots,
            "is_premium": self.is_premium,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }

    class Config:
        schema_extra = {
            "example": {
                "firebase_uid": "87h2f9a8sdf79a8s7f98a7sdf",
                "username": "hammock_lover",
                "email": "user@example.com",
                "profile_photo": "https://storage.googleapis.com/sway-app.appspot.com/profile_photos/user123.jpg",
                "bio": "Avid hammock enthusiast exploring the best spots around the world.",
                "favorite_spots": ["60d21b4667d0d8992e610c85", "60d21b4667d0d8992e610c86"],
                "created_spots": ["60d21b4667d0d8992e610c87"],
                "is_premium": False,
                "created_at": "2023-06-20T14:23:05.123Z",
                "updated_at": None
            }
        }