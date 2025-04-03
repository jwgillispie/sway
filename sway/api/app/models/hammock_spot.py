# api/app/models/hammock_spot.py
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from beanie import Document, Link
from enum import Enum


class Coordinates(BaseModel):
    latitude: float
    longitude: float


class TreeType(str, Enum):
    PINE = "pine"
    OLIVE = "olive"
    PALM = "palm"
    CAROB = "carob"
    CYPRESS = "cypress"
    OTHER = "other"
    STRUCTURE = "structure"  # For non-tree hammock spots


class Amenities(BaseModel):
    restrooms: bool = False
    water_source: bool = False
    shade: bool = False
    parking: bool = False
    food_nearby: bool = False
    swimming: bool = False


class Rating(BaseModel):
    view: float = 0  # 1-5
    comfort: float = 0  # 1-5
    accessibility: float = 0  # 1-5
    privacy: float = 0  # 1-5
    overall: float = 0  # 1-5


class Review(Document):
    spot_id: str
    user_id: str
    username: str
    rating: Rating
    comment: Optional[str] = None
    photos: List[str] = []  # URLs to Firebase Storage
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None


class HammockSpot(Document):
    name: str
    description: Optional[str] = None
    coordinates: Coordinates
    tree_types: List[TreeType] = []
    distance_between_trees: Optional[float] = None  # in meters
    amenities: Amenities = Field(default_factory=Amenities)
    photos: List[str] = []  # URLs to Firebase Storage
    creator_id: str
    is_private: bool = False  # Whether this is on private property
    is_verified: bool = False  # Admin-verified location
    avg_rating: float = 0
    reviews: List[Link[Review]] = []
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None


class User(Document):
    firebase_uid: str
    username: str
    email: str
    profile_photo: Optional[str] = None
    bio: Optional[str] = None
    favorite_spots: List[str] = []  # HammockSpot IDs
    created_spots: List[str] = []  # HammockSpot IDs
    is_premium: bool = False
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None