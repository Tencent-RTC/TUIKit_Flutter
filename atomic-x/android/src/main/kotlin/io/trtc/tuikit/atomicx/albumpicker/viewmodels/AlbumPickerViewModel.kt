package io.trtc.tuikit.atomicx.albumpicker.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.tencent.qcloud.tuicore.ServiceInitializer
import io.trtc.tuikit.atomicx.R
import io.trtc.tuikit.atomicx.albumpicker.AlbumPickerConfig
import io.trtc.tuikit.atomicx.albumpicker.PickMode
import io.trtc.tuikit.atomicx.albumpicker.model.BaseBean
import io.trtc.tuikit.atomicx.albumpicker.model.BucketBean
import io.trtc.tuikit.atomicx.albumpicker.model.VideoBean
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AlbumPickerViewModelFactory(private val albumPickerConfig: AlbumPickerConfig) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return AlbumPickerViewModel(albumPickerConfig) as T
    }
}

class AlbumPickerViewModel(private val albumPickerConfig: AlbumPickerConfig) : ViewModel() {
    private val tag = "AlbumPickerViewModel"

    companion object {
        private const val TAG = "AlbumPickerViewModel"
        private const val FIRST_LOAD_SIZE = 120
    }

    private val loadedSet = HashSet<Int>()

    private var allBucketName = ServiceInitializer.getAppContext()
        .getString(R.string.album_picker_all_photos_and_videos)
    private val allVideoBucketName = ServiceInitializer.getAppContext()
        .getString(R.string.album_picker_all_videos)
    private val collectionsBucketName = ServiceInitializer.getAppContext()
        .getString(R.string.album_picker_collections)

    private var isLoading = false

    private val loader = AlbumMediaLoader(ServiceInitializer.getAppContext())

    private val _bucketMapFlow = MutableStateFlow<Map<String, BucketBean>>(emptyMap())
    val bucketMapFlow = _bucketMapFlow.asStateFlow()

    private val _bucketBeanListFlow = MutableStateFlow<List<BucketBean>>(emptyList())
    val bucketBeanListFlow = _bucketBeanListFlow.asStateFlow()

    private val _currentBucketFlow = MutableStateFlow(BucketBean())
    val currentBucketFlow = _currentBucketFlow.asStateFlow()

    private val _selectedMediaListFlow = MutableStateFlow<List<BaseBean>>(emptyList())
    val selectedMediaListFlow = _selectedMediaListFlow.asStateFlow()

    private val _fullImage = MutableStateFlow(false)
    val fullImage = _fullImage.asStateFlow()

    init {
        val initialBucketMap = mutableMapOf<String, BucketBean>()

        if (albumPickerConfig.pickMode == PickMode.IMAGE) {
            allBucketName = ServiceInitializer.getAppContext()
                .getString(R.string.album_picker_all_photos)
        } else if (albumPickerConfig.pickMode == PickMode.VIDEO) {
            allBucketName = ServiceInitializer.getAppContext()
                .getString(R.string.album_picker_all_videos)
        } else {
            allBucketName = ServiceInitializer.getAppContext()
                .getString(R.string.album_picker_all_photos_and_videos)
        }

        val allBucketBean = BucketBean(
            bucketName = allBucketName,
            albumList = emptyList()
        )
        initialBucketMap[allBucketName] = allBucketBean

        if (albumPickerConfig.pickMode == PickMode.ALL) {
            val allVideoBucketBean = BucketBean(
                bucketName = allVideoBucketName,
                albumList = emptyList()
            )
            initialBucketMap[allVideoBucketName] = allVideoBucketBean
        }

        _bucketMapFlow.value = initialBucketMap
        _bucketBeanListFlow.value = initialBucketMap.values.toList()
        _currentBucketFlow.value = allBucketBean
    }

    fun loadImageVideo() {
        if (isLoading) {
            return
        }
        isLoading = true
        viewModelScope.launch {
            try {
                val loadFirstBatch: suspend () -> List<BaseBean> = when (albumPickerConfig.pickMode) {
                    PickMode.IMAGE -> {
                        { loader.loadImage(FIRST_LOAD_SIZE).orEmpty() }
                    }

                    PickMode.VIDEO -> {
                        { loader.loadVideo(FIRST_LOAD_SIZE).orEmpty() }
                    }

                    PickMode.ALL -> {
                        {
                            val images = async { loader.loadImage(FIRST_LOAD_SIZE).orEmpty() }
                            val videos = async { loader.loadVideo(FIRST_LOAD_SIZE).orEmpty() }
                            videos.await() + images.await()
                        }
                    }
                }

                val loadAllItems: suspend () -> List<BaseBean> = when (albumPickerConfig.pickMode) {
                    PickMode.IMAGE -> {
                        { loader.loadAllImage().orEmpty() }
                    }

                    PickMode.VIDEO -> {
                        { loader.loadAllVideo().orEmpty() }
                    }

                    PickMode.ALL -> {
                        {
                            val images = async { loader.loadAllImage().orEmpty() }
                            val videos = async { loader.loadAllVideo().orEmpty() }
                            images.await() + videos.await()
                        }
                    }
                }

                val firstBatchData = withContext(Dispatchers.IO) { loadFirstBatch() }
                processDataBatch(firstBatchData)

                val allData = withContext(Dispatchers.IO) { loadAllItems() }
                processDataBatch(allData)
            } catch (e: Exception) {
                Log.e(TAG, "Load Image Video failed")
            } finally {
                isLoading = false
            }
        }
    }

