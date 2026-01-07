package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data;

import android.util.Log;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderFileUtil;
import java.util.ArrayList;
import java.util.List;

public class BeautyInfo {
    private static final String DEFAULT_BEAUTY_DATA =
            "file:///asset/video_recorder_config/video_recorder_beauty_info_default_data.json";
    private final String TAG = "BeautyInfo_" + hashCode();

    public final VideoRecorderData<BeautyItem> tuiDataSelectedBeautyItem = new VideoRecorderData<>(null);
    private final List<BeautyType> mBeautyTypeList = new ArrayList<>();

    public static BeautyInfo CreateDefaultBeautyInfo() {
        Log.i("BeautyInfo", "create default beautyInfo");
        BeautyInfo beautyInfo = new BeautyInfo();
        String json = VideoRecorderFileUtil.readTextFromFile(DEFAULT_BEAUTY_DATA);
        if (json.isEmpty()) {
            return beautyInfo;
        }

        JsonObject mJsonObject = new Gson().fromJson(json, JsonObject.class);
        JsonArray beautyTypeList = mJsonObject.getAsJsonArray("beauty_type_list");
        for(JsonElement jsonElement : beautyTypeList.asList()) {
            BeautyType beautyType = new BeautyType(jsonElement.getAsJsonObject());
            beautyInfo.mBeautyTypeList.add(beautyType);
        }
        return beautyInfo;
    }

    public BeautyType getBeautyType(int typeIndex) {
        if (typeIndex >= mBeautyTypeList.size()) {
            return null;
        }

        return mBeautyTypeList.get(typeIndex);
    }

    public void setSelectedItemIndex(int typeIndex, int itemIndex) {
        Log.i(TAG, "set selected item index.type index = " + typeIndex + " item index = " + itemIndex);
        BeautyType BeautyType = getBeautyType(typeIndex);
        if (BeautyType == null) {
            return;
        }

        BeautyType.setSelectedItemIndex(itemIndex);
        BeautyItem beautyItem = BeautyType.getSelectBeautyItem();
        if (beautyItem != tuiDataSelectedBeautyItem.get()) {
            tuiDataSelectedBeautyItem.set(beautyItem);
        }
    }

    public int getItemTypeIndex(BeautyItem beautyItem) {
        for (int i = 0; i < mBeautyTypeList.size(); i++) {
            if (mBeautyTypeList.get(i).isContainItem(beautyItem)) {
                return i;
            }
        }
        return 0;
    }

    public int getBeautyTypeSize() {
        return mBeautyTypeList.size();
    }

    public int getItemSize(int typeIndex) {
        BeautyType beautyType = getBeautyType(typeIndex);
        return beautyType != null ? beautyType.getItemSize() : 0;
    }

    public int getTypeIndexWithType(BeautyInnerType beautyType) {
        if (beautyType == BeautyInnerType.BEAUTY_FILTER) {
            return 1;
        } else {
            return 0;
        }
    }
}
