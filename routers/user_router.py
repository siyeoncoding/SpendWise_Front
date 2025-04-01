from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from models.user_models import User, LoginUser
from core.auth import hash_password, verify_password, create_access_token, verify_token
from database.connection import get_db_connection

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/login/token")

# 회원가입 API
@router.post("/signup")
async def signup(user: User):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (user.user_id,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디입니다.")

    hashed_pw = hash_password(user.password)
    cursor.execute(
        "INSERT INTO usertable (user_id, user_password, full_name, email) VALUES (%s, %s, %s, %s)",
        (user.user_id, hashed_pw, user.full_name, user.email)
    )
    conn.commit()
    cursor.close()
    conn.close()

    return {"message": "회원가입 완료!"}

# 로그인 + JWT 토큰 발급
@router.post("/login/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM usertable WHERE user_id = %s", (form_data.username,))
    db_user = cursor.fetchone()
    cursor.close()
    conn.close()

    if db_user is None or not verify_password(form_data.password, db_user[2]):
        raise HTTPException(status_code=400, detail="아이디 또는 비밀번호가 올바르지 않습니다.")

    token = create_access_token(data={"sub": str(db_user[0])})
    return {"access_token": token, "token_type": "bearer"}

# 로그인된 사용자 정보 확인
@router.get("/me")
async def read_my_info(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    user_id = payload.get("sub")
    return {"message": f"{user_id}님 환영합니다!"}
