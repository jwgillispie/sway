# app/dependencies/database.py
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
import os
from fastapi import HTTPException
from ..models.hammock_spot import HammockSpot
from ..models.user import User
from ..models.review import Review

# Database client instances
db_client = None
db = None

async def get_database():
    """Get database connection."""
    return db

async def connect_to_mongodb():
    """Connect to MongoDB and initialize Beanie ODM."""
    global db_client, db
    
    mongodb_url = os.getenv("MONGODB_URL", "mongodb://mongo:27017/hammock_spots")
    
    try:
        # Connect to MongoDB
        db_client = AsyncIOMotorClient(mongodb_url)
        db = db_client.get_default_database()
        
        # Initialize Beanie with the document models
        await init_beanie(
            database=db,
            document_models=[HammockSpot, User, Review]
        )
        
        print("Connected to MongoDB!")
        return db
    except Exception as e:
        print(f"Failed to connect to MongoDB: {e}")
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

async def close_mongodb_connection():
    """Close MongoDB connection."""
    global db_client
    
    if db_client:
        db_client.close()
        print("MongoDB connection closed.")

# Get database client
async def get_db_client():
    """Get database client."""
    if db_client is None:
        await connect_to_mongodb()
    return db_client