    private suspend fun processDataBatch(data: List<BaseBean>) {
        withContext(Dispatchers.Default) {
            val updatedBucketMap = _bucketMapFlow.value.toMutableMap()

            val allMediaList = mutableListOf<BaseBean>()
            val videosList = mutableListOf<BaseBean>()
            val collectionsList = mutableListOf<BaseBean>()

            updatedBucketMap[allBucketName]?.albumList?.let { allMediaList.addAll(it) }
            updatedBucketMap[allVideoBucketName]?.albumList?.let { videosList.addAll(it) }
            updatedBucketMap[collectionsBucketName]?.albumList?.let { collectionsList.addAll(it) }

            for (baseBean in data) {
                if (loadedSet.contains(baseBean.id)) continue
                loadedSet.add(baseBean.id)

                if (baseBean.isFavorite) {
                    collectionsList.add(baseBean)

                    if (!updatedBucketMap.containsKey(collectionsBucketName)) {
                        val newCollectionsBucket = BucketBean(
                            bucketName = collectionsBucketName,
                            albumList = collectionsList
                        )
                        updatedBucketMap[collectionsBucketName] = newCollectionsBucket
                    } else {
                        val currentCollectionsList =
                            updatedBucketMap[collectionsBucketName]?.albumList?.toMutableList() ?: mutableListOf()
                        currentCollectionsList.add(baseBean)
                        updatedBucketMap[collectionsBucketName] = updatedBucketMap[collectionsBucketName]?.copy(
                            albumList = currentCollectionsList
                        ) ?: BucketBean(bucketName = collectionsBucketName, albumList = currentCollectionsList)
                    }
                }

                val bucketName = baseBean.bucketName
                if (!updatedBucketMap.containsKey(bucketName)) {
                    updatedBucketMap[bucketName] = BucketBean(
                        bucketName = bucketName,
                        albumList = listOf(baseBean)
                    )
                } else {
                    val currentBucketList = updatedBucketMap[bucketName]?.albumList?.toMutableList() ?: mutableListOf()
                    currentBucketList.add(baseBean)
                    updatedBucketMap[bucketName] = updatedBucketMap[bucketName]?.copy(
                        albumList = currentBucketList
                    ) ?: BucketBean(bucketName = bucketName, albumList = currentBucketList)
                }

                allMediaList.add(baseBean)

                if (baseBean is VideoBean) {
                    videosList.add(baseBean)
                }
            }

            updatedBucketMap[allBucketName] = updatedBucketMap[allBucketName]?.copy(
                albumList = allMediaList
            ) ?: BucketBean(bucketName = allBucketName, albumList = allMediaList)

            if (albumPickerConfig.pickMode == PickMode.ALL) {
                updatedBucketMap[allVideoBucketName] = updatedBucketMap[allVideoBucketName]?.copy(
                    albumList = videosList
                ) ?: BucketBean(bucketName = allVideoBucketName, albumList = videosList)
            }
            val sortedBucketMap = updatedBucketMap.mapValues { (_, bucket) ->
                bucket.copy(albumList = bucket.albumList.sorted())
            }

            withContext(Dispatchers.Main) {
                _bucketMapFlow.value = sortedBucketMap
                _bucketBeanListFlow.value = sortedBucketMap.values.toList()

                val currentBucketName = _currentBucketFlow.value.bucketName
                if (currentBucketName.isNotEmpty() && sortedBucketMap.containsKey(currentBucketName)) {
                    _currentBucketFlow.value = sortedBucketMap[currentBucketName]!!
                } else {
                    _currentBucketFlow.value = sortedBucketMap[allBucketName]!!
                }
            }
        }
    }

    fun selectBucket(bucketName: String) {
        val bucketMap = _bucketMapFlow.value
        if (bucketMap.containsKey(bucketName)) {
            _currentBucketFlow.value = bucketMap[bucketName]!!
        }
    }

    fun toggleSelectMedia(baseBean: BaseBean) {
        val selectedMediaList = _selectedMediaListFlow.value.toMutableList()
        if (selectedMediaList.contains(baseBean)) {
            selectedMediaList.remove(baseBean)
        } else {
            selectedMediaList.add(baseBean)
        }
        _selectedMediaListFlow.value = selectedMediaList
    }
}