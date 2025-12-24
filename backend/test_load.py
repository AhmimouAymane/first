import os
import keras
import tensorflow as tf

print(f"TF Version: {tf.__version__}")
print(f"Keras Version: {keras.__version__}")
# Check if tf.keras is legacy
try:
    print(f"TF Keras Version: {tf.keras.__version__}")
except:
    print("TF Keras Version: Not found/AttributeError")

print("-" * 20)
print("Attempting keras.models.load_model...")
try:
    model = keras.models.load_model('ann-model.keras')
    print("✅ Success loading with keras.models.load_model")
except Exception as e:
    print(f"❌ Failed loading with keras: {e}")

print("-" * 20)
print("Attempting tf.keras.models.load_model...")
try:
    model2 = tf.keras.models.load_model('ann-model.keras')
    print("✅ Success loading with tf.keras.models.load_model")
except Exception as e:
    print(f"❌ Failed loading with tf.keras: {e}")
