import joblib
import numpy as np
import os

# Rich fertilizer knowledge base
FERTILIZER_INFO = {
    "Urea": {
        "formula": "CO(NH₂)₂",
        "npk": "46-0-0",
        "type": "Nitrogenous",
        "color": "0xFF1565C0",
        "best_for": ["Rice", "Wheat", "Maize", "Sugarcane"],
        "description": "Urea is the most widely used nitrogen fertilizer. It rapidly converts to ammonium in soil and is ideal for crops requiring high nitrogen.",
        "schedule": [
            {"phase": "Basal (At Sowing)", "timing": "Day 0", "dose_per_acre": "50 kg"},
            {"phase": "Tillering Stage", "timing": "25-30 days", "dose_per_acre": "25 kg"},
            {"phase": "Panicle Initiation", "timing": "50-55 days", "dose_per_acre": "25 kg"},
        ],
        "benefits": ["Fast-acting nitrogen source", "Highly water-soluble", "Cost-effective", "Improves protein content in grains"],
        "precautions": ["Avoid applying before heavy rain", "Do not apply during noon heat", "Store in cool dry place"],
        "application_method": "Broadcast or top-dress. Split application recommended for better efficiency."
    },
    "DAP": {
        "formula": "Di-Ammonium Phosphate",
        "npk": "18-46-0",
        "type": "Phosphatic + Nitrogenous",
        "color": "0xFF6A1B9A",
        "best_for": ["Wheat", "Cotton", "Oilseeds", "Vegetables"],
        "description": "DAP is the world's most widely used phosphorus fertilizer. It provides both phosphorus and nitrogen to support early crop development.",
        "schedule": [
            {"phase": "Basal Application", "timing": "At planting", "dose_per_acre": "50 kg"},
            {"phase": "Row Placement", "timing": "At sowing", "dose_per_acre": "25 kg"},
        ],
        "benefits": ["Promotes root development", "Excellent starter fertilizer", "Improves flowering", "High phosphorus content"],
        "precautions": ["Apply before sowing for best results", "Avoid contact with seeds directly", "Do not mix with calcium fertilizers"],
        "application_method": "Incorporate into soil at or before planting. Best used as a basal dose."
    },
    "MOP": {
        "formula": "Muriate of Potash",
        "npk": "0-0-60",
        "type": "Potassic",
        "color": "0xFFBF360C",
        "best_for": ["Potato", "Cotton", "Banana", "Sugarcane", "Fruits"],
        "description": "MOP provides potassium, essential for fruit quality, disease resistance, and water regulation in plants.",
        "schedule": [
            {"phase": "Basal Dose", "timing": "At sowing", "dose_per_acre": "40 kg"},
            {"phase": "Top Dressing", "timing": "45 days after planting", "dose_per_acre": "20 kg"},
        ],
        "benefits": ["Improves fruit quality and taste", "Enhances disease resistance", "Better water use efficiency", "Increases shelf life of produce"],
        "precautions": ["Sensitive crops may not tolerate high chloride", "Avoid on saline soils", "Use SOP as alternative for chloride-sensitive crops"],
        "application_method": "Apply as basal dose or split application. Water in after broadcast application."
    },
    "NPK Complex": {
        "formula": "N-P-K Complex",
        "npk": "17-17-17",
        "type": "Complex / Balanced",
        "color": "0xFF2E7D32",
        "best_for": ["All crops", "Vegetables", "Fruits", "Flowers"],
        "description": "A balanced fertilizer providing equal proportions of N, P, and K. Ideal for soil with moderate nutrient deficiency.",
        "schedule": [
            {"phase": "Pre-sowing", "timing": "1 week before sowing", "dose_per_acre": "75 kg"},
            {"phase": "Top Dress", "timing": "30 days", "dose_per_acre": "25 kg"},
        ],
        "benefits": ["Balanced nutrition", "Suitable for most crops", "Improves overall plant health", "Easy to apply"],
        "precautions": ["Soil test recommended before use", "Adjust based on existing nutrient levels", "Do not over-apply"],
        "application_method": "Broadcast evenly before planting or as a top-dress. Irrigate after application."
    },
    "SSP": {
        "formula": "Single Super Phosphate",
        "npk": "0-16-0 + Sulphur",
        "type": "Phosphatic + Sulphur",
        "color": "0xFFE65100",
        "best_for": ["Oilseeds", "Pulses", "Groundnut", "Soybean"],
        "description": "SSP provides phosphorus and sulphur — both important for oilseed crops and legumes. Also improves soil health.",
        "schedule": [
            {"phase": "Basal Application", "timing": "At sowing", "dose_per_acre": "100 kg"},
        ],
        "benefits": ["Contains sulphur for oilseeds", "Improves soil pH", "Affordable phosphorus source", "Beneficial for legumes"],
        "precautions": ["Store away from moisture", "Do not mix with alkaline fertilizers", "Check sulphur needs first"],
        "application_method": "Incorporate into soil 1-2 weeks before planting. Do not apply on surface without incorporation."
    },
}

DEFAULT_FERTILIZER = {
    "formula": "N-P-K",
    "npk": "As required",
    "type": "General",
    "color": "0xFF546E7A",
    "best_for": ["Various crops"],
    "description": "A general-purpose fertilizer. Consult local agricultural officer for precise recommendation.",
    "schedule": [
        {"phase": "Basal Dose", "timing": "At sowing", "dose_per_acre": "50 kg"},
    ],
    "benefits": ["General nutrition"],
    "precautions": ["Consult soil test results"],
    "application_method": "Follow label instructions and soil test recommendations."
}


