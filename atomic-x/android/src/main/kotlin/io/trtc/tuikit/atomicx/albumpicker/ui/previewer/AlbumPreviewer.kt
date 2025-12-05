package io.trtc.tuikit.atomicx.albumpicker.ui.previewer

import android.view.ViewGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Done
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import coil3.compose.AsyncImage
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import io.trtc.tuikit.atomicx.albumpicker.model.ImageBean
import io.trtc.tuikit.atomicx.albumpicker.ui.component.photoview.PhotoView
import io.trtc.tuikit.atomicx.albumpicker.ui.component.videoview.VideoView
import io.trtc.tuikit.atomicx.albumpicker.ui.picker.LocalAlbumPickerViewModel
import io.trtc.tuikit.atomicx.albumpicker.util.CoilImageLoader
import io.trtc.tuikit.atomicx.basecomponent.theme.Colors
import io.trtc.tuikit.atomicx.basecomponent.theme.LocalTheme

@Composable
fun PreviewContent(
    previewBean: BaseBean?,
    onDismiss: () -> Unit,
    onSendClick: () -> Unit
) {
    val selectedList by LocalAlbumPickerViewModel.current.selectedMediaListFlow.collectAsState()
    val currentBucket by LocalAlbumPickerViewModel.current.currentBucketFlow.collectAsState()
    var previewList = currentBucket.albumList
    var currentBean by remember { mutableStateOf(previewBean) }

    LaunchedEffect(selectedList) {
        if (previewBean == null && selectedList.isEmpty()) {
            onDismiss()
        }
    }

    if (previewBean == null) {
        previewList = selectedList
        if (previewList.isEmpty()) {
            LaunchedEffect(Unit) { onDismiss() }
            return
        }
        currentBean = previewList.first()
    }
////        Surface(
//            modifier = Modifier
//                .fillMaxSize()
//        ) {
    Scaffold(modifier = Modifier
        .background(color = Color(0xFF333333))
        .systemBarsPadding(), topBar = {
        PreviewHeader(onBackClick = { onDismiss() }, currentBean!!, previewList)
    }, bottomBar = {
        PreviewFooter(onSendClick)
    }) { padding ->
        if (previewList.isEmpty() || currentBean == null) {
            LaunchedEffect(Unit) { onDismiss() }
            return@Scaffold
        }
        Box(
            modifier = Modifier
                .background(color = Color(0xFF333333))
                .padding(padding)
        ) {
            PreviewContent(modifier = Modifier.fillMaxSize(), currentBean!!, previewList, onCurrentChanged = {
                currentBean = it
            })
            SelectedPhotos(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomStart), currentBean!!, {
                    if (it in previewList) {
                        currentBean = it
                    }
                }
            )
        }
    }
}

@Composable
fun PreviewHeader(onBackClick: () -> Unit, currentBean: BaseBean, previewList: List<BaseBean>) {
    val viewModel = LocalAlbumPickerViewModel.current
    val selectedList by viewModel.selectedMediaListFlow.collectAsState()
    val colors = LocalTheme.current.colors
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(color = Color(0xFF333333))
            .padding(16.dp)
    ) {
        Icon(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .size(24.dp)
                .clickable { onBackClick() },
            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
            contentDescription = "",
            tint = Colors.White1,
        )

        val totalSize = previewList.size
        val currentIndex = previewList.indexOf(currentBean) + 1
        Text(
            "${currentIndex}/${totalSize}",
            modifier = Modifier.align(Alignment.Center),
            fontSize = 16.sp,
            color = Colors.White1
        )

        Row(
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {
                    viewModel.toggleSelectMedia(currentBean)
                },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (selectedList.contains(currentBean)) {
                Icon(
                    imageVector = Icons.Filled.Done,
                    modifier = Modifier
                        .size(16.dp)
                        .background(color = colors.textColorLink, shape = CircleShape),
                    contentDescription = "",
                    tint = Colors.White1
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(16.dp)
                        .border(
                            width = 1.dp,
                            color = Color(0xFF999999),
                            shape = CircleShape
                        )
                )
            }
            Text(
                text = stringResource(R.string.album_picker_select),
                fontSize = 16.sp,
                color = Color(0xFFFFFFFF)
            )
        }

    }
}

