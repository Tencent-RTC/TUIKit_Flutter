package io.trtc.tuikit.atomicx.albumpicker.ui.picker

import android.os.Bundle
import android.os.Parcelable
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import androidx.lifecycle.ViewModelProvider
import coil3.compose.AsyncImage
import coil3.request.ImageRequest
import com.tencent.qcloud.tuicore.TUICore
import com.tencent.qcloud.tuicore.permission.PermissionCallback
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerConfig
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import io.trtc.tuikit.atomicx.albumpicker.model.BucketBean
import io.trtc.tuikit.atomicx.albumpicker.model.VideoBean
import io.trtc.tuikit.atomicx.albumpicker.permission.ImageVideoPermissionRequester
import io.trtc.tuikit.atomicx.albumpicker.ui.previewer.PreviewContent
import io.trtc.tuikit.atomicx.albumpicker.util.CoilImageLoader
import io.trtc.tuikit.atomicx.albumpicker.util.DateTimeUtil
import io.trtc.tuikit.atomicx.albumpicker.viewmodels.AlbumPickerViewModel
import io.trtc.tuikit.atomicx.albumpicker.viewmodels.AlbumPickerViewModelFactory
import io.trtc.tuikit.atomicx.basecomponent.basiccontrols.FullScreenDialog
import io.trtc.tuikit.atomicx.basecomponent.theme.LocalTheme
import kotlin.math.roundToInt

val LocalAlbumPickerViewModel = compositionLocalOf<AlbumPickerViewModel> { error("AlbumPickerViewModel not found") }

class AlbumPickerActivity : AppCompatActivity() {

    private var eventKey: String? = null
    private var eventSubKey: String? = null
    private var configBean: AlbumPickerConfig = AlbumPickerConfig()
    private val albumPickerViewModel by lazy {
        ViewModelProvider(
            this@AlbumPickerActivity,
            AlbumPickerViewModelFactory(configBean)
        )[AlbumPickerViewModel::class.java]
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent == null) {
            finish()
            return
        }

        eventKey = intent.getStringExtra("eventKey")
        eventSubKey = intent.getStringExtra("eventSubKey")
        configBean = intent.getParcelableExtra<Parcelable>("config") as? AlbumPickerConfig ?: AlbumPickerConfig()

        checkPermissionAndLoad(albumPickerViewModel)
        enableEdgeToEdge()

        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.isAppearanceLightStatusBars = false
        windowInsetsController.isAppearanceLightNavigationBars = false
        setContent {

            CompositionLocalProvider(LocalAlbumPickerViewModel provides albumPickerViewModel) {

                Column(
                    modifier = Modifier
                        .background(color = Color(0xFF333333))
                        .statusBarsPadding()
                ) {
                    var showBucketListPop by remember { mutableStateOf(false) }
                    var showPreviewDialog by remember { mutableStateOf(false) }
                    var currentClickBean by remember { mutableStateOf<BaseBean?>(null) }
                    PickerHeader(showBucketListPop, {
                        finish()
                    }, {
                        showBucketListPop = !showBucketListPop
                    })
                    Box() {
                        Column(modifier = Modifier.navigationBarsPadding()) {
                            AlbumGrid(
                                modifier = Modifier.weight(1f),
                                spanCount = configBean?.gridCount ?: 4,
                                onItemClick = {
                                    currentClickBean = it
                                    showPreviewDialog = true
                                })
                            PickerFooter(onPreviewClick = {
                                currentClickBean = null
                                showPreviewDialog = true
                            }, onSendClick = {
                                setSelectionResult()
                            })
                        }
                        if (showBucketListPop) {
                            BucketListPop(showBucketListPop, {
                                albumPickerViewModel.selectBucket(it.bucketName)
                                showBucketListPop = false
                            })
                        }
                    }

                    if (showPreviewDialog) {
                        FullScreenDialog(onDismissRequest = { showPreviewDialog = false }) {
                            CompositionLocalProvider(LocalAlbumPickerViewModel provides albumPickerViewModel) {
                                PreviewContent(
                                    previewBean = currentClickBean, onDismiss =
                                        { showPreviewDialog = false }, onSendClick = { setSelectionResult() })
                            }
                        }
                    }
                }
            }
        }
    }

    private fun checkPermissionAndLoad(albumPickerViewModel: AlbumPickerViewModel) {
        if (ImageVideoPermissionRequester.checkPermission()) {
            albumPickerViewModel.loadImageVideo()
        } else {
            ImageVideoPermissionRequester.requestPermissions(object : PermissionCallback() {
                override fun onGranted() {
                    albumPickerViewModel.loadImageVideo()
                }
            })
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        TUICore.notifyEvent(eventKey, eventSubKey, null)
    }

    companion object {
        private const val TAG = "AlbumSelectorActivity"
        private const val DEFAULT_ANIM_DURATION = 200
    }

    fun setSelectionResult() {

//        val isFullImage = this.isFullImage
//        val selectedList = albumGridView!!.selectedPhotoList
//        if (isFullImage) {
//            for (baseBean in selectedList) {
//                originalUris.add(baseBean.getFinalUri())
//            }
//        } else {
//            for (baseBean in selectedList) {
//                if (baseBean is VideoBean) {
//                    if (baseBean.editedUri == null) {
//                        transcodeList.add(baseBean.uri)
//                    } else {
//                        originalUris.add(baseBean.editedUri)
//                    }
//                } else {
//                    originalUris.add(baseBean.getFinalUri())
//                }
//            }
//        }
        val hashMap = HashMap<String, Any>()
        hashMap["data"] = albumPickerViewModel.selectedMediaListFlow.value.map { it.getFinalUri() }
//                hashMap["transcodeData"] = transcodeList
        TUICore.notifyEvent(eventKey, eventSubKey, hashMap)
        finish()
    }
}

