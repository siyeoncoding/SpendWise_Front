import datetime
from pydantic import BaseModel
from datetime import date
from typing import Optional


# 소비 내역 등록용 모델
class SpendingCreate(BaseModel):
    category: str
    amount: int
    memo: Optional[str] = None
    date: date


# 소비 내역 조회용 모델 (전체 필드 포함)
class Spending(BaseModel):
    spending_id: int
    user_id: int
    category: str
    amount: int
    memo: Optional[str] = None
    date: date
    created_at: datetime
