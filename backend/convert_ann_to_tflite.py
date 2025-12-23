import tensorflow as tf
import os

# Load the Keras model
print("Loading ANN Keras model...")
try:
    model = tf.keras.models.load_model('ann-model.keras')
    print("✅ Model loaded successfully!")
    print(f"Input shape: {model.input_shape}")
    
    # Convert to TensorFlow Lite
    print("\nConverting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    # Save the TFLite model
    output_path = 'ann_model.tflite'
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
        
    print(f"\n✅ TFLite model saved to: {output_path}")
    print(f"File size: {os.path.getsize(output_path) / 1024:.2f} KB")

except Exception as e:
    print(f"❌ Error: {str(e)}")
