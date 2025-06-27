import numpy as np
import os
import pickle
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from ml.predictor import predict_category

router = APIRouter()

# ✅ 경로 설정
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "model_data", "total_spending_predictor.pkl")

# ✅ 모델 로드
with open(MODEL_PATH, 'rb') as f:
    reg_model, feature_order = pickle.load(f)

# ✅ 한글 키 변환 (for 피드백 메시지용)
def to_korean_keys(data: dict) -> dict:
    key_map = {
        "food": "식비",
        "transport": "교통",
        "culture": "문화",
        "health": "의료",
        "housing": "주거",
        "shopping": "쇼핑",
        "education": "교육",
        "etc": "기타"
    }
    return {key_map.get(k, k): v for k, v in data.items()}

# ✅ 피드백 생성
def generate_habit_feedback(data: dict) -> str:
    # data는 이미 한글 키로 변환된 상태
    feedback = []

    if data.get("식비", 0) > 0.35:
        feedback.append("🍽️ 식비 지출이 전체 소비의 35%를 초과했습니다. 식비 절약을 고려해보세요.")
    elif data.get("식비", 0) < 0.25:
        feedback.append("👍 식비를 잘 관리하고 계시네요.")

    if data.get("문화", 0) > 0.2:
        feedback.append("🎭 문화 소비가 많아요. 이벤트성 지출은 계획적으로 관리해보세요.")

    if data.get("쇼핑", 0) > 0.15:
        feedback.append("🛍️ 쇼핑 항목이 다소 높습니다. 불필요한 소비를 줄일 수 있어요.")

    if data.get("교통", 0) < 0.1:
        feedback.append("🚆 교통비가 평균보다 낮습니다. 좋은 소비 습관이에요.")

    if data.get("의료", 0) > 0.1:
        feedback.append("⚕️ 의료비가 일시적으로 많았을 수 있습니다. 추세를 지켜보세요.")

    return " ".join(feedback) if feedback else "소비 항목 간 균형이 잘 잡혀 있습니다. 계속 유지하세요!"

# ✅ 총 소비 예측용 모델 입력
class SpendingRatio(BaseModel):
    food: float
    transport: float
    culture: float
    health: float
    housing: float

# ✅ 총 소비 예측 API
@router.post("/predict-total", tags=["Prediction"])
async def predict_total_spending(input_data: SpendingRatio):
    data = input_data.dict()
    X = np.array([[data.get(feat, 0) for feat in feature_order]])
    predicted = reg_model.predict(X)[0]

    # 영향 해석 (한글 키 변환 후 분석)
    korean_data = to_korean_keys(data)

    insights = []
    if korean_data.get("식비", 0) > 0.3:
        insights.append("식비 소비가 높아 전체 소비액이 상승한 것으로 보입니다.")
    if korean_data.get("문화", 0) > 0.2:
        insights.append("문화 소비가 일시적으로 증가했을 수 있습니다.")
    if korean_data.get("의료", 0) > 0.1:
        insights.append("의료비 지출은 예외적일 수 있으므로 주의가 필요합니다.")
    if korean_data.get("교통", 0) < 0.1:
        insights.append("교통비는 평소보다 낮은 편입니다.")

    feedback = " ".join(insights) if insights else "소비 항목은 전반적으로 안정적입니다."
    comment = f"💰 다음 달 예상 총 소비액은 약 {predicted:.1f}만원입니다.\n📝 {feedback}"

    return {
        "predicted_total": round(predicted, 1),
        "feedback": feedback,
        "message": comment
    }

# 주요 소비 카테고리 예측용 모델 입력
class InputSpending(BaseModel):
    food: float
    transport: float
    culture: float
    health: float
    housing: float = 0
    shopping: Optional[float] = 0
    education: Optional[float] = 0
    etc: Optional[float] = 0

# 주요 소비 카테고리 예측 API
@router.post("/predict-next-month", tags=["Prediction"])
async def predict_next_category(input_data: InputSpending):
    parsed = input_data.dict()
    korean_data = to_korean_keys(parsed)
    result = predict_category(parsed)
    habit_feedback = generate_habit_feedback(korean_data)

    return {
        "predicted_category": result["prediction"],
        "confidence": result["confidence"],
        "top_3_predictions": result["top_3"],
        "message": f"🔮 다음 달에는 '{result['prediction']}' 분야의 소비가 가장 많을 것으로 예상됩니다.",
        "feedback": habit_feedback
    }
