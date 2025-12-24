import tensorflow as tf
import os

models_to_load = [
    ('ANN', 'ann-model.keras'),
    ('CNN', 'models/CNN-model.keras'),
    ('Stock', 'models/stock_price_predictor_model.keras')
]

for name, path in models_to_load:
    print(f"⌛ Attempting to load {name} from {path}...")
    try:
        if os.path.exists(path):
            model = tf.keras.models.load_model(path)
            print(f"✅ {name} loaded successfully!")
        else:
            print(f"❌ {name} file NOT FOUND at {path}")
    except Exception as e:
        print(f"❌ {name} loading failed: {str(e)}")
