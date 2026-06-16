import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import joblib
import os

def load_and_preprocess_crop_data():
    """
    Simulates loading crop dataset, cleaning, and preprocessing.
    In a real scenario, this would load from data/crop_data.csv.
    """
    # 1. Try to load real Kaggle Data
    current_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(current_dir, '..', 'data', 'Crop_recommendation.csv')
    
    if os.path.exists(csv_path):
        print(f"Loading real dataset from {csv_path}...")
        df = pd.read_csv(csv_path)
    else:
        print(f"Real dataset not found at {csv_path}. Generating dummy data...")
        np.random.seed(42)
        n_samples = 1000
        
        data = {
            'N': np.random.randint(0, 140, n_samples),
            'P': np.random.randint(5, 145, n_samples),
            'K': np.random.randint(5, 205, n_samples),
            'temperature': np.random.uniform(8.0, 43.0, n_samples),
            'humidity': np.random.uniform(14.0, 100.0, n_samples),
            'ph': np.random.uniform(3.5, 9.9, n_samples),
            'rainfall': np.random.uniform(20.0, 298.0, n_samples),
            'label': np.random.choice(['Rice', 'Maize', 'Jute', 'Cotton', 'Coconut', 'Papaya', 'Orange', 'Apple', 'Muskmelon', 'Watermelon', 'Grapes', 'Mango', 'Banana', 'Pomegranate', 'Lentil', 'Blackgram', 'Mungbean', 'Mothbeans', 'Pigeonpeas', 'Kidneybeans', 'Chickpea', 'Coffee'], n_samples)
        }
        df = pd.DataFrame(data)
    
    # 2. Handle missing values (simulate cleaning)
    df.fillna(df.mean(numeric_only=True), inplace=True)
    
    # 3. Separate features and target
    X = df.drop('label', axis=1)
    y = df['label']
    
    # 4. Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # 5. Feature Scaling
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Save the scaler for inference
    os.makedirs('../models', exist_ok=True)
    joblib.dump(scaler, '../models/crop_scaler.pkl')
    print("Saved crop_scaler.pkl")
    
    return X_train_scaled, X_test_scaled, y_train, y_test

def load_and_preprocess_fertilizer_data():
    """
    Simulates loading fertilizer dataset.
    """
    # Try to load real Kaggle Data
    current_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(current_dir, '..', 'data', 'Fertilizer Prediction.csv')
    
    if os.path.exists(csv_path):
        print(f"Loading real dataset from {csv_path}...")
        df = pd.read_csv(csv_path)
        # Typically Kaggle fertilizer dataset has columns: Temperature, Humidity, Moisture, Soil Type, Crop Type, Nitrogen, Potassium, Phosphorous, Fertilizer Name
        # We need to map it to our required input if needed, or assume it matches.
        # For this setup, we assume it has N, P, K, crop_type, fertilizer
        if 'Fertilizer Name' in df.columns:
            df.rename(columns={'Fertilizer Name': 'fertilizer', 'Nitrogen': 'N', 'Phosphorous': 'P', 'Potassium': 'K', 'Crop Type': 'crop_type'}, inplace=True)
            # Drop unnecessary columns if they exist
            cols_to_keep = ['N', 'P', 'K', 'crop_type', 'fertilizer']
            df = df[[c for c in cols_to_keep if c in df.columns]]
    else:
        print("Real dataset not found. Generating dummy data for Fertilizer Prediction...")
        np.random.seed(42)
        n_samples = 500
        
        data = {
            'N': np.random.randint(0, 100, n_samples),
            'P': np.random.randint(0, 100, n_samples),
            'K': np.random.randint(0, 100, n_samples),
            'crop_type': np.random.choice(['Rice', 'Maize', 'Cotton', 'Tobacco'], n_samples),
            'fertilizer': np.random.choice(['Urea', 'DAP', '14-35-14', '28-28', '10-26-26'], n_samples)
        }
        df = pd.DataFrame(data)
    
    # Convert categorical crop_type to numerical (simple Label Encoding for demonstration)
    df['crop_type'] = df['crop_type'].astype('category').cat.codes
    
    X = df.drop('fertilizer', axis=1)
    y = df['fertilizer']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    os.makedirs('../models', exist_ok=True)
    joblib.dump(scaler, '../models/fertilizer_scaler.pkl')
    print("Saved fertilizer_scaler.pkl")
    
    return X_train_scaled, X_test_scaled, y_train, y_test
