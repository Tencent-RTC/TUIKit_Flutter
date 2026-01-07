// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import <Masonry/Masonry.h>
#import "VideoRecorderBeautifyEffectPanelView.h"
#import "VideoRecorderBeautifyEffectViewCell.h"
#import "VideoRecorderBeautifySettings.h"
#import "VideoRecorderCommon.h"

static const CGSize EffectItemSize = VideoRecorderConstCGSize(60, 86);

@interface VideoRecorderBeautifyEffectPanelView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    NSArray<VideoRecorderBeautifyEffectItem *> *_items;
    UICollectionView *_collectionView;
}
@end

@implementation VideoRecorderBeautifyEffectPanelView
@dynamic items;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _selectedIndex = -1;
        _items = @[];
        [self initUI];
    }
    return self;
}

- (void)initUI {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 10;
    layout.itemSize = EffectItemSize;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:VideoRecorderBeautifyEffectViewCell.class forCellWithReuseIdentifier:VideoRecorderBeautifyEffectViewCell.reuseIdentifier];
    [self addSubview:_collectionView];

    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, EffectItemSize.height /* + self.safeAreaInsets.bottom*/);
}

#pragma mark - Properties
- (NSArray<VideoRecorderBeautifyEffectItem *> *)items {
    return _items;
}
- (void)setItems:(NSArray<VideoRecorderBeautifyEffectItem *> *)value {
    _items = value;
    _selectedIndex = -1;
    [_collectionView reloadData];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_collectionView reloadData];
}

- (void)setIconSize:(CGSize)iconSize {
    _iconSize = iconSize;
    [_collectionView reloadData];
}

- (void)setFirstIconSize:(CGSize)iconSize {
    _firstIconSize = iconSize;
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout protocol

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoRecorderBeautifyEffectViewCell *cell = (VideoRecorderBeautifyEffectViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VideoRecorderBeautifyEffectViewCell.reuseIdentifier
                                                                                           forIndexPath:indexPath];
    cell.image = _items[indexPath.item].iconImage;
    cell.text = _items[indexPath.item].name;
    cell.effectSelected = (indexPath.item == _selectedIndex);
    if (indexPath.item == 0 && _firstIconSize.width != 0 && _firstIconSize.height != 0) {
        cell.iconSize = _firstIconSize;
    } else {
        cell.iconSize = _iconSize;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _items.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    _selectedIndex = indexPath.item;
    [collectionView reloadData];
    [_delegate effectPanelSelectionChanged:self];
}

@end
