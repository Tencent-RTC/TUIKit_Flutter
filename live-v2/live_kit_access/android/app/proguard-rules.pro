-dontwarn kotlinx.parcelize.**
-dontwarn kotlinx.parcelize.Parcelize
-keep,allowobfuscation @interface kotlinx.parcelize.Parcelize

-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

-keep class io.trtc.tuikit.atomicxcore.** { *; }
-dontwarn io.trtc.tuikit.atomicxcore.**

-keep class com.tencent.** { *; }
-dontwarn com.tencent.**

-keep class com.tencent.liteav.** { *; }
-keep class com.tencent.rtmp.** { *; }
-keep class com.tencent.trtc.** { *; }
-dontwarn com.tencent.liteav.**
-dontwarn com.tencent.rtmp.**
-dontwarn com.tencent.trtc.**

-keepclassmembers class * {
    @kotlinx.parcelize.Parcelize *;
}
