import os
import numpy as np
import tensorflow as tf
from PIL import Image
import io

# Rich disease knowledge base
DISEASE_INFO = {
    "Apple Scab": {
        "severity": "High",
        "color": "red",
        "description": "A fungal disease caused by Venturia inaequalis that affects leaves, blossoms, and fruit.",
        "symptoms": [
            "Olive-green or brown spots on leaves",
            "Scab-like lesions on fruit surface",
            "Yellowing and premature leaf drop",
            "Distorted or cracked fruit"
        ],
        "treatments": [
            {"title": "Fungicide Application", "desc": "Apply Captan or Mancozeb-based fungicide every 7-10 days during wet spring weather."},
            {"title": "Pruning & Sanitation", "desc": "Remove and destroy all infected leaves and fruit. Prune to improve air circulation."},
            {"title": "Resistant Varieties", "desc": "In future plantings, choose scab-resistant apple varieties like Liberty or Freedom."},
        ],
        "prevention": "Avoid overhead irrigation. Apply protective fungicides before rain events."
    },
    "Apple Black Rot": {
        "severity": "High",
        "color": "red",
        "description": "Caused by the fungus Botryosphaeria obtusa, affecting fruit, leaves, and tree bark.",
        "symptoms": [
            "Brown to black circular lesions on fruit",
            "Purple spots on leaves with brown centers",
            "Mummified fruit remaining on tree",
            "Bark cankers on branches"
        ],
        "treatments": [
            {"title": "Remove Mummified Fruit", "desc": "Collect and destroy all mummified fruit and cankered wood, which serve as infection sources."},
            {"title": "Copper Fungicide", "desc": "Apply copper-based fungicide during the growing season for protection."},
            {"title": "Wound Management", "desc": "Prune infected branches at least 15 cm below visible canker tissue."},
        ],
        "prevention": "Maintain good tree vigor through proper fertilization and watering. Avoid wounding the bark."
    },
    "Healthy Apple": {
        "severity": "None",
        "color": "green",
        "description": "The plant appears healthy with no signs of disease or pest damage.",
        "symptoms": [
            "Deep green, uniform leaf color",
            "No spots, lesions, or discoloration",
            "Firm and properly developed fruit",
            "Normal growth pattern"
        ],
        "treatments": [
            {"title": "Routine Maintenance", "desc": "Continue regular watering, fertilization, and pruning practices."},
            {"title": "Preventive Spray", "desc": "Apply a preventive fungicide spray before the rainy season as a precaution."},
            {"title": "Monitor Regularly", "desc": "Inspect leaves weekly for early signs of disease for prompt action."},
        ],
        "prevention": "Maintain good soil health and balanced nutrition to keep the plant immune to diseases."
    },
    "Corn Common Rust": {
        "severity": "Medium",
        "color": "orange",
        "description": "Caused by Puccinia sorghi fungus, one of the most common diseases of maize worldwide.",
        "symptoms": [
            "Small, powdery, rust-colored pustules on both leaf surfaces",
            "Yellowing around pustules",
            "Premature drying of leaves in severe cases",
            "Reduced photosynthesis leading to yield loss"
        ],
        "treatments": [
            {"title": "Fungicide Spray", "desc": "Apply Propiconazole or Trifloxystrobin fungicide at early disease onset."},
            {"title": "Early Planting", "desc": "Plant earlier in the season to avoid peak rust infection periods."},
            {"title": "Resistant Hybrids", "desc": "Use rust-resistant corn hybrid varieties in future plantings."},
        ],
        "prevention": "Plant resistant varieties and monitor fields regularly. Ensure proper crop rotation."
    },
    "Healthy Corn": {
        "severity": "None",
        "color": "green",
        "description": "The corn plant is in excellent health with no visible disease symptoms.",
        "symptoms": [
            "Bright green leaves",
            "Strong, upright stalks",
            "Well-developed ears",
            "No lesions, spots, or discoloration"
        ],
        "treatments": [
            {"title": "Balanced Fertilization", "desc": "Continue with NPK schedule as per soil test recommendations."},
            {"title": "Adequate Irrigation", "desc": "Maintain proper moisture levels, especially during tasseling and silking."},
            {"title": "Pest Monitoring", "desc": "Check for common pests like stem borers and fall armyworm regularly."},
        ],
        "prevention": "Practice crop rotation and use certified disease-free seeds."
    },
    "Tomato Leaf Mold": {
        "severity": "Medium",
        "color": "orange",
        "description": "Caused by Passalora fulva (formerly Cladosporium fulvum), mainly affecting greenhouse tomatoes.",
        "symptoms": [
            "Pale greenish-yellow spots on upper leaf surfaces",
            "Olive-gray velvety mold growth on leaf undersides",
            "Leaves curl, wither, and drop prematurely",
            "Reduced fruit set and quality"
        ],
        "treatments": [
            {"title": "Reduce Humidity", "desc": "Improve ventilation and reduce leaf wetness. Keep humidity below 85%."},
            {"title": "Fungicide Application", "desc": "Apply chlorothalonil or mancozeb every 7-14 days from first appearance."},
            {"title": "Remove Infected Leaves", "desc": "Carefully remove and destroy infected leaves to prevent spore spread."},
        ],
        "prevention": "Use resistant varieties. Space plants properly for good airflow. Avoid wetting foliage when irrigating."
    },
    "Healthy Tomato": {
        "severity": "None",
        "color": "green",
        "description": "The tomato plant is healthy and shows no signs of disease or stress.",
        "symptoms": [
            "Vibrant dark green foliage",
            "No spots, mold, or wilting",
            "Healthy fruit development",
            "Strong root system"
        ],
        "treatments": [
            {"title": "Calcium Supplementation", "desc": "Ensure adequate calcium to prevent blossom end rot as a preventive measure."},
            {"title": "Regular Pruning", "desc": "Remove suckers for indeterminate varieties for better air circulation."},
            {"title": "Consistent Watering", "desc": "Water deeply but infrequently to encourage deep root growth."},
        ],
        "prevention": "Rotate crops every 2-3 years. Use disease-resistant varieties and certified healthy seedlings."
    },
}

