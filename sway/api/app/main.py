# api/app/main.py
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient

# Import models and routers
from models import HammockSpot, User, Review
from routes.spots import spot_router
from routes.users import user_router
from routes.reviews import review_router

# Create FastAPI app
app = FastAPI(
    title="Hammock Spots API",
    description="API for finding perfect hammock spots",
    version="1.0.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development - restrict in production
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
        raise HTTPException(status_code=500, detail="Database connection failed")


@app.get("/")
async def root():
    """Root endpoint for health check"""
    return {"message": "Welcome to Hammock Spots API!", "status": "online"}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )