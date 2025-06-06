from fastapi import APIRouter
from pydantic import BaseModel, Field
from typing import Optional

router = APIRouter()

# ✅ 월별 소비 데이터 모델 (한글 alias 사용)
class MonthSpending(BaseModel):
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
        extra = "allow"

# ✅ 분석 API 입력 포맷
class SpendingInput(BaseModel):
    this_month: MonthSpending
    last_month: MonthSpending

    class Config:
        populate_by_name = True
        extra = "allow"

# ✅ 소비 항목 변화 분석 API
@router.post("/analyze-spending", tags=["Analysis"])
async def analyze_spending(input_data: SpendingInput):
    # alias 기준으로 dict 변환
    this = input_data.this_month.dict(by_alias=True)
    last = input_data.last_month.dict(by_alias=True)

    # 가장 많이 소비된 항목 찾기
    top_category = max(this, key=this.get)
    top_value = this[top_category]
    last_value = last.get(top_category, 0)

    # 변화율 계산
    change = top_value - last_value
    change_percent = f"{change * 100:+.1f}%"

    # 결과 메시지 구성
    comment = (
        f"📊 이번 달에는 '{top_category}' 분야에 소비가 가장 많았습니다.\n"
        f"🔮 다음 달에도 '{top_category}' 소비가 높을 가능성이 있습니다."
    )

    return {
        "top_category": top_category,
        "comment": comment,
        "change_from_last_month": change_percent
    }
