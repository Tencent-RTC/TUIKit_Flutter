package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data;

import android.util.Log;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.annotations.SerializedName;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;
import java.util.LinkedList;
import java.util.List;

public class BeautyType {
    private String mTabName;
    private List<BeautyItem> mBeautyItemList = new LinkedList<>();

    private int mSelectedItemIndex = 1;

    public BeautyType(JsonObject jsonObject) {
        if (jsonObject != null) {
            mTabName = jsonObject.get("beauty_type_name").getAsString();
            JsonArray beautyItemList = jsonObject.getAsJsonArray("beauty_item_list");
            for(JsonElement jsonElement : beautyItemList.asList()) {
                BeautyItem beautyItem = new BeautyItem(jsonElement.getAsJsonObject());
                mBeautyItemList.add(beautyItem);
            }
        }
    }

    public BeautyItem getSelectBeautyItem() {
        if (mBeautyItemList == null || mSelectedItemIndex >= mBeautyItemList.size()) {
            return null;
        }

        return mBeautyItemList.get(mSelectedItemIndex);
    }

    public String getName() {
        return VideoRecorderResourceUtils.getString(mTabName);
    }

    public int getItemSize() {
        return mBeautyItemList != null ? mBeautyItemList.size() : 0;
    }

    public BeautyItem getItem(int index) {
        if (mBeautyItemList == null || index >= mBeautyItemList.size()) {
            return null;
        }
        return mBeautyItemList.get(index);
    }

    public int getSelectedItemIndex() {
        return mSelectedItemIndex;
    }

    public void setSelectedItemIndex(int index) {
        mSelectedItemIndex = index;
    }

    public BeautyItem getSelectedItem() {
        return getItem(mSelectedItemIndex);
    }

    public boolean isContainItem(BeautyItem item) {
        return mBeautyItemList != null && mBeautyItemList.contains(item);
    }
}
