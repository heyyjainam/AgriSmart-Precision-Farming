from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.models import User

router = APIRouter()

class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

@router.post("/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Hardcoded admin check
    if request.email == "admin@gmail.com" and request.password == "1234":
        return {"username": "Admin", "email": "admin@gmail.com", "role": "Admin"}
        
    # Standard database check for farmers
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid Email or Password")
    
    # Match password
    if user.password_hash != request.password:
        raise HTTPException(status_code=400, detail="Invalid Email or Password")
        
    return {"username": user.username, "email": user.email, "role": user.role}

@router.post("/register")
async def register(request: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == request.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    new_user = User(
        username=request.username,
        email=request.email,
        password_hash=request.password,
        role="Farmer"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"username": new_user.username, "email": new_user.email, "role": new_user.role}
