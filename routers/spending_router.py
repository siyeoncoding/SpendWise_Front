from idlelib.query import Query
from pydoc import describe

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.security import OAuth2PasswordBearer
from typing import List

from core.auth import verify_token
from database.connection import get_db_connection
from models.spending_models import Spending, SpendingCreate, SpendingSummary, SpendingCategorySummary

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
@router.get("/spending-summary/daily", response_model=List[SpendingSummary])
async def get_spending_summary(token: str = Depends(oauth2_scheme)):
    print("체크용출력 /spending-summary 라우트 진입 성공!")
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

#✅ 한달 기준 날짜별 소비내역을 카테고리로 집계해야지
@router.get("/spending-summary/monthly", tags=["Spending"])
async def get_monthly_summary(
        month: str = Query(...),
        token: str = Depends(oauth2_scheme),
):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT category, SUM(amount) as total
        FROM spending
        WHERE user_id = %s AND DATE_FORMAT(date, '%Y-%m') = %s
        GROUP BY category
    """, (user_id, month))

    data = cursor.fetchall()
    cursor.close()
    conn.close()
    return data


