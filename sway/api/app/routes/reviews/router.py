# app/routes/reviews/router.py
from fastapi import APIRouter, Depends, HTTPException, Body, File, UploadFile, Form
from typing import List, Optional
import json
from bson.objectid import ObjectId
from app.models.review import Review
from app.models.hammock_spot import HammockSpot, Rating
from app.models.user import User
from app.dependencies.auth import get_current_user, upload_file_to_firebase

# Initialize router
review_router = APIRouter(prefix="/reviews", tags=["reviews"])


@review_router.post("/{spot_id}", response_model=dict)
async def create_review(
    spot_id: str,
    view_rating: float = Form(..., ge=1, le=5),
    comfort_rating: float = Form(..., ge=1, le=5),
    accessibility_rating: float = Form(..., ge=1, le=5),
    privacy_rating: float = Form(..., ge=1, le=5),
    comment: Optional[str] = Form(None),
    photos: List[UploadFile] = File([]),
    current_user: User = Depends(get_current_user)
):
    """Create a review for a hammock spot"""
    # Verify spot exists
    spot = await HammockSpot.get(spot_id)
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found")
    
    # Check if user already reviewed this spot
    existing_review = await Review.find_one({
        "spot_id": spot_id,
        "user_id": str(current_user.id)
    })
    
    if existing_review:
        raise HTTPException(
            status_code=400, 
            detail="You have already reviewed this spot. Please update your existing review."
        )
    
    # Calculate overall rating
    overall_rating = (view_rating + comfort_rating + accessibility_rating + privacy_rating) / 4
    
    # Create Rating object
    rating = Rating(
        view=view_rating,
        comfort=comfort_rating,
        accessibility=accessibility_rating,
        privacy=privacy_rating,
        overall=overall_rating
    )
    
    # Upload photos if any
    photo_urls = []
    for i, photo in enumerate(photos):
        if photo.filename:
            file_content = await photo.read()
            path = f"review_photos/{spot_id}/{current_user.id}/{ObjectId()}-{i}"
            url = await upload_file_to_firebase(
                file_content, 
                path, 
                photo.content_type or "image/jpeg"
            )
            photo_urls.append(url)
    
    # Create review
    review = Review(
        spot_id=spot_id,
        user_id=str(current_user.id),
        username=current_user.username,
        rating=rating,
        comment=comment,
        photos=photo_urls
    )
    
    # Save to database
    await review.insert()
    
    # Update spot's reviews and average rating
    if spot.reviews is None:
        spot.reviews = []
    
    spot.reviews.append(review)
    
    # Recalculate average rating
    total_rating = 0
    for r in spot.reviews:
        total_rating += r.rating.overall
    
    spot.avg_rating = total_rating / len(spot.reviews)
    
    # Save spot changes
    await spot.save()
    
    return review.to_response_model()


@review_router.get("/{review_id}", response_model=dict)
async def get_review(review_id: str):
    """Get a specific review by ID"""
    try:
        review = await Review.get(review_id)
        if not review:
            raise HTTPException(status_code=404, detail="Review not found")
        return review.to_response_model()
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Review not found: {str(e)}")


@review_router.put("/{review_id}", response_model=dict)
async def update_review(
    review_id: str,
    review_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update a review (author only)"""
    # Get review
    review = await Review.get(review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Check ownership
    if review.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to update this review")
    
    # Update rating if provided
    if "rating" in review_update:
        rating_data = review_update["rating"]
        
        # Calculate overall rating
        view = rating_data.get("view", review.rating.view)
        comfort = rating_data.get("comfort", review.rating.comfort)
        accessibility = rating_data.get("accessibility", review.rating.accessibility)
        privacy = rating_data.get("privacy", review.rating.privacy)
        overall = (view + comfort + accessibility + privacy) / 4
        
        review.rating = Rating(
            view=view,
            comfort=comfort,
            accessibility=accessibility,
            privacy=privacy,
            overall=overall
        )
    
    # Update comment if provided
    if "comment" in review_update:
        review.comment = review_update["comment"]
    
    # Save changes
    await review.save()
    
    # Update spot's average rating
    spot = await HammockSpot.get(review.spot_id)
    if spot:
        # Recalculate average rating
        total_rating = 0
        for r in spot.reviews:
            if str(r.id) == review_id:
                # Use updated rating
                total_rating += review.rating.overall
            else:
                total_rating += r.rating.overall
        
        spot.avg_rating = total_rating / len(spot.reviews)
        await spot.save()
    
    return review.to_response_model()


@review_router.delete("/{review_id}")
async def delete_review(
    review_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a review (author only)"""
    # Get review
    review = await Review.get(review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Check ownership
    if review.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to delete this review")
    
    # Get spot for updating ratings
    spot_id = review.spot_id
    spot = await HammockSpot.get(spot_id)
    
    # Delete review
    await review.delete()
    
    # Update spot's reviews and average rating
    if spot:
        # Remove review from spot
        spot.reviews = [r for r in spot.reviews if str(r.id) != review_id]
        
        # Recalculate average rating
        if spot.reviews:
            total_rating = sum(r.rating.overall for r in spot.reviews)
            spot.avg_rating = total_rating / len(spot.reviews)
        else:
            spot.avg_rating = 0
        
        await spot.save()
    
    return {"message": "Review deleted successfully"}


@review_router.post("/{review_id}/photos")
async def upload_review_photo(
    review_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload a photo for a review"""
    # Get review
    review = await Review.get(review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Check ownership
    if review.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to add photos to this review")
    
    # Upload photo
    file_content = await file.read()
    path = f"review_photos/{review.spot_id}/{current_user.id}/{ObjectId()}"
    url = await upload_file_to_firebase(
        file_content, 
        path, 
        file.content_type or "image/jpeg"
    )
    
    # Add to review's photos
    if review.photos is None:
        review.photos = []
    
    review.photos.append(url)
    await review.save()
    
    return {"url": url}