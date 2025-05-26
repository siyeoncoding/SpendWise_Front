# from fastapi import FastAPI
# from routers import user_router, spending_router, test_router  # 여기서 test_router 불러옴
#
# app = FastAPI()
#
# # 각 기능별 router 등록
# app.include_router(user_router.router, prefix="/user", tags=["User"])
# app.include_router(spending_router.router, tags=["Spending"])
# app.include_router(test_router.router, prefix="/test", tags=["Board"])  # 👈 여기가 포인트!
#
# @app.get("/")
# async def root():
#     return {"message": "SpendWise 백엔드입니다."}
from fastapi import FastAPI
from routers import user_router, spending_router, test_router

from routers import analyze_router
from routers import predict_router

app = FastAPI()

app.include_router(user_router.router, prefix="/user", tags=["User"])
app.include_router(spending_router.router, tags=["Spending"])
app.include_router(analyze_router.router, tags=["Analysis"])
app.include_router(predict_router.router, tags=["Prediction"])


@app.get("/")
async def root():
    return {"message": "SpendWise"}
