from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel

# ✅ 소비 내역 등록용 모델
class SpendingCreate(BaseModel):
    category: str
    amount: int
    memo: Optional[str] = None
    date: date

# ✅ 소비 내역 조회용 모델
class Spending(BaseModel):
    spending_id: int
    user_id: int
    category: str
    amount: int
    memo: Optional[str] = None
    date: date
    created_at: Optional[datetime] = None


# ✅ 날짜별 총 소비 금액 모델 (캘린더 색 표현용 등)
class SpendingSummary(BaseModel):
    date: date
    total_amount: int

# ✅ 카테고리별 소비 집계 모델
class SpendingCategorySummary(BaseModel):
    category: str
    total: int


#소비 목표 설정모델

class GoalCreate(BaseModel):
    goal_amount: int
    month: str  # "2025-04" 이런 식으로

class GoalRead(BaseModel):
    month: str
    goal_amount: int