@Composable
fun PickerHeader(
    showBucketListPop: Boolean,
    onBackClick: () -> Unit,
    onBuckedListClick: () -> Unit,
) {
    val viewModel = LocalAlbumPickerViewModel.current
    val currentBucketBean by viewModel.currentBucketFlow.collectAsState()
    var rotationAngle by remember { mutableStateOf(0f) }
    LaunchedEffect(showBucketListPop) {
        rotationAngle += 180f
    }
    val rotation by animateFloatAsState(
        targetValue = rotationAngle,
        animationSpec = tween(
            durationMillis = 200,
            easing = LinearEasing
        ),
        label = "rotation"
    )

    Box(
        Modifier
            .fillMaxWidth()
            .padding(10.dp)
    ) {
        Icon(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .size(28.dp)
                .clickable { onBackClick() },
            imageVector = Icons.Default.Close,
            contentDescription = "", tint = Color.White
        )

        Row(
            modifier = Modifier
                .align(Alignment.Center)
                .background(color = Color(0xFF555555), shape = CircleShape)
                .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {
                    onBuckedListClick()
                }
                .padding(start = 10.dp, end = 3.dp, top = 3.dp, bottom = 3.dp),

            ) {
            Text(
                text = currentBucketBean.bucketName,
                fontSize = 16.sp,
                color = Color(0xFFFFFFFF)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Icon(
                modifier = Modifier
                    .size(20.dp)
                    .background(color = Color(0xFFAAAAAA), shape = CircleShape)
                    .graphicsLayer {
                        rotationZ = rotation
                    },
                imageVector = Icons.Default.KeyboardArrowDown,
                contentDescription = ""
            )
        }
    }
}

@Composable
fun AlbumGrid(modifier: Modifier = Modifier, spanCount: Int, onItemClick: (BaseBean) -> Unit) {
    val viewModel = LocalAlbumPickerViewModel.current
    val bucketBean by viewModel.currentBucketFlow.collectAsState()
    val albumList = bucketBean.albumList
    Box(modifier = modifier.fillMaxSize()) {
        LazyVerticalGrid(
            GridCells.Fixed(spanCount),
            verticalArrangement = Arrangement.spacedBy(2.dp),
            horizontalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            items(albumList) {
                AlbumItem(it, onItemClick)
            }
        }
    }
}

@Composable
fun AlbumItem(baseBean: BaseBean, onItemClick: (BaseBean) -> Unit) {
    val viewModel = LocalAlbumPickerViewModel.current
    val colors = LocalTheme.current.colors
    val selectedMediaList by viewModel.selectedMediaListFlow.collectAsState()
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clickable {
                onItemClick(baseBean)
            }

    ) {

        AsyncImage(
            imageLoader = CoilImageLoader.getInstance(context = LocalContext.current),
            model = ImageRequest.Builder(LocalContext.current)
                .data(baseBean)
                .size(250, 250)
                .build(),
            modifier = Modifier.fillMaxSize(),
            contentDescription = "", contentScale = ContentScale.Crop
        )
        if (baseBean is VideoBean) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(4.dp)
            ) {
                Text(
                    text = DateTimeUtil.formatTime((baseBean.duration / 1000f).roundToInt()),
                    color = Color.White,
                    fontSize = 10.sp
                )
            }
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(color = if (selectedMediaList.contains(baseBean)) Color(0x88000000) else Color(0x26000000))
        )

        Box(
            modifier = Modifier
                .wrapContentSize()
                .padding(3.dp)
                .align(Alignment.TopEnd)
                .clickable {
                    viewModel.toggleSelectMedia(baseBean)
                }
        ) {
            if (selectedMediaList.contains(baseBean)) {
                Text(
                    text = "${selectedMediaList.indexOf(baseBean) + 1}",
                    fontSize = 12.sp, lineHeight = 24.sp,
                    textAlign = TextAlign.Center,
                    color = Color(0xFFFFFFFF),
                    modifier = Modifier
                        .size(24.dp)
                        .align(Alignment.Center)
                        .background(color = colors.textColorLink, shape = CircleShape)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .align(Alignment.TopEnd)
                        .border(
                            width = 1.dp,
                            color = Color(0xFF999999),
                            shape = CircleShape
                        )
                )
            }
        }
    }
}

