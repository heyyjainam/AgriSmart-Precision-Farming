from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from datetime import datetime
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="Farmer") # "Farmer" or "Admin"
    created_at = Column(DateTime, default=datetime.utcnow)

class PredictionLog(Base):
    __tablename__ = "prediction_logs"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, index=True, nullable=False) # "Crop Recommendation", "Fertilizer Suggestion", "Disease Detection"
    inputs_json = Column(Text, nullable=False) # Stores input fields as JSON string
    result = Column(String, nullable=False)
    confidence = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

class MandiRate(Base):
    __tablename__ = "mandi_rates"

    id = Column(Integer, primary_key=True, index=True)
    commodity = Column(String, index=True, nullable=False)
    state = Column(String, index=True, nullable=False)
    mandi = Column(String, nullable=False)
    min_price = Column(Float, nullable=False)
    max_price = Column(Float, nullable=False)
    modal_price = Column(Float, nullable=False)
    arrival_date = Column(String, nullable=True)
