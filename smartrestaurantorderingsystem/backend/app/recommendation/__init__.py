"""Recommendation engine package."""

from app.recommendation.engine import (
    RecommendationEngine,
    PreferenceProfile,
    RecommendedItem,
)
from app.recommendation.collaborative import CollaborativeEngine
from app.recommendation.fallback import PopularityEngine
from app.recommendation.service import RecommendationService

__all__ = [
    "RecommendationEngine",
    "PreferenceProfile",
    "RecommendedItem",
    "CollaborativeEngine",
    "PopularityEngine",
    "RecommendationService",
]
