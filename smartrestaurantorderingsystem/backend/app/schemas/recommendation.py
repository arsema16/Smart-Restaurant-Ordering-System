from pydantic import BaseModel


class RecommendedItem(BaseModel):
    menu_item_id: int
    name: str
    category: str
    price: float
    score: float
    reason: str

    class Config:
        from_attributes = True


class RecommendationResponse(BaseModel):
    recommendations: list[RecommendedItem]
    based_on_history: bool
