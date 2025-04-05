# app/routes/__init__.py
from .spots.router import spot_router
from .users.router import user_router
from .reviews.router import review_router

__all__ = ['spot_router', 'user_router', 'review_router']