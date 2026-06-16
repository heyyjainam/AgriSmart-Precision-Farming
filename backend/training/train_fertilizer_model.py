import joblib
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from data_engineering import load_and_preprocess_fertilizer_data

def train_fertilizer_model():
    print("Loading and preprocessing fertilizer data...")
    X_train, X_test, y_train, y_test = load_and_preprocess_fertilizer_data()
    
    print("Training RandomForest model for Fertilizer...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Fertilizer Model Accuracy: {acc:.4f}")
    
    os.makedirs('../models', exist_ok=True)
    joblib.dump(model, '../models/fertilizer_model.pkl')
    print("Model saved to models/fertilizer_model.pkl")

if __name__ == "__main__":
    train_fertilizer_model()
