# routers/predict_router.py

from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import Optional
from ml.predictor import predict_category

router = APIRouter()

class InputSpending(BaseModel):
    food: float = Field(..., alias="식비")
    transport: float = Field(..., alias="교통")
    culture: float = Field(..., alias="문화")
    health: float = Field(..., alias="의료")
    housing: float = Field(0, alias="주거")
    shopping: Optional[float] = Field(0, alias="쇼핑")
    education: Optional[float] = Field(0, alias="교육")
    etc: Optional[float] = Field(0, alias="기타")

    class Config:
        populate_by_name = True

# routers/predict_router.py

@router.post("/predict-next-month", tags=["Prediction"])
async def predict_next_category(input_data: InputSpending):
    result = predict_category(input_data.dict(by_alias=True))

    return {
        "predicted_category": result["prediction"],
        "confidence": result["confidence"],
        "top_3_predictions": result["top_3"],
        "message": f"🔮 다음 달에는 '{result['prediction']}' 분야의 소비가 가장 많을 것으로 예상됩니다."
    }

#git test