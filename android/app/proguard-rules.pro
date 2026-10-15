# ONNX Runtime's native library looks up its Java classes, fields and
# methods by name over JNI. If R8 renames them, the first inference aborts
# the app (JNI GetMethodID failure in convertToTensorInfo).
-keep class ai.onnxruntime.** { *; }