@Composable
fun PreviewContent(
    modifier: Modifier = Modifier,
    currentBean: BaseBean,
    previewList: List<BaseBean>,
    onCurrentChanged: (BaseBean) -> Unit
) {
    Box(modifier = modifier) {
        val viewModel = LocalAlbumPickerViewModel.current
        val context = LocalContext.current
        val initIndex = previewList.indexOf(currentBean)
        val pagerState = rememberPagerState(initIndex.coerceAtLeast(0), pageCount = { previewList.size })
        LaunchedEffect(pagerState.currentPage) {
            if (previewList.isNotEmpty() && pagerState.currentPage in previewList.indices) {
                onCurrentChanged(previewList[pagerState.currentPage])
            }
        }
        LaunchedEffect(currentBean) {
            pagerState.scrollToPage(previewList.indexOf(currentBean).coerceAtLeast(0))
        }
        HorizontalPager(modifier = Modifier.fillMaxSize(), state = pagerState) {
            val baseBean = previewList[it]
            if (baseBean is ImageBean) {
                AndroidView(modifier = Modifier.fillMaxSize(), factory = { context ->
                    PhotoView(context).apply {
                        layoutParams = ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )

                        Glide.with(context)
                            .load(baseBean.getFinalUri())
                            .diskCacheStrategy(DiskCacheStrategy.NONE)
                            .skipMemoryCache(true)
                            .dontTransform()
                            .dontAnimate()
                            .into(this)
                    }
                })
            } else {
                Box() {
                    val videoView = remember { VideoView(context) }
                    var isPlaying by remember { mutableStateOf(false) }
                    DisposableEffect(Unit) {
                        onDispose {
                            videoView.stop()
                            videoView.resetVideo()
                            isPlaying = false
                        }
                    }
                    AndroidView(modifier = Modifier, factory = { context ->
                        videoView
                    }, update = {
                        videoView.setVideoURI(baseBean.getFinalUri())
                    })
                    if (!isPlaying) {
                        AsyncImage(
                            modifier = Modifier.fillMaxSize(),
                            model = baseBean,
                            imageLoader = CoilImageLoader.getInstance(context),
                            contentDescription = "",
                            contentScale = ContentScale.Crop
                        )
                        Icon(
                            imageVector = Icons.Default.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier
                                .size(80.dp)
                                .align(Alignment.Center)
                                .clickable {
                                    videoView.start()
                                    isPlaying = true
                                },
                            tint = Color(0xFFFFFFFF)
                        )
                    }

                }
            }
        }
    }
}

@Composable
fun SelectedPhotos(modifier: Modifier, currentBean: BaseBean, onItemClick: (BaseBean) -> Unit) {
    val viewModel = LocalAlbumPickerViewModel.current
    val selectedList by viewModel.selectedMediaListFlow.collectAsState()
    val colors = LocalTheme.current.colors
    LazyRow(
        modifier = modifier
            .background(color = Color(0xFF333333))
            .padding(vertical = 16.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        items(selectedList) { baseBean ->
            val isSelected = selectedList.contains(baseBean) && baseBean == currentBean
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .border(
                        width = if (isSelected) 1.5.dp else 0.dp,
                        color = if (isSelected) colors.textColorLink else Color.Transparent,
                        shape = RoundedCornerShape(0.dp)
                    )
                    .clickable {
                        onItemClick(baseBean)
                    }
            ) {
                AsyncImage(
                    imageLoader = CoilImageLoader.getInstance(context = LocalContext.current),
                    modifier = Modifier.fillMaxSize(),
                    model = baseBean,
                    contentDescription = "",
                    contentScale = ContentScale.Crop
                )
            }
        }
    }
}

@Composable
fun PreviewFooter(onSendClick: () -> Unit) {
    val viewModel = LocalAlbumPickerViewModel.current
    val selectedList by viewModel.selectedMediaListFlow.collectAsState()
    val colors = LocalTheme.current.colors
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(color = Color(0xFF333333))
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
//        Row(
//            modifier = Modifier
//                .align(Alignment.Center)
//                .clickable {
//                },
//            verticalAlignment = Alignment.CenterVertically,
//            horizontalArrangement = Arrangement.spacedBy(4.dp)
//        ) {
//            Box(
//                modifier = Modifier
//                    .size(16.dp)
//                    .border(
//                        width = 1.dp,
//                        color = Color(0xFF999999),
//                        shape = CircleShape
//                    )
//            )
//            Text(
//                text = stringResource(R.string.multimedia_plugin_picker_full_image),
//                fontSize = 16.sp,
//                color = Color(0xFFFFFFFF)
//            )
//        }

        Text(
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .background(
                    color = if (selectedList.isEmpty()) Color(0xFF555555) else colors.textColorLink,
                    shape = RoundedCornerShape(6.dp)
                )
                .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {
                    if (selectedList.isNotEmpty()) {
                        onSendClick()
                    }
                }
                .padding(horizontal = 10.dp, vertical = 4.dp),
            text = stringResource(R.string.album_picker_send) + if (selectedList.isEmpty()) "" else "(${selectedList.size})",
            lineHeight = 28.sp, fontSize = 16.sp,
            color = Color(0xFFFFFFFF)
        )
    }
}

