# main.py
from fastapi import FastAPI
from routers import user_router, spending_router

app = FastAPI()

# 라우터 등록
app.include_router(user_router.router, prefix="/user", tags=["User"])
app.include_router(spending_router.router, tags=["Spending"])


@app.get("/")
async def root():
    return {"message": "SpendWise 백엔드입니다."}
