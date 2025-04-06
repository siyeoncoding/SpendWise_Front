from pydantic import BaseModel
from datetime import date
from typing import Optional

class Spending(BaseModel):
    category: str
    amount: int
    memo: Optional[str] = None
    date: date
