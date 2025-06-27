from jose import jwt, JWTError
from datetime import datetime, timedelta
from fastapi import HTTPException
import bcrypt

# 🔐 JWT 설정
SECRET_KEY = "spendwise_super_secret_key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# 🔐 비밀번호 해시 함수
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

# 🔐 비밀번호 검증 함수
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))

# 🔐 액세스 토큰 생성 함수
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta if expires_delta else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    print("✅ 토큰 생성 완료:", token)  # 디버깅용 로그
    return token

# 🔐 토큰 검증 함수 (디버깅 로그 포함)
def verify_token(token: str):
    try:
        print("📦 받은 토큰:", token)  # 토큰 내용 출력
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        print("✅ 디코딩 성공:", payload)  # 성공한 경우 payload 출력
        return payload
    except JWTError as e:
        print("❌ 토큰 디코딩 실패:", e)  # 실패한 경우 예외 로그
        raise HTTPException(status_code=401, detail="유효하지 않은 인증 토큰입니다.")
