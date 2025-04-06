# app/main.py
from fastapi import FastAPI
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient
import os
from fastapi.middleware.cors import CORSMiddleware

# Import models and routers
from app.models.hammock_spot import HammockSpot
from app.models.user import User
from app.models.review import Review
from app.routes.spots.router import spot_router
from app.routes.users.router import user_router
from app.routes.reviews.router import review_router

# Create FastAPI app
app = FastAPI(
    title="Hammock Spots API",
    description="API for finding perfect hammock spots",
    version="1.0.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Your Firebase hosting URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(spot_router)
app.include_router(user_router)
app.include_router(review_router)

@app.on_event("startup")
async def startup_db_client():
    """Initialize database connection and Beanie ODM"""
    mongodb_url = os.getenv("MONGODB_URL", "mongodb://localhost:27017/hammock_spots")
    
    try:
        # Connect to MongoDB
        client = AsyncIOMotorClient(mongodb_url)
        
        # Initialize Beanie with the document models
        await init_beanie(
            database=client.get_default_database(),
            document_models=[HammockSpot, User, Review]
        )
        
        print("Connected to MongoDB!")
    except Exception as e:
        print(f"Failed to connect to MongoDB: {e}")
        raise

@app.get("/")
async def root():
    """Root endpoint for health check"""
    return {"message": "Welcome to Hammock Spots API!", "status": "online"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}