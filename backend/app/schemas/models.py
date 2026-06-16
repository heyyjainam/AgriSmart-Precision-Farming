from pydantic import BaseModel, Field

# --- CROP RECOMMENDATION ---
class CropPredictionRequest(BaseModel):
    N: float = Field(..., description="Nitrogen content in soil")
    P: float = Field(..., description="Phosphorous content in soil")
    K: float = Field(..., description="Potassium content in soil")
    temperature: float = Field(..., description="Temperature in Celsius")
    humidity: float = Field(..., description="Relative humidity in percentage")
    ph: float = Field(..., description="pH value of the soil")
    rainfall: float = Field(..., description="Rainfall in mm")

class CropPredictionResponse(BaseModel):
    recommended_crop: str
    confidence: str
    fertilizer: str

# --- FERTILIZER RECOMMENDATION ---
class FertilizerPredictionRequest(BaseModel):
    N: float
    P: float
    K: float
    crop_type: str

from typing import List

class FertilizerResponse(BaseModel):
    recommended_fertilizer: str
    formula: str
    npk_ratio: str
    fertilizer_type: str
    color_hex: str
    description: str
    best_for_crops: List[str]
    application_schedule: List[str]
    benefits: List[str]
    precautions: List[str]
    application_method: str
    n_status: str
    p_status: str
    k_status: str
    total_dose_per_acre: str


# --- DISEASE DETECTION ---
# (Input is multipart form-data image, so no Pydantic model for request)
from typing import List

class DiseasePredictionResponse(BaseModel):
    disease: str
    confidence: str
    confidence_value: float
    severity: str
    is_healthy: bool
    description: str
    symptoms: List[str]
    treatments: List[str]
    prevention: str

# --- CHATBOT ---
class ChatbotRequest(BaseModel):
    query: str

class ChatbotResponse(BaseModel):
    answer: str
