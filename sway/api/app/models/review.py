# app/models/review.py
from datetime import datetime
from typing import List, Optional
from pydantic import Field
from beanie import Document, Link
from .hammock_spot import Rating

class Review(Document):
    spot_id: str = Field(..., description="ID of the HammockSpot being reviewed")
    user_id: str = Field(..., description="ID of the user who created the review")
    username: str = Field(..., description="Username of the reviewer")
    rating: Rating = Field(..., description="User's rating for this spot")
    comment: Optional[str] = Field(default=None, description="Review comment")
    photos: List[str] = Field(default_factory=list, description="URLs to Firebase Storage for review photos")
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None

    class Settings:
        name = "reviews"
    
    def to_response_model(self) -> dict:
        """Convert to a dictionary that can be used in API responses"""
        return {
            "id": str(self.id),  # Convert ObjectId to string
            "spot_id": self.spot_id,
            "user_id": self.user_id,
            "username": self.username,
            "rating": self.rating.dict(),
            "comment": self.comment,
            "photos": self.photos,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }

    class Config:
        schema_extra = {
            "example": {
                "spot_id": "60d21b4667d0d8992e610c85",
                "user_id": "60d21b4667d0d8992e610c86",
                "username": "hammock_lover",
                "rating": {
                    "view": 4.5,
                    "comfort": 5.0,
                    "accessibility": 3.5,
                    "privacy": 4.0,
                    "overall": 4.2
                },
                "comment": "This spot has an amazing view of the sunset. Trees are perfectly spaced for hanging a hammock.",
                "photos": [
                    "https://storage.googleapis.com/sway-app.appspot.com/review_photos/review123_1.jpg",
                    "https://storage.googleapis.com/sway-app.appspot.com/review_photos/review123_2.jpg"
                ],
                "created_at": "2023-06-21T09:30:45.123Z",
                "updated_at": None
            }
        }