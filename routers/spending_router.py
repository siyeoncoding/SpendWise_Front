from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.security import OAuth2PasswordBearer
from typing import List

from core.auth import verify_token
from database.connection import get_db_connection
from models.spending_models import (
    Spending, SpendingCreate, SpendingSummary,
    SpendingCategorySummary, GoalCreate, GoalRead
)

router = APIRouter(tags=["Spending"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/login/token")


# ✅ 소비 내역 등록
@router.post("/spending")
async def add_spending(spending: SpendingCreate, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """
            INSERT INTO spending (user_id, category, amount, memo, date)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (user_id, spending.category, spending.amount, spending.memo, spending.date)
        )
        conn.commit()
    finally:
        cursor.close()
        conn.close()

    return {"message": "소비 내역 등록 완료!"}


# ✅ 특정 날짜 소비 내역 조회
@router.get("/spending", response_model=List[Spending])
async def get_spending_by_date(date: str, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT * FROM spending
            WHERE user_id = %s AND date = %s
            ORDER BY created_at DESC
            """,
            (user_id, date)
        )
        result = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    return result


# ✅ 날짜별 소비 총액 조회 (캘린더 색상 표현용)
@router.get("/spending-summary/daily", response_model=List[SpendingSummary])
async def get_spending_summary(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT DATE(date) as date, SUM(amount) as total_amount
            FROM spending
            WHERE user_id = %s
            GROUP BY DATE(date)
            ORDER BY date
            """,
            (user_id,)
        )
        result = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    return result




# 한달 기준 날짜별 소비내역을 카테고리로 집계해야지
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
#
# # ✅ 월별 카테고리 소비 요약
# @router.get("/spending-summary/monthly", response_model=List[SpendingCategorySummary])
# async def get_monthly_summary(
#     month: str = Query(...),
#     token: str = Depends(oauth2_scheme),
# ):
#     payload = verify_token(token)
#     user_id = payload.get("sub")
#
#     conn = get_db_connection()
#     cursor = conn.cursor(dictionary=True)
#     try:
#         cursor.execute(
#             """
#             SELECT category, SUM(amount) as total
#             FROM spending
#             WHERE user_id = %s AND DATE_FORMAT(date, '%%Y-%%m') = %s
#             GROUP BY category
#             """,
#             (user_id, month)
#         )
#         data = cursor.fetchall()
#     finally:
#         cursor.close()
#         conn.close()
#
#     return data


#소비수정
#
@router.post("/goal")
async def set_goal(goal: GoalCreate, token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True, buffered=True)

    try:
        # 1. 목표 존재 여부 확인 및 저장/업데이트
        cursor.execute("""
            SELECT * FROM spending_goal
            WHERE user_id = %s AND month = %s
        """, (user_id, goal.month))
        existing = cursor.fetchone()

        if existing:
            cursor.execute("""
                UPDATE spending_goal
                SET goal_amount = %s
                WHERE user_id = %s AND month = %s
            """, (goal.goal_amount, user_id, goal.month))
        else:
            cursor.execute("""
                INSERT INTO spending_goal (user_id, month, goal_amount)
                VALUES (%s, %s, %s)
            """, (user_id, goal.month, goal.goal_amount))
        conn.commit()

        # ✅ 2. 소비 총합 조회 (수정됨)
        year, month = map(int, goal.month.split('-'))
        cursor.execute("""
            SELECT SUM(amount) as total_spending
            FROM spending
            WHERE user_id = %s AND YEAR(date) = %s AND MONTH(date) = %s
        """, (user_id, year, month))
        total = cursor.fetchone().get("total_spending") or 0

        # 3. 목표 초과 여부 판단
        if total > goal.goal_amount:
            message = f"소비 목표({goal.goal_amount}원)를 초과했어요! 현재 총 소비: {total}원"
        else:
            message = f"목표가 저장되었습니다. 현재 총 소비: {total}원 / 목표: {goal.goal_amount}원"

    finally:
        cursor.close()
        conn.close()

    return {
        "message": message,
        "total_spending": total,
        "goal": goal.goal_amount
    }

# 소비 목표 설정 (있으면 업데이트)
# @router.post("/goal")
# async def set_goal(goal: GoalCreate, token: str = Depends(oauth2_scheme)):
#     payload = verify_token(token)
#     user_id = payload.get("sub")
#
#     conn = get_db_connection()
#     # 👇 여기에 buffered=True 추가
#     cursor = conn.cursor(buffered=True)
#     try:
#         cursor.execute(
#             """
#             SELECT * FROM spending_goal
#             WHERE user_id = %s AND month = %s
#             """,
#             (user_id, goal.month)
#         )
#         existing = cursor.fetchone()
#
#         if existing:
#             # 이미 존재하면 업데이트
#             cursor.execute(
#                 """
#                 UPDATE spending_goal
#                 SET goal_amount = %s
#                 WHERE user_id = %s AND month = %s
#                 """,
#                 (goal.goal_amount, user_id, goal.month)
#             )
#         else:
#             # 없으면 새로 삽입
#             cursor.execute(
#                 """
#                 INSERT INTO spending_goal (user_id, month, goal_amount)
#                 VALUES (%s, %s, %s)
#                 """,
#                 (user_id, goal.month, goal.goal_amount)
#             )
#         conn.commit()
#     finally:
#         cursor.close()
#         conn.close()
#
#     return {"message": "목표가 성공적으로 저장되었습니다."}
#





#  소비 목표 조회
@router.get("/goal", response_model=GoalRead)
async def get_goal(month: str = Query(...), token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")

    conn = get_db_connection()
    # 👇 여기에 buffered=True 추가 (dictionary=True와 함께 사용 가능)
    cursor = conn.cursor(dictionary=True, buffered=True)

    try:
        cursor.execute(
            """
            SELECT month, goal_amount
            FROM spending_goal
            WHERE user_id = %s AND month = %s
            """,
            (user_id, month)
        )
        goal = cursor.fetchone()  #  여기까지만 DB 통신

    finally:
        cursor.close()
        conn.close()

    #  커서를 닫은 후 결과 처리
    if goal:
        return goal
    else:
        raise HTTPException(status_code=404, detail="목표가 설정되지 않았습니다.")



