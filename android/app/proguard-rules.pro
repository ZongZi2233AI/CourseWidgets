# Flutter相关混淆规则
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保持类名和方法名
-keepnames class * { public <methods>; }

# 保持序列化类
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保持R文件
-keep class **.R$* { *; }

# 保持BuildConfig
-keep class **.BuildConfig { *; }

# 保持自定义模型类
-keep class com.example.schedule_app.models.** { *; }
-keep class com.example.schedule_app.database.** { *; }

# 保持原生方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保持View构造函数
-keepclassmembers class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# 保持Activity构造函数
-keepclassmembers class * extends android.app.Activity {
    public <init>(...);
}

# 保持Fragment构造函数
-keepclassmembers class * extends android.app.Fragment {
    public <init>(...);
}

# 保持Parcelable实现类
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# 保持枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保持注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 保持JavaScript接口
-keepattributes JavascriptInterface

# 保持资源类
-keep class android.support.annotation.** { *; }
-keep class androidx.annotation.** { *; }

# 保持Kotlin相关
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# 保持Gson相关
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 保持SQLite相关
-keep class org.sqlite.** { *; }
-keep class org.sqlite.jdbc.** { *; }

# 忽略 Google Play Core 相关的缺失警告（解决你当前的报错）
-dontwarn com.google.android.play.core.**

# 如果你没有用到 Flutter 的延迟加载组件功能，直接忽略它们
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# 针对你日志中提到的 R8 构造函数警告的通用修复
-keepclassmembers class * {
    void <init>();
}