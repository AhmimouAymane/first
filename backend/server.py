"""
Unified Flask Server for ANN and CNN Models
Combines both models into a single API server
"""

import os
import tensorflow as tf
import keras
import numpy as np
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS

import io
from sklearn.preprocessing import MinMaxScaler
from PyPDF2 import PdfReader
from langchain_text_splitters import CharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain_huggingface import HuggingFaceEndpoint
from langchain_ollama import ChatOllama
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# ============================================
# FLASK APPLICATION
# ============================================

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global variables
ann_model = None
cnn_model = None
stock_model = None
class_names = []

# RAG Global Variables
vector_store = None
rag_chain = None
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") 
HF_TOKEN = os.getenv("HUGGINGFACEHUB_API_TOKEN")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# ============================================
# MODEL LOADING
# ============================================

def load_models():
    """Load ANN, CNN, and Stock Predictor models"""
    global ann_model, cnn_model, stock_model, class_names
    
    print("📋 Starting model loading sequence...")
    try:
        # Load ANN model
        print("⌛ Loading ANN Model (ann-model.keras)...")
        ann_model = keras.models.load_model('ann-model.keras')
        print("✅ ANN Model loaded successfully")
        
        # Load CNN model
        print("⌛ Loading CNN Model (models/CNN-model.keras)...")
        cnn_model = keras.models.load_model('models/CNN-model.keras')
        print("✅ CNN Model loaded successfully")

        # Load Stock model
        print("⌛ Loading Stock Predictor (models/stock_price_predictor_model.keras)...")
        stock_model = keras.models.load_model('models/stock_price_predictor_model.keras')
        print(f"✅ Stock Price Predictor Model loaded successfully: {stock_model is not None}")
        
        # Define class names (36 fruit/vegetable classes)
        class_names = [
            'apple', 'banana', 'beetroot', 'bell pepper', 'cabbage', 'capsicum',
            'carrot', 'cauliflower', 'chilli pepper', 'corn', 'cucumber', 'eggplant',
            'garlic', 'ginger', 'grapes', 'jalepeno', 'kiwi', 'lemon', 'lettuce',
            'mango', 'onion', 'orange', 'paprika', 'pear', 'peas', 'pineapple',
            'pomegranate', 'potato', 'raddish', 'soy beans', 'spinach', 'sweetcorn',
            'sweetpotato', 'tomato', 'turnip', 'watermelon'
        ]
        
        print(f"✅ Class names: {len(class_names)} classes")
        return True
        
    except Exception as e:
        print(f"❌ Error loading models: {str(e)}")
        return False

# ============================================
# IMAGE PREPROCESSING
# ============================================

def preprocess_image_ann(image, target_size=(28, 28)):
    """Preprocess image for ANN model"""
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    image = image.resize(target_size)
    img_array = np.array(image) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

def preprocess_image_cnn(image, target_size=(224, 224)):
    """Preprocess image for CNN model"""
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    image = image.resize(target_size)
    img_array = np.array(image) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    
    return img_array

# ============================================
# PREDICTION FUNCTIONS
# ============================================

def predict_with_model(image_bytes, model, preprocess_fn, model_type):
    """Make prediction using specified model"""
    try:
        # Open and preprocess image
        image = Image.open(io.BytesIO(image_bytes))
        processed_image = preprocess_fn(image)
        
        # Make prediction
        predictions = model.predict(processed_image, verbose=0)
        
        # Apply softmax to get probabilities
        probabilities = tf.nn.softmax(predictions[0]).numpy()
        
        # Get top 3 predictions
        top_indices = np.argsort(probabilities)[-3:][::-1]
        
        top_predictions = []
        for idx in top_indices:
            top_predictions.append({
                "class": class_names[idx],
                "confidence": float(probabilities[idx]),
                "index": int(idx)
            })
        
        # Get primary prediction
        primary_idx = np.argmax(probabilities)
        
        return {
            "success": True,
            "label": class_names[primary_idx],
            "confidence": float(probabilities[primary_idx]),
            "class_index": int(primary_idx),
            "top_predictions": top_predictions,
            "model_type": model_type
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model_type": model_type
        }

