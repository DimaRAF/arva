# --- TensorFlow Lite core ---
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# --- Google / Firebase dependencies ---
-keep class com.google.** { *; }
-dontwarn com.google.**

# --- TensorFlow Lite GPU Delegate ---
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# --- Keep inner classes for GPU delegate ---
-keepclassmembers class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keepclassmembers class org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend { *; }

# --- Preserve annotations used by TFLite ---
-keepattributes *Annotation*