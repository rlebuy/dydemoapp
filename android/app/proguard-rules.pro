# Mantener clases del paquete mailer y dependencias SMTP
-keep class com.sun.mail.** { *; }
-keep class javax.mail.** { *; }
-keep class javax.activation.** { *; }
-dontwarn com.sun.mail.**
-dontwarn javax.mail.**
-dontwarn javax.activation.**

# Mantener clases de Dart/Flutter que usan reflexión
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