# ============================================
# API ENDPOINTS
# ============================================

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        "message": "Fruit & Vegetable Classification API",
        "status": "running",
        "models": {
            "ann": ann_model is not None,
            "cnn": cnn_model is not None
        },
        "endpoints": {
            "/health": "Check server health",
            "/classes": "Get available classes",
            "/ann/predict": "Classify image with ANN",
            "/cnn/predict": "Classify image with CNN"
        }
    })

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "ann_loaded": ann_model is not None,
        "cnn_loaded": cnn_model is not None
    })

@app.route('/classes')
def get_classes():
    """Get class names"""
    return jsonify({
        "classes": class_names,
        "count": len(class_names)
    })

@app.route('/ann/predict', methods=['POST'])
def ann_predict():
    """Classify image using ANN model"""
    try:
        if ann_model is None:
            return jsonify({
                "success": False,
                "error": "ANN model not loaded"
            }), 500
        
        if 'image' not in request.files:
            return jsonify({
                "success": False,
                "error": "No image provided"
            }), 400
        
        image_file = request.files['image']
        image_bytes = image_file.read()
        
        result = predict_with_model(image_bytes, ann_model, preprocess_image_ann, "ANN")
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/cnn/predict', methods=['POST'])
def cnn_predict():
    """Classify image using CNN model"""
    try:
        if cnn_model is None:
            return jsonify({
                "success": False,
                "error": "CNN model not loaded"
            }), 500
        
        if 'image' not in request.files:
            return jsonify({
                "success": False,
                "error": "No image provided"
            }), 400
        
        image_file = request.files['image']
        image_bytes = image_file.read()
        
        result = predict_with_model(image_bytes, cnn_model, preprocess_image_cnn, "CNN")
        
        if result['success']:
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/stock/predict', methods=['POST'])
def stock_predict():
    """Predict stock price based on 60 historic values"""
    try:
        if stock_model is None:
            return jsonify({
                "success": False,
                "error": "Stock model not loaded"
            }), 500
        
        data = request.json
        if not data or 'history' not in data:
            return jsonify({
                "success": False,
                "error": "No history data provided"
            }), 400
        
        custom_input = data['history']
        
        if len(custom_input) != 60:
            return jsonify({
                "success": False,
                "error": f"Expected 60 values, got {len(custom_input)}"
            }), 400

        # Preprocessing as provided by user
        sc = MinMaxScaler(feature_range=(0, 1))
        custom_input_scaled = sc.fit_transform(np.array(custom_input).reshape(-1, 1))
        
        # Prepare for prediction
        X_custom = custom_input_scaled.reshape(1, 60, 1)
        
        # Predict
        predicted_price_scaled = stock_model.predict(X_custom, verbose=0)
        
        # Inverse transform
        predicted_price = sc.inverse_transform(predicted_price_scaled)
        
        result = float(predicted_price[0][0])
        print(f"📈 Stock Prediction: {result}")
        
        return jsonify({
            "success": True,
            "prediction": result
        })
            
    except Exception as e:
        print(f"❌ Stock Prediction Error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# ============================================
# MAIN EXECUTION
# ============================================

# ============================================
# RAG ENDPOINTS
# ============================================

@app.route('/rag/process', methods=['POST'])
def rag_process():
    """Process uploaded PDFs and create vector store"""
    global vector_store
    
    try:
        if 'files' not in request.files:
            return jsonify({"success": False, "error": "No files provided"}), 400
        
        files = request.files.getlist('files')
        pdf_content = ""
        
        for file in files:
            if file.filename.endswith('.pdf'):
                pdf_reader = PdfReader(file)
                for page in pdf_reader.pages:
                    pdf_content += page.extract_text()
        
        if not pdf_content.strip():
            return jsonify({"success": False, "error": "No text found in PDFs"}), 400

        # Chunking
        text_splitter = CharacterTextSplitter(
            separator="\n",
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
        )
        chunks = text_splitter.split_text(pdf_content)
        
        # Embeddings
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-mpnet-base-v2"
        )
        
        # Vector Store (FAISS)
        vector_store = FAISS.from_texts(
            texts=chunks,
            embedding=embeddings
        )
        
        print(f"✅ RAG: Created {len(chunks)} chunks and updated vector store")
        return jsonify({
            "success": True, 
            "message": f"Processed {len(files)} files into {len(chunks)} chunks"
        })
            
    except Exception as e:
        print(f"❌ RAG processing error: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/rag/query', methods=['POST'])
def rag_query():
    """Query the RAG system"""
    global vector_store
    
    try:
        if vector_store is None:
            return jsonify({"success": False, "error": "No documents processed yet"}), 400
        
        data = request.json
        question = data.get('question')
        if not question:
            return jsonify({"success": False, "error": "No question provided"}), 400

        # Similarity Search
        docs = vector_store.similarity_search(question, k=3)
        context = "\n\n".join([doc.page_content for doc in docs])
        
        # Prompt
        prompt_template = """
        Answer the following question based only on the provided context.
        Think step by step before providing a detailed answer.
        
        Context: {context}
        
        Question: {question}
        
        Answer:"""
        
        full_prompt = prompt_template.format(context=context, question=question)
        
        # Generation with Ollama (Local Llama) as primary
        response_text = ""
        try:
            print("🤖 RAG: Generating response with local Ollama (llama3.2)...")
            llm = ChatOllama(
                model="llama3.2", # Matching user's snippet
                temperature=0.7,
            )
            
            # Using the prompt from user snippet
            prompt = ChatPromptTemplate.from_template("""
            Answer the following question based only on the provided context.
            Think step by step before providing a detailed answer.
            
            Context: {context}
            
            Question: {question}
            
            Answer:""")
            
            chain = prompt | llm | StrOutputParser()
            response_text = chain.invoke({"context": context, "question": question})
            
        except Exception as ollama_e:
            print(f"⚠️ RAG: Ollama failed: {str(ollama_e)}. Trying HuggingFace fallback...")
            if HF_TOKEN:
                try:
                    llm = HuggingFaceEndpoint(
                        repo_id="HuggingFaceH4/zephyr-7b-beta",
                        task="text-generation",
                        max_new_tokens=512,
                        temperature=0.7,
                        huggingfacehub_api_token=HF_TOKEN
                    )
                    chain = prompt | llm | StrOutputParser()
                    response_text = chain.invoke({"context": context, "question": question})
                except Exception as hf_e:
                    print(f"⚠️ RAG: HuggingFace also failed: {str(hf_e)}. Trying Gemini fallback...")
                    # Gemini fallback if both local and HF fail
                    if GEMINI_API_KEY:
                        try:
                            model = genai.GenerativeModel('gemini-1.5-flash')
                            response = model.generate_content(full_prompt)
                            response_text = response.text
                        except Exception as gemini_e:
                            response_text = f"❌ All AI models failed. Last error: {str(gemini_e)}"
                    else:
                        response_text = f"❌ AI Generation failed and no Gemini API key provided."
            else:
                response_text = f"❌ Ollama error: {str(ollama_e)} (and no HuggingFace token found)"

        return jsonify({
            "success": True,
            "answer": response_text,
            "context_used": context[:500] 
        })
            
    except Exception as e:
        print(f"❌ RAG query error: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Starting Unified Flask Server...")
    print("=" * 60)
    
    # Load models on startup
    models_loaded = load_models()
    
    if not models_loaded:
        print("⚠️  Warning: Some models failed to load")
    
    # Run Flask app
    print("=" * 60)
    print("✅ API Server Ready!")
    print("📡 Running on: http://localhost:5000")
    print("=" * 60)
    print("🔗 Endpoints:")
    print("   • GET  /health - Health check")
    print("   • GET  /classes - Get classes")
    print("   • POST /ann/predict - ANN prediction")
    print("   • POST /cnn/predict - CNN prediction")
    print("   • POST /stock/predict - Stock price prediction")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)