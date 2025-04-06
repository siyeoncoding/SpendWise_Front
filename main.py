from fastapi import FastAPI
from routers import user_router, spending_router

app = FastAPI()

# 사용자 관련 API 라우터 등록
app.include_router(user_router.router, prefix="/user")
app.include_router(spending_router.router)
@app.get("/")
async def root():
    return {"message": "SpendWise 백엔드입니다."}









# import mysql.connector
# from fastapi import FastAPI, HTTPException
# from pydantic import BaseModel
#
# app = FastAPI()
#
# # MySQL 연결 설정 함수
# def get_db():
#     return mysql.connector.connect(
#         host="localhost",
#         user="root",
#         password="0113",
#         database="spendwise_user"
#     )
#
# # Pydantic 모델 정의
# class UserRegister(BaseModel):
#     user_id: str
#     user_password: str
#     full_name: str
#     email: str
#
# class UserLogin(BaseModel):
#     user_id: str
#     user_password: str
#
# # 회원가입 API
# @app.post("/register/")
# def register(user: UserRegister):
#     conn = get_db()
#     cur = conn.cursor()
#
#     try:
#         # 중복 검사
#         cur.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id,))
#         existing_user = cur.fetchone()
#
#         if existing_user:
#             raise HTTPException(status_code=400, detail="이미 존재하는 사용자 아이디입니다!")
#
#         # 사용자 데이터 삽입
#         cur.execute(
#             "INSERT INTO usertable (user_id, user_password, full_name, email) VALUES (%s, %s, %s, %s)",
#             (user.user_id, user.user_password, user.full_name, user.email)
#         )
#
#         conn.commit()
#         return {"message": "회원가입 성공!"}
#
#     finally:
#         cur.close()
#         conn.close()
#
# # 로그인 API
# @app.post("/login")  # 경로 끝에 슬래시 제거
# def login(user: UserLogin):
#     conn = get_db()
#     cur = conn.cursor()
#
#     try:
#         # 사용자 조회
#         cur.execute("SELECT * FROM usertable WHERE user_id = %s AND user_password = %s",
#                     (user.user_id, user.user_password))
#         existing_user = cur.fetchone()
#
#         if existing_user:
#             return {"message": "로그인 성공!"}
#         else:
#             raise HTTPException(status_code=400, detail="아이디 또는 비밀번호가 올바르지 않습니다.")
#
#     finally:
#         cur.close()
#         conn.close()
#
# # 기본 라우트
# @app.get("/")
# async def root():
#     return {"message": "Hello World"}
#
# @app.get("/hello/{name}")
# async def say_hello(name: str):
#     return {"message": f"Hello {name}"}
