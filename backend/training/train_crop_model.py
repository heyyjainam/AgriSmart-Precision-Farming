import joblib
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from xgboost import XGBClassifier
from sklearn.metrics import accuracy_score
from data_engineering import load_and_preprocess_crop_data
from sklearn.preprocessing import LabelEncoder

def train_and_compare_models():
    print("Loading and preprocessing crop data...")
    X_train, X_test, y_train, y_test = load_and_preprocess_crop_data()
    
    # Encode target labels for XGBoost which requires numeric labels
    le = LabelEncoder()
    y_train_encoded = le.fit_transform(y_train)
    y_test_encoded = le.transform(y_test)
    
    # Save Label Encoder
    os.makedirs('../models', exist_ok=True)
    joblib.dump(le, '../models/crop_label_encoder.pkl')
    
    models = {
        'RandomForest': RandomForestClassifier(n_estimators=100, random_state=42),
        'XGBoost': XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', random_state=42),
        'SVM': SVC(kernel='rbf', probability=True, random_state=42)
    }
    
    best_model = None
    best_accuracy = 0
    best_name = ""
    
    for name, model in models.items():
        print(f"Training {name}...")
        if name == 'XGBoost':
            model.fit(X_train, y_train_encoded)
            preds = model.predict(X_test)
            acc = accuracy_score(y_test_encoded, preds)
        else:
            model.fit(X_train, y_train)
            preds = model.predict(X_test)
            acc = accuracy_score(y_test, preds)
            
        print(f"{name} Accuracy: {acc:.4f}")
        
        if acc > best_accuracy:
            best_accuracy = acc
            best_model = model
            best_name = name
            
    print(f"\nBest Model: {best_name} with Accuracy: {best_accuracy:.4f}")
    
    # Save the best model
    # Note: If XGBoost is the best, we must note it in the service so it decodes output.
    joblib.dump(best_model, '../models/crop_model.pkl')
    # Save the best model name flag to know if we need to decode
    with open('../models/crop_model_type.txt', 'w') as f:
        f.write(best_name)
    print("Model saved to models/crop_model.pkl")

if __name__ == "__main__":
    train_and_compare_models()
