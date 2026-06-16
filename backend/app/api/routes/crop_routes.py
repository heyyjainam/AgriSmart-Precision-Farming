from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import json
from app.schemas.models import CropPredictionRequest, CropPredictionResponse
from app.services.crop_service import CropService
from app.core.database import get_db
from app.models.models import PredictionLog

router = APIRouter()
crop_service = CropService()

@router.post("/predict-crop", response_model=CropPredictionResponse)
async def predict_crop(request: CropPredictionRequest, db: Session = Depends(get_db)):
    try:
        result = crop_service.predict(request)
        
        # Log to Database
        log_entry = PredictionLog(
            type="Crop Recommendation",
            inputs_json=json.dumps(request.dict()),
            result=result.get("recommended_crop", "Unknown"),
            confidence=result.get("confidence", "N/A")
        )
        db.add(log_entry)
        db.commit()
        
        return CropPredictionResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

