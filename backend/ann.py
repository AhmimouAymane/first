"""
ANN Model Backend for Flutter App
Handles 36-class fruit/vegetable classification
"""

import os
import tensorflow as tf
import numpy as np
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
import io
import base64

# ============================================
# ANN MODEL SETUP
# ============================================

def create_ann_model(input_shape=(28, 28, 3), num_classes=36):
    """
    Create the ANN model architecture
    """
    model = tf.keras.Sequential([
        tf.keras.layers.Flatten(input_shape=input_shape),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(num_classes)
    ])
    
    return model

def preprocess_image(image, target_size=(28, 28)):
    """
    Preprocess image for ANN model
    """
    # Resize to 28x28 (ANN input size)
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    image = image.resize(target_size)
    img_array = np.array(image)
    
    # Normalize to [0, 1]
    img_array = img_array / 255.0
    
    # Add batch dimension
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

# ============================================
# FLASK APPLICATION
# ============================================

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global variables
ann_model = None
class_names = []

def load_ann_model(model_path='models/ann-model.keras'):
    """
    Load the ANN model and class names
    """
    global ann_model, class_names
    
    try:
        # Load model
        ann_model = tf.keras.models.load_model(model_path)
        
        # Define class names (36 fruit/vegetable classes)
        class_names = [
            "Apple", "Banana", "Beetroot", "Bell Pepper", "Cabbage", 
            "Capsicum", "Carrot", "Cauliflower", "Chilli Pepper", "Corn", 
            "Cucumber", "Eggplant", "Garlic", "Ginger", "Grapes", 
            "Jalapeno", "Kiwi", "Lemon", "Lettuce", "Mango", 
            "Onion", "Orange", "Paprika", "Pear", "Peas", 
            "Pineapple", "Pomegranate", "Potato", "Raddish", "Soy Beans", 
            "Spinach", "Sweetcorn", "Sweetpotato", "Tomato", "Turnip", 
            "Watermelon"
        ]
        
        print(f"✅ ANN Model loaded successfully")
        print(f"✅ Class names: {len(class_names)} classes")
        return True
        
    except Exception as e:
        print(f"❌ Error loading ANN model: {str(e)}")
        return False

def predict_ann(image_file):
    """
    Make prediction using ANN model
    """
    try:
        # Open and preprocess image
        image = Image.open(io.BytesIO(image_file.read()))
        processed_image = preprocess_image(image)
        
        # Make prediction
        predictions = ann_model.predict(processed_image, verbose=0)
        
        # Apply softmax to get probabilities
        probabilities = tf.nn.softmax(predictions[0]).numpy()
        
        # Get top predictions
        top_indices = np.argsort(probabilities)[-5:][::-1]
        
        results = []
        for idx in top_indices:
            results.append({
                "class": class_names[idx],
                "confidence": float(probabilities[idx] * 100),
                "class_id": int(idx)
            })
        
        # Get primary prediction
        primary_idx = np.argmax(probabilities)
        primary_result = {
            "class": class_names[primary_idx],
            "confidence": float(probabilities[primary_idx] * 100),
            "class_id": int(primary_idx)
        }
        
        return {
            "success": True,
            "predictions": results,
            "primary": primary_result,
            "model_type": "ANN"
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model_type": "ANN"
        }

# ============================================
# API ENDPOINTS
# ============================================

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        "message": "ANN Classification API",
        "status": "running",
        "endpoints": {
            "/health": "Check server health",
            "/ann/classes": "Get available classes",
            "/ann/predict": "Classify image with ANN"
        }
    })

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "model_loaded": ann_model is not None,
        "model_type": "ANN"
    })

@app.route('/ann/classes')
def get_ann_classes():
    """Get ANN class names"""
    return jsonify({
        "classes": class_names,
        "count": len(class_names),
        "model_type": "ANN"
    })

@app.route('/ann/predict', methods=['POST'])
def ann_predict():
    """Classify image using ANN model"""
    try:
        # Check if model is loaded
        if ann_model is None:
            return jsonify({
                "success": False,
                "error": "ANN model not loaded",
                "model_type": "ANN"
            }), 500
        
        # Check if image is provided
        if 'image' not in request.files:
            return jsonify({
                "success": False,
                "error": "No image provided",
                "model_type": "ANN"
            }), 400
        
        image_file = request.files['image']
        
        # Check if file is empty
        if image_file.filename == '':
            return jsonify({
                "success": False,
                "error": "Empty file",
                "model_type": "ANN"
            }), 400
        
        # Make prediction
        result = predict_ann(image_file)
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "model_type": "ANN"
        }), 500

# ============================================
# MAIN EXECUTION
# ============================================

if __name__ == '__main__':
    # Load model on startup
    print("🚀 Starting ANN Flask Server...")
    
    # Load model (update path as needed)
    model_loaded = load_ann_model('ann-model.keras')
    
    if not model_loaded:
        print("⚠️  Creating new ANN model...")
        ann_model = create_ann_model()
        ann_model.save('ann-model.keras')
        print("✅ Created new ANN model")
    
    # Run Flask app
    print("✅ ANN API Server Ready!")
    print("📡 Running on: http://192.168.1.17:5000")
    print("🔗 Endpoints:")
    print("   • /health - Health check")
    print("   • /ann/classes - Get classes")
    print("   • /ann/predict - Classify image")
    
    app.run(host='0.0.0.0', port=5000, debug=True)