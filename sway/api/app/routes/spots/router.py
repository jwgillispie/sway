# app/routes/spots/router.py
from fastapi import APIRouter, Depends, HTTPException, Query, Body, File, UploadFile, Form
from typing import List, Optional
import json
from bson.objectid import ObjectId
from app.models.hammock_spot import HammockSpot, TreeType, Coordinates, Amenities
from app.models.review import Review
from app.models.user import User
from app.dependencies.auth import get_current_user, upload_file_to_firebase

# Initialize router
spot_router = APIRouter(prefix="/spots", tags=["spots"])


@spot_router.get("/", response_model=List[dict])
async def get_spots(
    lat: Optional[float] = Query(None, description="Latitude coordinate for center of search"),
    lng: Optional[float] = Query(None, description="Longitude coordinate for center of search"),
    radius: Optional[float] = Query(5000.0, description="Search radius in meters"),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of results to return"),
    tree_type: Optional[str] = Query(None, description="Filter by tree type"),
    min_rating: Optional[float] = Query(None, description="Minimum average rating"),
    has_amenity: Optional[List[str]] = Query(None, description="Filter by amenities"),
    current_user: User = Depends(get_current_user)
):
    """
    Get hammock spots with optional filtering by location, ratings, and amenities.
    If lat and lng are provided, returns spots within the specified radius.
    """
    query = {}
    
    # Add location-based filtering if coordinates are provided
    if lat is not None and lng is not None:
        # Use MongoDB geospatial query with $nearSphere
        # First ensure there's a geospatial index on the coordinates field
        query["location"] = {
            "$nearSphere": {
                "$geometry": {
                    "type": "Point",
                    "coordinates": [lng, lat]  # Note: GeoJSON format is [longitude, latitude]
                },
                "$maxDistance": radius
            }
        }
    
    # Add tree type filter
    if tree_type:
        query["tree_types"] = tree_type
    
    # Add rating filter
    if min_rating is not None:
        query["avg_rating"] = {"$gte": min_rating}
    
    # Add amenities filter
    if has_amenity:
        for amenity in has_amenity:
            query[f"amenities.{amenity}"] = True
    
    # Execute query
    spots = await HammockSpot.find(query).limit(limit).to_list()
    
    # Convert to response format
    return [spot.to_response_model() for spot in spots]


@spot_router.post("/", response_model=dict)
async def create_spot(
    name: str = Form(...),
    description: Optional[str] = Form(None),
    latitude: float = Form(...),
    longitude: float = Form(...),
    tree_types: str = Form(...),  # JSON string array of tree types
    distance_between_trees: Optional[float] = Form(None),
    amenities: str = Form(...),  # JSON object with amenity booleans
    is_private: bool = Form(False),
    photos: List[UploadFile] = File([]),
    current_user: User = Depends(get_current_user)
):
    """Create a new hammock spot"""
    # Parse JSON strings
    try:
        tree_types_list = json.loads(tree_types)
        amenities_dict = json.loads(amenities)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON format for tree_types or amenities")
    
    # Validate tree types
    valid_tree_types = []
    for tt in tree_types_list:
        try:
            valid_tree_types.append(TreeType(tt))
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid tree type: {tt}")
    
    # Create coordinates
    coordinates = Coordinates(latitude=latitude, longitude=longitude)
    
    # Create amenities object
    amenities_obj = Amenities(
        restrooms=amenities_dict.get("restrooms", False),
        water_source=amenities_dict.get("water_source", False),
        shade=amenities_dict.get("shade", False),
        parking=amenities_dict.get("parking", False),
        food_nearby=amenities_dict.get("food_nearby", False),
        swimming=amenities_dict.get("swimming", False)
    )
    
    # Upload photos if any
    photo_urls = []
    for i, photo in enumerate(photos):
        if photo.filename:
            file_content = await photo.read()
            path = f"spot_photos/{current_user.id}/{ObjectId()}-{i}"
            url = await upload_file_to_firebase(
                file_content, 
                path, 
                photo.content_type or "image/jpeg"
            )
            photo_urls.append(url)
    
    # Create spot
    spot = HammockSpot(
        name=name,
        description=description,
        coordinates=coordinates,
        tree_types=valid_tree_types,
        distance_between_trees=distance_between_trees,
        amenities=amenities_obj,
        photos=photo_urls,
        creator_id=str(current_user.id),
        creator_username=current_user.username,
        is_private=is_private
    )
    
    # Save to database
    await spot.insert()
    
    # Update user's created spots
    if current_user.created_spots is None:
        current_user.created_spots = []
    current_user.created_spots.append(str(spot.id))
    await current_user.save()
    
    return spot.to_response_model()


