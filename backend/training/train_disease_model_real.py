"""
AgriSmart Disease Detection — Real Training Script
===================================================
Dataset: PlantVillage (auto-detected from training/PlantVillage/)
Run from: backend/
Command:  venv\Scripts\python.exe training/train_disease_model_real.py
"""

import os, sys, shutil
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# ── Config ────────────────────────────────────────────────────────────────────
IMG_SIZE   = (224, 224)
BATCH_SIZE = 16
EPOCHS     = 12
MAX_IMGS   = 500   # max images per class (keeps training fast)

BASE_DIR   = os.path.dirname(__file__)
MODEL_OUT  = os.path.join(BASE_DIR, '../models/disease_model.h5')
CLASSES_OUT= os.path.join(BASE_DIR, '../models/disease_classes.txt')

# Search both locations
DATASET_CANDIDATES = [
    os.path.join(BASE_DIR, 'PlantVillage', 'PlantVillage'),
    os.path.join(BASE_DIR, 'PlantVillage'),
]

# ── Display name mapping ──────────────────────────────────────────────────────
DISPLAY_NAMES = {
    'Pepper__bell___Bacterial_spot':               'Pepper Bacterial Spot',
    'Pepper__bell___healthy':                      'Healthy Pepper',
    'Potato___Early_blight':                       'Potato Early Blight',
    'Potato___Late_blight':                        'Potato Late Blight',
    'Potato___healthy':                            'Healthy Potato',
    'Tomato_Bacterial_spot':                       'Tomato Bacterial Spot',
    'Tomato_Early_blight':                         'Tomato Early Blight',
    'Tomato_Late_blight':                          'Tomato Late Blight',
    'Tomato_Leaf_Mold':                            'Tomato Leaf Mold',
    'Tomato_Septoria_leaf_spot':                   'Tomato Septoria Leaf Spot',
    'Tomato_Spider_mites_Two_spotted_spider_mite': 'Tomato Spider Mites',
    'Tomato__Target_Spot':                         'Tomato Target Spot',
    'Tomato__Tomato_mosaic_virus':                 'Tomato Mosaic Virus',
    'Tomato__Tomato_YellowLeaf__Curl_Virus':       'Tomato Yellow Leaf Curl Virus',
    'Tomato_healthy':                              'Healthy Tomato',
    # Apple (if present)
    'Apple___Apple_scab':                          'Apple Scab',
    'Apple___Black_rot':                           'Apple Black Rot',
    'Apple___Cedar_apple_rust':                    'Apple Cedar Rust',
    'Apple___healthy':                             'Healthy Apple',
    # Corn
    'Corn_(maize)___Common_rust_':                 'Corn Common Rust',
    'Corn_(maize)___Northern_Leaf_Blight':         'Corn Northern Blight',
    'Corn_(maize)___healthy':                      'Healthy Corn',
}

def find_dataset():
    for path in DATASET_CANDIDATES:
        if os.path.exists(path):
            folders = [f for f in os.listdir(path) if os.path.isdir(os.path.join(path, f))]
            if folders:
                print(f"✅ Dataset found at: {path}")
                return path, folders
    print("❌ Dataset not found! Place PlantVillage folder in backend/training/")
    sys.exit(1)

def prepare_split(dataset_path, folders):
    tmp_dir   = os.path.join(BASE_DIR, '_tmp_train')
    train_dir = os.path.join(tmp_dir, 'train')
    val_dir   = os.path.join(tmp_dir, 'val')
    if os.path.exists(tmp_dir):
        shutil.rmtree(tmp_dir)

    classes_used = []
    for folder in sorted(folders):
        display = DISPLAY_NAMES.get(folder, folder.replace('_', ' ').replace('  ', ' '))
        src = os.path.join(dataset_path, folder)
        imgs = sorted([f for f in os.listdir(src) if f.lower().endswith(('.jpg','.jpeg','.png'))])
        if not imgs:
            continue
        imgs = imgs[:MAX_IMGS]
        split = int(len(imgs) * 0.8)
        train_imgs, val_imgs = imgs[:split], imgs[split:]

        for subdir, img_list in [(train_dir, train_imgs), (val_dir, val_imgs)]:
            dest = os.path.join(subdir, display)
            os.makedirs(dest, exist_ok=True)
            for img in img_list:
                shutil.copy(os.path.join(src, img), os.path.join(dest, img))

        classes_used.append(display)
        print(f"   {display}: {len(train_imgs)} train + {len(val_imgs)} val")

    return tmp_dir, train_dir, val_dir, classes_used

