from pydantic import BaseModel

class User(BaseModel):
    user_id: str
    password: str
    email: str
    full_name: str

class LoginUser(BaseModel):
    user_id: str
    password: str