class FertilizerService:
    def __init__(self):
        self.model = None
        self.scaler = None
        self._load_models()

    def _load_models(self):
        try:
            model_path = os.path.join(os.path.dirname(__file__), '../../models/fertilizer_model.pkl')
            scaler_path = os.path.join(os.path.dirname(__file__), '../../models/fertilizer_scaler.pkl')

            if os.path.exists(model_path):
                self.model = joblib.load(model_path)
            if os.path.exists(scaler_path):
                self.scaler = joblib.load(scaler_path)
        except Exception as e:
            print(f"Error loading fertilizer models: {e}")

    def _get_rule_based_fertilizer(self, N, P, K, crop_type):
        """Rule-based fallback using NPK values"""
        crop_lower = crop_type.lower()

        # High N need
        if N < 40:
            return "Urea"
        # High P need
        elif P < 30:
            return "DAP" if N < 60 else "SSP"
        # High K need
        elif K < 30:
            return "MOP"
        # Balanced need
        elif abs(N - P) < 15 and abs(P - K) < 15:
            return "NPK Complex"
        # Oilseed/legume crops
        elif any(c in crop_lower for c in ['soybean', 'groundnut', 'sunflower', 'mustard', 'pulse', 'lentil']):
            return "SSP"
        # Potassium-hungry crops
        elif any(c in crop_lower for c in ['potato', 'banana', 'sugarcane', 'cotton', 'fruit']):
            return "MOP"
        else:
            return "NPK Complex"

    def predict(self, data, db=None):
        fertilizer_name = "NPK Complex"

        if self.model and self.scaler:
            try:
                crop_code = sum(bytearray(data.crop_type.encode('utf-8'))) % 5
                input_data = np.array([[data.N, data.P, data.K, crop_code]])
                scaled_input = self.scaler.transform(input_data)
                prediction = self.model.predict(scaled_input)[0]
                fertilizer_name = str(prediction).strip()
            except Exception as e:
                print(f"Fertilizer model predict error: {e}")
                fertilizer_name = self._get_rule_based_fertilizer(data.N, data.P, data.K, data.crop_type)
        else:
            fertilizer_name = self._get_rule_based_fertilizer(data.N, data.P, data.K, data.crop_type)

        # Normalize to known fertilizer names
        name_map = {
            "urea": "Urea", "dap": "DAP", "mop": "MOP",
            "npk": "NPK Complex", "ssp": "SSP",
            "17-17-17": "NPK Complex", "46-0-0": "Urea",
        }
        normalized = name_map.get(fertilizer_name.lower(), fertilizer_name)
        if normalized not in FERTILIZER_INFO:
            # Try partial match
            for key in FERTILIZER_INFO:
                if key.lower() in fertilizer_name.lower() or fertilizer_name.lower() in key.lower():
                    normalized = key
                    break

        # Compute N-P-K status labels
        n_status = "Deficient" if data.N < 40 else "Optimal" if data.N < 80 else "Excess"
        p_status = "Deficient" if data.P < 30 else "Optimal" if data.P < 70 else "Excess"
        k_status = "Deficient" if data.K < 30 else "Optimal" if data.K < 70 else "Excess"

        # Try to query the database first
        if db:
            from app.models.models import Fertilizer
            import json
            try:
                db_fert = db.query(Fertilizer).filter(Fertilizer.name.like(f"%{normalized}%")).first()
                if db_fert:
                    schedule_list = json.loads(db_fert.schedule) if db_fert.schedule else []
                    best_for_crops = json.loads(db_fert.best_for) if db_fert.best_for else []
                    benefits = json.loads(db_fert.benefits) if db_fert.benefits else []
                    precautions = json.loads(db_fert.precautions) if db_fert.precautions else []

                    return {
                        "recommended_fertilizer": db_fert.name,
                        "formula": db_fert.formula or "",
                        "npk_ratio": db_fert.npk_ratio or "",
                        "fertilizer_type": db_fert.fertilizer_type or "",
                        "color_hex": db_fert.color_hex or "0xFF546E7A",
                        "description": db_fert.description or "",
                        "best_for_crops": best_for_crops,
                        "application_schedule": schedule_list,
                        "benefits": benefits,
                        "precautions": precautions,
                        "application_method": db_fert.application_method or "",
                        "n_status": n_status,
                        "p_status": p_status,
                        "k_status": k_status,
                        "total_dose_per_acre": schedule_list[0].split(': ')[-1] if (schedule_list and ':' in schedule_list[0]) else "50 kg",
                    }
            except Exception as ex:
                print(f"Error loading fertilizer from DB: {ex}")

        # Fallback to local memory dictionary
        info = FERTILIZER_INFO.get(normalized, DEFAULT_FERTILIZER)
        schedule_list = [f"{s['phase']} ({s['timing']}): {s['dose_per_acre']}" for s in info["schedule"]]

        return {
            "recommended_fertilizer": normalized,
            "formula": info["formula"],
            "npk_ratio": info["npk"],
            "fertilizer_type": info["type"],
            "color_hex": info["color"],
            "description": info["description"],
            "best_for_crops": info["best_for"],
            "application_schedule": schedule_list,
            "benefits": info["benefits"],
            "precautions": info["precautions"],
            "application_method": info["application_method"],
            "n_status": n_status,
            "p_status": p_status,
            "k_status": k_status,
            "total_dose_per_acre": info["schedule"][0]["dose_per_acre"],
        }
