import mysql
from fastapi import FastAPI
from auth import router
import _mysql_connector
from pydantic import BaseModel


app = FastAPI()
app.include_router(router)

# MySQL 연결 설정
def get_db():
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="0113",
        database="spendwise_user"
    )
    return conn


# Pydantic 모델 정의
class UserRegister(BaseModel):
    user_id: str
    user_password: str
    full_name: str
    email: str

class UserLogin(BaseModel):
    user_id: str
    user_password: str
#회원가입 api만들어보기









@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/hello/{name}")
async def say_hello(name: str):
    return {"message": f"Hello {name}"}
