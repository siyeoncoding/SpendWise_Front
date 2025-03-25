#api경로설정을 위한 apirouter, 여러개 api를 하나로 묶어서 사용가능!
#사용자 관련 api를 묶어서 사용자라우터로 묶을 수 있다...\

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import mysql.connector


#pydantic model define
class User(BaseModel):
    user_id: str
    password: str
    email: str
    full_name: str

class LoginUser(BaseModel):
    user_id: str
    password: str

# MySQL 데이터베이스 연결 함수
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="0113",
        database="spendwise_user"
    )

 #회원가입, 로그인
router = APIRouter()

#signup api
@router.post('/signup')
async def signup(user: User):
    conn = get_db_connection()
    cursor = conn.cursor()

    #기존 유저가 있는가?
    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디 입니다.")
    password = user.password

    cursor.execute("INSERT INTO usertable (user_id, password, full_name, email) VALUES (%s, %s, %s, %s)", (user.user_id, password,user.full_name,user.email))

    conn.commit()

    conn.close()
    return {"message": "회원가입이 성공적으로 완료되었습니다!"}

#로그인
@router.post('/login')
async def login(user: LoginUser):
    conn = get_db_connection()
    cursor = conn.cursor()

    # 사용자 존재 여부 확인
    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id,))
    db_user = cursor.fetchone()

    if db_user is None:
        raise HTTPException(status_code=400, detail="존재하지 않는 정보입니다.")


    # 입력된 비밀번호와 DB에 저장된 비밀번호 확인
    if db_user[2] != user.password:  # db_user[2]는 user_password 열
        raise HTTPException(status_code=400, detail="Invalid username or password")

    cursor.close()
    conn.close()

    return {"message": "로그인 성공!"}

