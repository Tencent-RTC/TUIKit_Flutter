package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.TypedValue;
import com.google.gson.JsonObject;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderResourceUtils;


public class BeautyItem {
    private int mItemType;
    private int mItemLevel = 5;
    private String mItemName;
    private String mItemIconResName;
    private String mFilterBitmapResource;

    private Bitmap mFilterBitmap;

    public BeautyItem(JsonObject jsonObject) {
        if (jsonObject != null) {
            mItemType = jsonObject.get("item_type").getAsInt();
            mItemLevel = jsonObject.get("item_level").getAsInt();
            mItemName = jsonObject.get("item_name").getAsString();
            mItemIconResName = jsonObject.get("item_icon_normal").getAsString();
            mFilterBitmapResource = jsonObject.get("item_filter_bitmap").getAsString();
        }
    }

    public Bitmap getFilterBitmap() {
        if (mFilterBitmapResource == null || mFilterBitmapResource.isEmpty() || !mFilterBitmapResource
                .startsWith("@")) {
            return null;
        }

        if (mFilterBitmap != null) {
            return mFilterBitmap;
        }

        TypedValue value = new TypedValue();
        int resId = VideoRecorderResourceUtils.getDrawableId(mFilterBitmapResource);
        VideoRecorderResourceUtils.getResources().openRawResource(resId, value);
        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inTargetDensity = value.density;
        mFilterBitmap = BitmapFactory.decodeResource(VideoRecorderResourceUtils.getResources(), resId, opts);
        return mFilterBitmap;
    }

    public int getLevel() {
        return mItemLevel;
    }

    public void setLevel(int level) {
        mItemLevel = level;
    }

    public String getName() {
        if (mItemName.startsWith(VideoRecorderResourceUtils.STRING_RESOURCE_PREFIX)) {
            return VideoRecorderResourceUtils.getString(mItemName);
        }
        return mItemName;
    }

    public BeautyInnerType getInnerType() {
        return BeautyInnerType.fromInteger(mItemType);
    }

    public String getIconResName() {
        return mItemIconResName;
    }
}