def build_model(num_classes):
    base = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224,224,3))
    base.trainable = False
    x = base.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu')(x)
    x = Dropout(0.4)(x)
    x = Dense(128, activation='relu')(x)
    x = Dropout(0.3)(x)
    out = Dense(num_classes, activation='softmax')(x)
    model = Model(inputs=base.input, outputs=out)
    model.compile(optimizer=Adam(0.001), loss='categorical_crossentropy', metrics=['accuracy'])
    return model, base

def train():
    print("=" * 55)
    print("  AgriSmart Disease Model — Training Started")
    print("=" * 55)

    dataset_path, folders = find_dataset()
    print(f"\n📁 Found {len(folders)} disease classes. Preparing split...")
    tmp_dir, train_dir, val_dir, classes_used = prepare_split(dataset_path, folders)
    num_classes = len(classes_used)
    print(f"\n✅ {num_classes} classes ready.")

    train_gen = ImageDataGenerator(
        rescale=1./255, rotation_range=20,
        width_shift_range=0.1, height_shift_range=0.1,
        horizontal_flip=True, zoom_range=0.15,
        brightness_range=[0.85, 1.15],
    )
    val_gen = ImageDataGenerator(rescale=1./255)

    train_data = train_gen.flow_from_directory(
        train_dir, target_size=IMG_SIZE,
        batch_size=BATCH_SIZE, class_mode='categorical', shuffle=True
    )
    val_data = val_gen.flow_from_directory(
        val_dir, target_size=IMG_SIZE,
        batch_size=BATCH_SIZE, class_mode='categorical', shuffle=False
    )

    # Save class order matching Keras
    idx_to_class = {v: k for k, v in train_data.class_indices.items()}
    ordered_classes = [idx_to_class[i] for i in range(num_classes)]

    print(f"\n🧠 Building MobileNetV2 model ({num_classes} classes)...")
    model, base = build_model(num_classes)

    os.makedirs(os.path.dirname(MODEL_OUT), exist_ok=True)
    callbacks = [
        EarlyStopping(monitor='val_accuracy', patience=4, restore_best_weights=True, verbose=1),
        ModelCheckpoint(MODEL_OUT, monitor='val_accuracy', save_best_only=True, verbose=1),
        ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=2, verbose=1),
    ]

    print(f"\n🚀 Phase 1: Training top layers ({EPOCHS} epochs)...")
    model.fit(train_data, validation_data=val_data, epochs=EPOCHS, callbacks=callbacks)

    print("\n🔧 Phase 2: Fine-tuning last 30 layers...")
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False
    model.compile(optimizer=Adam(0.0001), loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_data, validation_data=val_data, epochs=5, callbacks=callbacks)

    # Save class list
    with open(CLASSES_OUT, 'w') as f:
        f.write('\n'.join(ordered_classes))

    loss, acc = model.evaluate(val_data, verbose=0)
    print(f"\n📊 Final Validation Accuracy: {acc*100:.1f}%")
    print(f"✅ Model saved → {MODEL_OUT}")
    print(f"✅ Classes saved → {CLASSES_OUT}")

    shutil.rmtree(tmp_dir, ignore_errors=True)
    print(f"\n🎉 Done! Restart uvicorn to use new model.")

if __name__ == '__main__':
    train()
