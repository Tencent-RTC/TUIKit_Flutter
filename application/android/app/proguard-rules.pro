-keep class com.tencent.** { *; }
-keep class com.tommy.rtmp.** { *; }
-dontwarn com.tencent.rtmp.ITXVodPlayListener$ITXVodAudioFrameDataListener
-dontwarn com.tencent.rtmp.TXVodDef$TXVodAudioFrameData
-dontwarn com.tencent.xmagic.XmagicApi$XmagicLightGameListener
-dontwarn com.tencent.xmagic.XmagicApi
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
