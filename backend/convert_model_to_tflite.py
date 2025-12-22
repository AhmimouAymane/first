import tensorflow as tf
import os

# Load your Keras model
print("Loading Keras model...")
model = tf.keras.models.load_model('models/CNN-model.keras')

print(f"Model loaded successfully!")
print(f"Input shape: {model.input_shape}")
print(f"Output shape: {model.output_shape}")

# Convert to TensorFlow Lite
print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Optional: Optimize the model
# converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convert the model
tflite_model = converter.convert()

# Save the TFLite model
output_path = 'models/cnn_model.tflite'
with open(output_path, 'wb') as f:
    f.write(tflite_model)

print(f"\n✅ TFLite model saved to: {output_path}")
print(f"File size: {os.path.getsize(output_path) / 1024 / 1024:.2f} MB")

# Optional: Test the converted model
print("\n📊 Testing converted model...")
interpreter = tf.lite.Interpreter(model_path=output_path)
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input shape: {input_details[0]['shape']}")
print(f"Input type: {input_details[0]['dtype']}")
print(f"Output shape: {output_details[0]['shape']}")
print(f"Output type: {output_details[0]['dtype']}")

print("\n✅ Conversion complete!")
print("Next steps:")
print("1. Copy 'models/cnn_model.tflite' to 'assets/models/' in your Flutter project")
print("2. Create 'assets/models/labels.txt' with class names")
print("3. Update pubspec.yaml to include the assets")