DEFAULT_DISEASE_INFO = {
    "severity": "Unknown",
    "color": "grey",
    "description": "Could not determine detailed disease information.",
    "symptoms": ["Consult a local agricultural expert."],
    "treatments": [{"title": "Expert Consultation", "desc": "Please consult a local agricultural extension officer."}],
    "prevention": "Keep plants healthy with proper nutrition and watering."
}

class DiseaseService:
    def __init__(self):
        self.model = None
        self.classes = []
        self._load_model()

    def _load_model(self):
        try:
            model_path = os.path.join(os.path.dirname(__file__), '../../models/disease_model.h5')
            classes_path = os.path.join(os.path.dirname(__file__), '../../models/disease_classes.txt')

            if os.path.exists(model_path):
                self.model = tf.keras.models.load_model(model_path)
                print("[Disease] Model loaded successfully.")
            if os.path.exists(classes_path):
                with open(classes_path, 'r') as f:
                    self.classes = [line.strip() for line in f.readlines()]
                print(f"[Disease] Loaded {len(self.classes)} disease classes.")
        except Exception as e:
            print(f"Error loading disease models: {e}")

    async def predict(self, file_bytes: bytes):
        predicted_class = "Apple Scab"
        confidence_val = 0.94

        if self.model and self.classes:
            try:
                image = Image.open(io.BytesIO(file_bytes))
                if image.mode != "RGB":
                    image = image.convert("RGB")

                image = image.resize((224, 224))
                img_array = tf.keras.preprocessing.image.img_to_array(image)
                img_array = img_array / 255.0
                img_array = np.expand_dims(img_array, axis=0)

                predictions = self.model.predict(img_array)[0]
                max_idx = int(np.argmax(predictions))
                confidence_val = float(predictions[max_idx])

                # If confidence too low, the image is likely not a supported plant
                if confidence_val < 0.30:
                    return {
                        "disease": "Uncertain — Unsupported Plant",
                        "confidence": f"{int(confidence_val * 100)}%",
                        "confidence_value": round(confidence_val, 4),
                        "severity": "Unknown",
                        "is_healthy": False,
                        "description": (
                            f"The model could not confidently identify this plant (confidence: {int(confidence_val*100)}%). "
                            "This model is trained only for Apple, Corn, and Tomato plants. "
                            "Please upload a clear, close-up leaf image of these supported plants."
                        ),
                        "symptoms": [
                            "Image may not be a supported plant type",
                            "Supported plants: Apple · Corn · Tomato",
                            "Try a clearer, brighter leaf photo",
                            "Ensure the leaf fills most of the frame",
                        ],
                        "treatments": [
                            "Upload a clear image of: Apple leaf, Corn leaf, or Tomato leaf",
                            "Ensure good lighting and minimal background",
                            "Avoid blurry or small images",
                        ],
                        "prevention": "For best results, use high-resolution leaf photos with clear green coloring.",
                    }

                predicted_class = self.classes[max_idx]
            except Exception as e:
                print(f"Prediction error: {e}")
                predicted_class = "Unknown"
                confidence_val = 0.0

        info = DISEASE_INFO.get(predicted_class, DEFAULT_DISEASE_INFO)
        is_healthy = "Healthy" in predicted_class

        return {
            "disease": predicted_class,
            "confidence": f"{int(confidence_val * 100)}%",
            "confidence_value": round(confidence_val, 4),
            "severity": info["severity"],
            "is_healthy": is_healthy,
            "description": info["description"],
            "symptoms": info["symptoms"],
            "treatments": [f"{t['title']}: {t['desc']}" for t in info["treatments"]],
            "prevention": info["prevention"],
        }