@Composable
fun PickerFooter(
    onPreviewClick: () -> Unit, onSendClick: () -> Unit
) {
    val viewModel = LocalAlbumPickerViewModel.current
    val selectedList by viewModel.selectedMediaListFlow.collectAsState()
    val colors = LocalTheme.current.colors
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp)
            .padding(horizontal = 16.dp)
    ) {
        Text(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {
                    if (selectedList.isNotEmpty()) {
                        onPreviewClick()
                    }
                },
            text = if (selectedList.isEmpty()) stringResource(R.string.album_picker_preview) else stringResource(
                R.string.album_picker_preview
            ) + "(${selectedList.size})",
            fontSize = 16.sp,
            color =
                if (selectedList.isEmpty()) Color(0xFF999999) else Color(0xFFFFFFFF)
        )

//        Row(
//            modifier = Modifier
//                .align(Alignment.Center)
//                .clickable {
//                }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)
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
            lineHeight = 28.sp,
            fontSize = 16.sp,
            color = Color(0xFFFFFFFF)
        )
    }

}

@Composable
fun BucketListPop(
    showBucketListPop: Boolean,
    onItemClick: (BucketBean) -> Unit
) {

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(color = Color(0xCC000000))

    ) {
        val viewModel = LocalAlbumPickerViewModel.current
        val bucketBeanList by viewModel.bucketBeanListFlow.collectAsState()
        LazyColumn(
            modifier = Modifier
                .background(color = Color(0xFF333333))
                .widthIn(maxWidth * 0.9f)
        ) {
            items(bucketBeanList) {
                BucketItem(it, onItemClick)
            }
        }
    }
}

@Composable
fun BucketItem(bucketBean: BucketBean, onClick: (BucketBean) -> Unit) {
    val viewModel = LocalAlbumPickerViewModel.current
    val currentBucketBean by viewModel.currentBucketFlow.collectAsState()
    val colors = LocalTheme.current.colors
    Row(
        modifier = Modifier
            .clickable {
                onClick(bucketBean)
            }
            .padding(end = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        AsyncImage(
            imageLoader = CoilImageLoader.getInstance(context = LocalContext.current),
            model = bucketBean.albumList.firstOrNull(),
            modifier = Modifier.size(50.dp),
            contentDescription = "",
            contentScale = ContentScale.Crop
        )
        Spacer(modifier = Modifier.width(8.dp))
        Row(modifier = Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = bucketBean.bucketName,
                fontSize = 16.sp,
                color = Color(0xFFFFFFFF),
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "(${bucketBean.albumList.size})",
                fontSize = 16.sp,
                color = Color(0xFF555555),
                overflow = TextOverflow.Ellipsis
            )
        }

        if (currentBucketBean == bucketBean) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = "",
                tint = colors.textColorLink
            )
        }
    }
}
