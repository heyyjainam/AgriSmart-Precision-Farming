from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import crop_routes, fertilizer_routes, disease_routes, chatbot_routes, mandi_routes
from app.core.database import Base, engine
from app.models import models # Ensure models are registered

# Create database tables
Base.metadata.create_all(bind=engine)

from app.core.database import SessionLocal
import json

def seed_database():
    db = SessionLocal()
    try:
        from app.models.models import Fertilizer
        if db.query(Fertilizer).count() == 0:
            print("[DB] Seeding default fertilizers...")
            from app.services.fertilizer_service import FERTILIZER_INFO
            for name, info in FERTILIZER_INFO.items():
                schedule_list = [f"{s['phase']} ({s['timing']}): {s['dose_per_acre']}" for s in info["schedule"]]
                db_fert = Fertilizer(
                    name=name,
                    formula=info.get("formula", ""),
                    npk_ratio=info.get("npk", ""),
                    fertilizer_type=info.get("type", ""),
                    color_hex=info.get("color", "0xFF546E7A"),
                    description=info.get("description", ""),
                    best_for=json.dumps(info.get("best_for", [])),
                    schedule=json.dumps(schedule_list),
                    benefits=json.dumps(info.get("benefits", [])),
                    precautions=json.dumps(info.get("precautions", [])),
                    application_method=info.get("application_method", "")
                )
                db.add(db_fert)
            db.commit()
            print("[DB] Default fertilizers seeded successfully!")
    except Exception as e:
        print(f"[DB] Seeding error: {e}")
    finally:
        db.close()

seed_database()



app = FastAPI(
    title="AgriSmart Assistant API",
    description="Backend API for the AgriSmart Assistant Flutter application.",
    version="1.0.0"
)

# Configure CORS for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(crop_routes.router, prefix="/api/v1", tags=["Crop Recommendation"])
app.include_router(fertilizer_routes.router, prefix="/api/v1", tags=["Fertilizer Suggestion"])
app.include_router(disease_routes.router, prefix="/api/v1", tags=["Disease Detection"])
app.include_router(chatbot_routes.router, prefix="/api/v1", tags=["Agri Chatbot"])

# Mandi Rates - Registering specifically
app.include_router(mandi_routes.router, prefix="/api/v1", tags=["Mandi Rates"])

@app.get("/")
async def root():
    return {"message": "Welcome to the AgriSmart Assistant API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
