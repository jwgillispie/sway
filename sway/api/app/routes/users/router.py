# app/routes/users/router.py
from fastapi import APIRouter, Depends, HTTPException, Body, File, UploadFile
from typing import List, Optional
from bson.objectid import ObjectId
from app.models.user import User
from app.models.hammock_spot import HammockSpot
from app.dependencies.auth import get_current_user, upload_file_to_firebase

# Initialize router
user_router = APIRouter(prefix="/users", tags=["users"])


@user_router.get("/me", response_model=dict)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """Get the current user's profile"""
    return current_user.to_response_model()


@user_router.put("/me", response_model=dict)
async def update_user_profile(
    profile_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update the current user's profile"""
    # Filter allowed fields
    allowed_fields = ["username", "bio"]
    
    for field in allowed_fields:
        if field in profile_update:
            setattr(current_user, field, profile_update[field])
    
    # Save changes
    await current_user.save()
    
    return current_user.to_response_model()


@user_router.post("/me/profile-photo", response_model=dict)
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload a profile photo"""
    # Upload photo to Firebase
    file_content = await file.read()
    path = f"profile_photos/{current_user.id}/{ObjectId()}"
    url = await upload_file_to_firebase(
        file_content, 
        path, 
        file.content_type or "image/jpeg"
    )
    
    # Update user profile
    current_user.profile_photo = url
    await current_user.save()
    
    return {"url": url}


@user_router.post("/favorites/{spot_id}")
async def add_favorite(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Add a spot to user's favorites"""
    # Verify spot exists
    spot = await HammockSpot.get(spot_id)
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found")
    
    # Add to favorites if not already there
    if current_user.favorite_spots is None:
        current_user.favorite_spots = []
        
    if spot_id not in current_user.favorite_spots:
        current_user.favorite_spots.append(spot_id)
        await current_user.save()
    
    return {"message": "Spot added to favorites"}


@user_router.delete("/favorites/{spot_id}")
async def remove_favorite(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Remove a spot from user's favorites"""
    # Check if in favorites
    if current_user.favorite_spots and spot_id in current_user.favorite_spots:
        current_user.favorite_spots.remove(spot_id)
        await current_user.save()
    
    return {"message": "Spot removed from favorites"}


@user_router.get("/favorites", response_model=List[dict])
async def get_favorites(
    current_user: User = Depends(get_current_user)
):
    """Get user's favorite spots"""
    if not current_user.favorite_spots:
        return []
    
    favorites = []
    for spot_id in current_user.favorite_spots:
        try:
            spot = await HammockSpot.get(spot_id)
            if spot:
                favorites.append(spot.to_response_model())
        except:
            # Skip spots that couldn't be found
            pass
    
    return favorites


@user_router.get("/spots", response_model=List[dict])
async def get_user_spots(
    current_user: User = Depends(get_current_user)
):
    """Get spots created by the current user"""
    if not current_user.created_spots:
        return []
    
    user_spots = []
    for spot_id in current_user.created_spots:
        try:
            spot = await HammockSpot.get(spot_id)
            if spot:
                user_spots.append(spot.to_response_model())
        except:
            # Skip spots that couldn't be found
            pass
    
    return user_spots