# api/app/routes/router.py
from fastapi import APIRouter, Depends, HTTPException, Query, Body, File, UploadFile
from typing import List, Optional
from models import HammockSpot, User, Review, Coordinates
from firebase_admin import auth
from dependencies import get_current_user

# Initialize routers
spot_router = APIRouter(prefix="/spots", tags=["spots"])
user_router = APIRouter(prefix="/users", tags=["users"])
review_router = APIRouter(prefix="/reviews", tags=["reviews"])


# Spot endpoints
@spot_router.get("/", response_model=List[HammockSpot])
async def get_spots(
    lat: Optional[float] = Query(None),
    lng: Optional[float] = Query(None),
    radius: Optional[float] = Query(5000.0),  # Default 5km radius
    limit: int = Query(20, ge=1, le=100),
    tree_type: Optional[str] = Query(None),
    min_rating: Optional[float] = Query(None),
    has_amenity: Optional[List[str]] = Query(None),
    current_user: User = Depends(get_current_user)
):
    """
    Get hammock spots with optional filtering by location, ratings, and amenities.
    If lat and lng are provided, returns spots within the specified radius.
    """
    # Implementation will use MongoDB geospatial queries


@spot_router.post("/", response_model=HammockSpot)
async def create_spot(
    spot: HammockSpot,
    current_user: User = Depends(get_current_user)
):
    """Create a new hammock spot"""
    spot.creator_id = current_user.firebase_uid
    # Implementation will save to MongoDB and update user's created_spots


@spot_router.get("/{spot_id}", response_model=HammockSpot)
async def get_spot(spot_id: str):
    """Get a specific hammock spot by ID"""
    # Implementation will fetch from MongoDB


@spot_router.put("/{spot_id}", response_model=HammockSpot)
async def update_spot(
    spot_id: str,
    spot_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update a hammock spot (creator only)"""
    # Implementation will check ownership and update


@spot_router.delete("/{spot_id}")
async def delete_spot(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a hammock spot (creator only)"""
    # Implementation will check ownership and delete


@spot_router.post("/{spot_id}/photos")
async def upload_spot_photo(
    spot_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload a photo for a hammock spot"""
    # Implementation will check ownership, upload to Firebase Storage, and update spot


# User endpoints
@user_router.get("/me", response_model=User)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """Get the current user's profile"""
    return current_user


@user_router.put("/me", response_model=User)
async def update_user_profile(
    profile_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update the current user's profile"""
    # Implementation will validate and update user document


@user_router.post("/favorites/{spot_id}")
async def add_favorite(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Add a spot to user's favorites"""
    # Implementation will validate spot exists and update user's favorites


@user_router.delete("/favorites/{spot_id}")
async def remove_favorite(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Remove a spot from user's favorites"""
    # Implementation will update user's favorites


# Review endpoints
@review_router.post("/{spot_id}", response_model=Review)
async def create_review(
    spot_id: str,
    review: Review,
    current_user: User = Depends(get_current_user)
):
    """Create a review for a hammock spot"""
    # Implementation will create review and update spot's avg_rating


@review_router.put("/{review_id}", response_model=Review)
async def update_review(
    review_id: str,
    review_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update a review (author only)"""
    # Implementation will check ownership and update


@review_router.delete("/{review_id}")
async def delete_review(
    review_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a review (author only)"""
    # Implementation will check ownership and delete