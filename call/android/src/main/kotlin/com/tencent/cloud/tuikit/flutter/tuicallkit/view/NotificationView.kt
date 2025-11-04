package com.tencent.cloud.tuikit.flutter.tuicallkit.view

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import com.bumptech.glide.request.transition.Transition
import com.bumptech.glide.request.target.CustomTarget
import com.tencent.liteav.base.Log
import com.tencent.cloud.tuikit.flutter.tuicallkit.R

class NotificationView(context: Context) {
    private val TAG = "IncomingNotificationView"
    private val channelID = "CallChannelId"
    private val notificationId = 9909

    private val context: Context
    private var remoteViews: RemoteViews? = null
    private val notificationManager: NotificationManager?
    private var notification: Notification? = null

    init {
        this.context = context
        notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?
    }

    fun showNotification(name: String, avatar: String, mediaType: MediaType) {
        createChannel()
        notification = createNotification()


        remoteViews!!.setTextViewText(R.id.tv_incoming_title, name)

        if (mediaType == MediaType.Video) {
            remoteViews!!.setTextViewText(R.id.tv_desc, "video call")
            remoteViews!!.setImageViewResource(
                R.id.img_media_type,
                R.drawable.tuicallkit_ic_video_incoming
            )
            remoteViews!!.setImageViewResource(
                R.id.btn_accept,
                R.drawable.tuicallkit_ic_dialing_video
            )
        } else {
            remoteViews!!.setTextViewText(R.id.tv_desc, "voice call")
            remoteViews!!.setImageViewResource(R.id.img_media_type, R.drawable.tuicallkit_ic_float)
            remoteViews!!.setImageViewResource(R.id.btn_accept, R.drawable.tuicallkit_bg_dialing)
        }

        Glide.with(context)
            .asBitmap()
            .load(Uri.parse(avatar))
            .diskCacheStrategy(DiskCacheStrategy.ALL)
            .placeholder(R.drawable.tuicallkit_ic_avatar)
            .apply(RequestOptions.bitmapTransform(RoundedCorners(15)))
            .into(object : CustomTarget<Bitmap>() {
                override fun onResourceReady(
                    resource: Bitmap,
                    transition: Transition<in Bitmap>?
                ) {
                    remoteViews!!.setImageViewBitmap(R.id.img_incoming_avatar, resource)
                    if (notificationManager != null) {
                        remoteViews!!.setImageViewBitmap(R.id.img_incoming_avatar, resource)
                        notificationManager.notify(notificationId, notification)
                    }
                }

                override fun onLoadFailed(errorDrawable: Drawable?) {
                    remoteViews!!.setImageViewResource(
                        R.id.img_incoming_avatar,
                        R.drawable.tuicallkit_ic_avatar
                    )
                    if (notificationManager != null) {
                        notificationManager.notify(notificationId, notification)
                    }
                }

                override fun onLoadCleared(placeholder: Drawable?) {
                    remoteViews!!.setImageViewResource(
                        R.id.img_incoming_avatar,
                        R.drawable.tuicallkit_ic_avatar
                    )
                }
            })
    }

    fun cancelNotification() {
        if (notificationManager != null) {
            notificationManager.cancel(notificationId)
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "CallChannel"
            val groupID = "CallGroupId"
            val groupName = "CallGroup"

            val channelGroup = NotificationChannelGroup(groupID, groupName)
            notificationManager!!.createNotificationChannelGroup(channelGroup)
            val channel = NotificationChannel(
                channelID, channelName,
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.setGroup(groupID)
            channel.enableLights(true)
            channel.setShowBadge(true)
            channel.setSound(null, null)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val builder = NotificationCompat.Builder(context, channelID)
            .setOngoing(true)
            .setWhen(System.currentTimeMillis())
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setTimeoutAfter(30 * 1000L)
            .setAutoCancel(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setCategory(NotificationCompat.CATEGORY_CALL)
            builder.setPriority(NotificationCompat.PRIORITY_MAX)
        }

        builder.setChannelId(channelID)
        builder.setSmallIcon(R.drawable.tuicallkit_ic_avatar)
        builder.setSound(null)

        remoteViews =
            RemoteViews(context.getPackageName(), R.layout.tuicallkit_incoming_notification_view)

        builder.setContentIntent(this.bgPendingIntent)
        remoteViews!!.setViewVisibility(R.id.btn_accept, View.GONE)
        remoteViews!!.setViewVisibility(R.id.btn_decline, View.GONE)

        builder.setCustomContentView(remoteViews)
        builder.setCustomBigContentView(remoteViews)
        return builder.build()
    }

    private val bgPendingIntent: PendingIntent?
        get() {
            val intentLaunchMain =
                context.getPackageManager().getLaunchIntentForPackage(context.getPackageName())
            if (intentLaunchMain != null) {
                intentLaunchMain.putExtra("show_in_foreground", true)
                intentLaunchMain.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                return PendingIntent.getActivity(
                    context,
                    0,
                    intentLaunchMain,
                    PendingIntent.FLAG_IMMUTABLE
                )
            } else {
                Log.e(TAG, "Failed to get launch intent for package: " + context.getPackageName())
                return PendingIntent.getActivity(context, 0, null, PendingIntent.FLAG_IMMUTABLE)
            }
        }

    companion object {
        private var sInstance: NotificationView? = null

        fun getInstance(context: Context): NotificationView {
            if (sInstance == null) {
                synchronized(NotificationView::class.java) {
                    if (sInstance == null) {
                        sInstance = NotificationView(context)
                    }
                }
            }
            return sInstance!!
        }

        enum class MediaType {
            Unknown,
            Audio,
            Video,
        }
    }
}