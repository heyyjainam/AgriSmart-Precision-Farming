from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from sqlalchemy.orm import Session
import json
from app.schemas.models import DiseasePredictionResponse
from app.services.disease_service import DiseaseService
from app.core.database import get_db
from app.models.models import PredictionLog

router = APIRouter()
disease_service = DiseaseService()

# Allowed image extensions for filename-based check
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tiff"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/bmp", "image/gif", "image/tiff"}

@router.post("/predict-disease", response_model=DiseasePredictionResponse)
async def predict_disease(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Flutter Web sometimes sends content_type as application/octet-stream or None
    # So we check BOTH content_type AND file extension as fallback
    content_type = file.content_type or ""
    filename = file.filename or ""
    file_ext = "." + filename.rsplit(".", 1)[-1].lower() if "." in filename else ""

    is_image_by_type = content_type in ALLOWED_CONTENT_TYPES or content_type.startswith("image/")
    is_image_by_ext = file_ext in ALLOWED_EXTENSIONS

    if not is_image_by_type and not is_image_by_ext:
        raise HTTPException(
            status_code=400,
            detail=f"File is not a valid image. Got content_type='{content_type}', filename='{filename}'. Please upload a JPG, PNG, or WEBP image."
        )

    try:
        contents = await file.read()
        if len(contents) == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        result = await disease_service.predict(contents)
        
        # Log to Database
        log_entry = PredictionLog(
            type="Disease Detection",
            inputs_json=json.dumps({"filename": filename, "file_size": len(contents)}),
            result=result.get("disease", "Unknown"),
            confidence=result.get("confidence", "N/A")
        )
        db.add(log_entry)
        db.commit()
        
        return DiseasePredictionResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

