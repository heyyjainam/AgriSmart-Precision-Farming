from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import json
from app.schemas.models import FertilizerPredictionRequest, FertilizerResponse
from app.services.fertilizer_service import FertilizerService
from app.core.database import get_db
from app.models.models import PredictionLog

router = APIRouter()
fertilizer_service = FertilizerService()

@router.post("/predict-fertilizer", response_model=FertilizerResponse)
async def predict_fertilizer(request: FertilizerPredictionRequest, db: Session = Depends(get_db)):
    try:
        result = fertilizer_service.predict(request)
        
        # Log to Database
        log_entry = PredictionLog(
            type="Fertilizer Suggest",
            inputs_json=json.dumps(request.dict()),
            result=result.get("recommended_fertilizer", "Unknown"),
            confidence=None
        )
        db.add(log_entry)
        db.commit()
        
        return FertilizerResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

