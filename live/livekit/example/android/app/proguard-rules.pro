-keep class com.tencent.** { *; }
-keep class com.tommy.rtmp.** { *; }
-dontwarn com.tencent.rtmp.ITXVodPlayListener$ITXVodAudioFrameDataListener
-dontwarn com.tencent.rtmp.TXVodDef$TXVodAudioFrameData
-dontwarn com.tencent.xmagic.XmagicApi$XmagicLightGameListener
-dontwarn com.tencent.xmagic.XmagicApi
-dontwarn com.tencent.live.beauty.custom.**
-dontwarn com.tommy.rtmp.**

# TencentEffect
-keep class com.tencent.xmagic.** { *;}
-keep class org.light.** { *;}
-keep class org.libpag.** { *;}
-keep class org.extra.** { *;}
-keep class com.gyailib.**{ *;}
-keep class com.tencent.cloud.iai.lib.** { *;}
-keep class com.tencent.beacon.** { *;}
-keep class com.tencent.qimei.** { *;}
-keep class androidx.exifinterface.** { *;}
-keep class com.tencent.effect.** { *;}

# keep Gson library
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.reflect.TypeToken$* { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**

# Keep all anonymous TypeToken subclasses (compiled from `new TypeToken<...>() {}`: XxxClass$1, XxxClass$2, ...)
# These anonymous classes are critical carriers for generic signatures and must NOT be removed or renamed by R8
-keep class **$* extends com.google.gson.reflect.TypeToken
