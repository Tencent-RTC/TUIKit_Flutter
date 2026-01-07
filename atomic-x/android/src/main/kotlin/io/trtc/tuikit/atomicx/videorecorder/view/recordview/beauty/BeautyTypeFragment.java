package io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import io.trtc.tuikit.atomicx.R;
import io.trtc.tuikit.atomicx.videorecorder.utils.VideoRecorderData.VideoRecorderDataObserver;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.BeautyInfo;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.BeautyItem;
import io.trtc.tuikit.atomicx.videorecorder.view.recordview.beauty.data.BeautyType;
import org.jetbrains.annotations.Nullable;

public class BeautyTypeFragment extends Fragment {

    private final BeautyInfo mBeautyInfo;
    private final Context mContext;
    private final int mTypeIndex;

    private BeautyHorizontalScrollView mScrollItemView;
    private final VideoRecorderDataObserver<BeautyItem> mOnSelectedBeautyItemChanged = new VideoRecorderDataObserver<BeautyItem>() {
        @Override
        public void onChanged(BeautyItem beautyItem) {
            BeautyType beautyType = mBeautyInfo.getBeautyType(mTypeIndex);
            if (beautyType != null) {
                mScrollItemView.setClicked(beautyType.getSelectedItemIndex());
            }
        }
    };

    public BeautyTypeFragment(Context context, BeautyInfo beautyInfo, int typeIndex) {
        mContext = context;
        mBeautyInfo = beautyInfo;
        mTypeIndex = typeIndex;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {
        Log.i("BeautyTypeFragment", "onCreateView");
        View view = inflater.inflate(R.layout.video_recorder_beauty_type_fragment, container, false);

        mScrollItemView = view.findViewById(R.id.beauty_scroll_view);
        BeautyItemAdapter itemAdapter = new BeautyItemAdapter(mContext, mBeautyInfo, mTypeIndex);
        BeautyType beautyType = mBeautyInfo.getBeautyType(mTypeIndex);
        itemAdapter.setSelectPosition(beautyType != null ? beautyType.getSelectedItemIndex() : 1);
        mScrollItemView.setAdapter(itemAdapter);
        mScrollItemView.setFocusable(true);
        mBeautyInfo.tuiDataSelectedBeautyItem.observe(mOnSelectedBeautyItemChanged);
        return view;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        mBeautyInfo.tuiDataSelectedBeautyItem.removeObserver(mOnSelectedBeautyItemChanged);
    }
}