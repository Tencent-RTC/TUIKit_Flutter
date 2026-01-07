package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.BeautyInfo;

public class BeautyTypeAdapter extends FragmentStateAdapter {

    private final Context mContext;
    private final BeautyInfo mBeautyInfo;

    public BeautyTypeAdapter(@NonNull Context context, BeautyInfo beautyInfo) {
        super((FragmentActivity) context);
        mBeautyInfo = beautyInfo;
        mContext = context;
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        return new BeautyTypeFragment(mContext, mBeautyInfo, position);
    }

    @Override
    public int getItemCount() {
        return mBeautyInfo.getBeautyTypeSize();
    }

}
