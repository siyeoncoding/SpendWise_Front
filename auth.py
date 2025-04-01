#api경로설정을 위한 apirouter, 여러개 api를 하나로 묶어서 사용가능!
#사용자 관련 api를 묶어서 사용자라우터로 묶을 수 있다...\
import bcrypt
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import mysql.connector
from fastapi.security import OAuth2PasswordRequestForm

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

# signup api
@router.post('/signup')
async def signup(user: User):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디 입니다.")

    hashed_pw = hash_password(user.password)

    cursor.execute("INSERT INTO usertable (user_id, password, full_name, email) VALUES (%s, %s, %s, %s)",
                   (user.user_id, hashed_pw, user.full_name, user.email))
    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "회원가입이 성공적으로 완료되었습니다!"}

# login api
@router.post('/login')
async def login(user: LoginUser):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id,))
    db_user = cursor.fetchone()
    cursor.close()
    conn.close()

    if db_user is None:
        raise HTTPException(status_code=400, detail="존재하지 않는 정보입니다.")

    hashed_pw = db_user[2]  # 저장된 해시 비밀번호
    if not verify_password(user.password, hashed_pw):
        raise HTTPException(status_code=400, detail="아이디 또는 비밀번호가 올바르지 않습니다.")

    return {"message": "로그인 성공!"}

# bcrypt를 이용한 암호화 함수
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))




