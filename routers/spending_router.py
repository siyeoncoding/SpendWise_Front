from fastapi import APIRouter, Depends, HTTPException
from core.auth import verify_token
from fastapi.security import OAuth2PasswordBearer
from database.connection import get_db_connection
from models.spending_models import Spending

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/login/token")

# 소비 내역 등록 API
@router.post("/spending")
async def add_spending(spending: Spending, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO spending (user_id, category, amount, memo, date) VALUES (%s, %s, %s, %s, %s)",
            (user_id, spending.category, spending.amount, spending.memo, spending.date)
        )
        conn.commit()
        return {"message": "소비 내역 등록 완료!"}
    finally:
        cursor.close()
        conn.close()

# 특정 날짜 소비 내역 조회 API
@router.get("/spending")
async def get_spending_by_date(date: str, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT id, category, amount, memo, date FROM spending WHERE user_id = %s AND date = %s",
            (user_id, date)
        )
        result = cursor.fetchall()
        spendings = [
            {
                "id": row[0],
                "category": row[1],
                "amount": row[2],
                "memo": row[3],
                "date": row[4].isoformat()
            }
            for row in result
        ]
        return {"spendings": spendings}
    finally:
        cursor.close()
        conn.close()
