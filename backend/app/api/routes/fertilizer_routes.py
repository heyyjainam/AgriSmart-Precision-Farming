from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import json
from typing import List
from pydantic import BaseModel
from app.schemas.models import FertilizerPredictionRequest, FertilizerResponse
from app.services.fertilizer_service import FertilizerService
from app.core.database import get_db
from app.models.models import PredictionLog, Fertilizer

router = APIRouter()
fertilizer_service = FertilizerService()

class FertilizerUpdateSchema(BaseModel):
    formula: str
    npk_ratio: str
    fertilizer_type: str
    color_hex: str
    description: str
    best_for: List[str]
    schedule: List[str]
    benefits: List[str]
    precautions: List[str]
    application_method: str

@router.post("/predict-fertilizer", response_model=FertilizerResponse)
async def predict_fertilizer(request: FertilizerPredictionRequest, db: Session = Depends(get_db)):
    try:
        result = fertilizer_service.predict(request, db=db)
        
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

@router.get("/fertilizer-crops", response_model=List[str])
async def get_fertilizer_crops(db: Session = Depends(get_db)):
    try:
        fertilizers = db.query(Fertilizer).all()
        crops = set()
        for f in fertilizers:
            if f.best_for:
                try:
                    crop_list = json.loads(f.best_for)
                    crops.update(crop_list)
                except Exception:
                    pass
        if not crops:
            return ['Rice', 'Wheat', 'Maize', 'Sugarcane', 'Cotton', 'Potato', 'Soybean', 'Groundnut', 'Mustard', 'Banana']
        return sorted(list(crops))
    except Exception as e:
        print(f"Error fetching crops: {e}")
        return ['Rice', 'Wheat', 'Maize', 'Sugarcane', 'Cotton', 'Potato', 'Soybean', 'Groundnut', 'Mustard', 'Banana']

@router.get("/fertilizers", response_model=List[FertilizerResponse])
async def get_fertilizers(db: Session = Depends(get_db)):
    try:
        fertilizers = db.query(Fertilizer).all()
        response_list = []
        for f in fertilizers:
            sched = json.loads(f.schedule) if f.schedule else []
            best = json.loads(f.best_for) if f.best_for else []
            ben = json.loads(f.benefits) if f.benefits else []
            prec = json.loads(f.precautions) if f.precautions else []
            response_list.append({
                "recommended_fertilizer": f.name,
                "formula": f.formula or "",
                "npk_ratio": f.npk_ratio or "",
                "fertilizer_type": f.fertilizer_type or "",
                "color_hex": f.color_hex or "0xFF546E7A",
                "description": f.description or "",
                "best_for_crops": best,
                "application_schedule": sched,
                "benefits": ben,
                "precautions": prec,
                "application_method": f.application_method or "",
                "n_status": "Optimal",
                "p_status": "Optimal",
                "k_status": "Optimal",
                "total_dose_per_acre": sched[0].split(': ')[-1] if (sched and ':' in sched[0]) else "50 kg",
            })
        return response_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/fertilizers/{name}", response_model=FertilizerResponse)
async def update_fertilizer(name: str, payload: FertilizerUpdateSchema, db: Session = Depends(get_db)):
    try:
        f = db.query(Fertilizer).filter(Fertilizer.name == name).first()
        if not f:
            raise HTTPException(status_code=404, detail="Fertilizer not found")
        
        f.formula = payload.formula
        f.npk_ratio = payload.npk_ratio
        f.fertilizer_type = payload.fertilizer_type
        f.color_hex = payload.color_hex
        f.description = payload.description
        f.best_for = json.dumps(payload.best_for)
        f.schedule = json.dumps(payload.schedule)
        f.benefits = json.dumps(payload.benefits)
        f.precautions = json.dumps(payload.precautions)
        f.application_method = payload.application_method
        
        db.commit()
        db.refresh(f)
        
        sched = json.loads(f.schedule) if f.schedule else []
        best = json.loads(f.best_for) if f.best_for else []
        ben = json.loads(f.benefits) if f.benefits else []
        prec = json.loads(f.precautions) if f.precautions else []
        
        return {
            "recommended_fertilizer": f.name,
            "formula": f.formula or "",
            "npk_ratio": f.npk_ratio or "",
            "fertilizer_type": f.fertilizer_type or "",
            "color_hex": f.color_hex or "0xFF546E7A",
            "description": f.description or "",
            "best_for_crops": best,
            "application_schedule": sched,
            "benefits": ben,
            "precautions": prec,
            "application_method": f.application_method or "",
            "n_status": "Optimal",
            "p_status": "Optimal",
            "k_status": "Optimal",
            "total_dose_per_acre": sched[0].split(': ')[-1] if (sched and ':' in sched[0]) else "50 kg",
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


