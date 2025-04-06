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