@spot_router.get("/{spot_id}", response_model=dict)
async def get_spot(spot_id: str):
    """Get a specific hammock spot by ID"""
    try:
        spot = await HammockSpot.get(spot_id)
        if not spot:
            raise HTTPException(status_code=404, detail="Spot not found")
        return spot.to_response_model()
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Spot not found: {str(e)}")


@spot_router.put("/{spot_id}", response_model=dict)
async def update_spot(
    spot_id: str,
    spot_update: dict = Body(...),
    current_user: User = Depends(get_current_user)
):
    """Update a hammock spot (creator only)"""
    spot = await HammockSpot.get(spot_id)
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found")
    
    # Check ownership
    if str(spot.creator_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to update this spot")
    
    # Update allowed fields
    allowed_fields = [
        "name", "description", "coordinates", "tree_types", 
        "distance_between_trees", "amenities", "is_private"
    ]
    
    for field in allowed_fields:
        if field in spot_update:
            # Special handling for nested fields
            if field == "coordinates" and spot_update.get("coordinates"):
                coords_data = spot_update["coordinates"]
                spot.coordinates = Coordinates(
                    latitude=coords_data.get("latitude", spot.coordinates.latitude),
                    longitude=coords_data.get("longitude", spot.coordinates.longitude)
                )
            elif field == "amenities" and spot_update.get("amenities"):
                amenities_data = spot_update["amenities"]
                spot.amenities = Amenities(
                    restrooms=amenities_data.get("restrooms", spot.amenities.restrooms),
                    water_source=amenities_data.get("water_source", spot.amenities.water_source),
                    shade=amenities_data.get("shade", spot.amenities.shade),
                    parking=amenities_data.get("parking", spot.amenities.parking),
                    food_nearby=amenities_data.get("food_nearby", spot.amenities.food_nearby),
                    swimming=amenities_data.get("swimming", spot.amenities.swimming)
                )
            elif field == "tree_types" and spot_update.get("tree_types"):
                # Convert string tree types to enum values
                try:
                    spot.tree_types = [TreeType(tt) for tt in spot_update["tree_types"]]
                except ValueError as e:
                    raise HTTPException(status_code=400, detail=f"Invalid tree type: {str(e)}")
            else:
                setattr(spot, field, spot_update[field])
    
    # Handle photos separately if needed
    # This would require file upload handling similar to the create endpoint
    
    # Save changes
    await spot.save()
    
    return spot.to_response_model()


@spot_router.delete("/{spot_id}")
async def delete_spot(
    spot_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a hammock spot (creator only)"""
    spot = await HammockSpot.get(spot_id)
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found")
    
    # Check ownership
    if str(spot.creator_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to delete this spot")
    
    # Delete the spot
    await spot.delete()
    
    # Remove from user's created spots
    if spot_id in current_user.created_spots:
        current_user.created_spots.remove(spot_id)
        await current_user.save()
    
    return {"message": "Spot deleted successfully"}


@spot_router.post("/{spot_id}/photos")
async def upload_spot_photo(
    spot_id: str,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload a photo for a hammock spot"""
    spot = await HammockSpot.get(spot_id)
    if not spot:
        raise HTTPException(status_code=404, detail="Spot not found")
    
    # Check ownership
    if str(spot.creator_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="You don't have permission to add photos to this spot")
    
    # Upload photo
    file_content = await file.read()
    path = f"spot_photos/{current_user.id}/{ObjectId()}"
    url = await upload_file_to_firebase(
        file_content, 
        path, 
        file.content_type or "image/jpeg"
    )
    
    # Add to spot's photos
    if spot.photos is None:
        spot.photos = []
    spot.photos.append(url)
    await spot.save()
    
    return {"url": url}