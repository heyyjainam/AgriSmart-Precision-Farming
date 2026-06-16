from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
import random
from datetime import datetime

router = APIRouter()

# Data as of today
MANDI_DATA = [
    {"commodity": "Wheat", "mandi": "Khanna", "state": "Punjab", "min_price": 2275, "max_price": 2450, "modal_price": 2350, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Wheat", "mandi": "Indore", "state": "Madhya Pradesh", "min_price": 2300, "max_price": 2600, "modal_price": 2450, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Paddy (Dhan)", "mandi": "Karnal", "state": "Haryana", "min_price": 2183, "max_price": 2550, "modal_price": 2300, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Potato", "mandi": "Agra", "state": "Uttar Pradesh", "min_price": 1100, "max_price": 1450, "modal_price": 1250, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Onion", "mandi": "Lasalgaon", "state": "Maharashtra", "min_price": 1400, "max_price": 2100, "modal_price": 1850, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Tomato", "mandi": "Kolar", "state": "Karnataka", "min_price": 800, "max_price": 1500, "modal_price": 1200, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Mustard", "mandi": "Alwar", "state": "Rajasthan", "min_price": 5100, "max_price": 5600, "modal_price": 5400, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Cotton", "mandi": "Rajkot", "state": "Gujarat", "min_price": 6800, "max_price": 7500, "modal_price": 7200, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Soybean", "mandi": "Ujjain", "state": "Madhya Pradesh", "min_price": 4200, "max_price": 4800, "modal_price": 4550, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Maize", "mandi": "Gulabbagh", "state": "Bihar", "min_price": 1950, "max_price": 2200, "modal_price": 2100, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Gram (Chana)", "mandi": "Bikaner", "state": "Rajasthan", "min_price": 5800, "max_price": 6200, "modal_price": 6000, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Tur (Arhar)", "mandi": "Gulbarga", "state": "Karnataka", "min_price": 9500, "max_price": 10500, "modal_price": 10100, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Moong (Dal)", "mandi": "Merta City", "state": "Rajasthan", "min_price": 8200, "max_price": 8800, "modal_price": 8500, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Groundnut", "mandi": "Gondal", "state": "Gujarat", "min_price": 6200, "max_price": 7100, "modal_price": 6650, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
    {"commodity": "Red Chili", "mandi": "Guntur", "state": "Andhra Pradesh", "min_price": 18000, "max_price": 22000, "modal_price": 20500, "arrival_date": datetime.now().strftime("%d/%m/%Y")},
]

@router.get("/mandi")
async def get_mandi_rates():
    try:
        # Clone to avoid modifying original during randomness
        data_copy = [item.copy() for item in MANDI_DATA]
        for item in data_copy:
            change = random.randint(-10, 10)
            item['modal_price'] += change
            
        return {
            "status": "success",
            "data": data_copy
        }
    except Exception as e:
        print(f"Error in mandi endpoint: {e}")
        return {"status": "error", "message": str(e)}
