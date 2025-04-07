from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from typing import List

from core.auth import verify_token
from database.connection import get_db_connection
from models.spending_models import Spending, SpendingCreate, SpendingSummary

# ✅ 전체 태그 명시: Swagger UI에 "Spending"으로 정리
router = APIRouter(tags=["Spending"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/login/token")


# ✅ 소비 내역 등록
@router.post("/spending")
async def add_spending(spending: SpendingCreate, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO spending (user_id, category, amount, memo, date)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (user_id, spending.category, spending.amount, spending.memo, spending.date)
    )

    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "소비 내역 등록 완료!"}


# ✅ 특정 날짜의 소비 내역 조회
@router.get("/spending", response_model=List[Spending])
async def get_spending_by_date(date: str, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        """
        SELECT * FROM spending
        WHERE user_id = %s AND date = %s
        ORDER BY created_at DESC
        """,
        (user_id, date)
    )
    result = cursor.fetchall()
    cursor.close()
    conn.close()

    return result


# ✅ 날짜별 소비 총액 조회 (캘린더 색상 표현용 등)
@router.get("/spending-summary", response_model=List[SpendingSummary])
async def get_spending_summary(token: str = Depends(oauth2_scheme)):
    print("✅ /spending-summary 라우트 진입 성공!")
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT DATE(date) as date, SUM(amount) as total_amount
        FROM spending
        WHERE user_id = %s
        GROUP BY DATE(date)
        ORDER BY date
    """, (user_id,))

    result = cursor.fetchall()
    cursor.close()
    conn.close()

    return result
