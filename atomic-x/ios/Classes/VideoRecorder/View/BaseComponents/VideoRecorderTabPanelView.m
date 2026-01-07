// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

#import "VideoRecorderTabPanelView.h"
#import <Masonry/Masonry.h>
#import "VideoRecorderNSArray+Functional.h"
#import "VideoRecorderCommon.h"
#import "VideoRecorderImageUtil.h"
#import "VideoRecorderSplitterView.h"

@interface VideoRecorderTabPanelView () <VideoRecorderTabBarDelegate> {
    VideoRecorderTabBar *_bar;
    VideoRecorderSplitterView *_splitter;
    NSArray<VideoRecorderTabPanelTab *> *_tabs;
}

@end

@implementation VideoRecorderTabPanelView

@dynamic tabs;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self initUI];
    return self;
}

- (void)initUI {
    _bar = [[VideoRecorderTabBar alloc] init];
    [self addSubview:_bar];
    _bar.delegate = self;

    _splitter = [[VideoRecorderSplitterView alloc] init];
    [self addSubview:_splitter];
    _splitter.lineWidth = 1;
    _splitter.color = VideoRecorderDynamicColor(@"tabpanel_splitter_color", @"#FFFFFF1A");

    [_bar mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.right.top.equalTo(self).inset(5);
      make.height.mas_equalTo(42);
    }];
    [_splitter mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.right.equalTo(self);
      make.top.equalTo(_bar.mas_bottom);
      make.height.mas_equalTo(5);
    }];
}
- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - Properties
- (NSInteger)selectedIndex {
    return _bar.selectedIndex;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _bar.selectedIndex = selectedIndex;
    for (int i = 0; i < _tabs.count; i++) {
        VideoRecorderTabPanelTab *t = _tabs[i];
        t.view.hidden = i != selectedIndex;
    }
}

- (NSArray<VideoRecorderTabPanelTab *> *)tabs {
    return _tabs;
}

- (void)setTabs:(NSArray<VideoRecorderTabPanelTab *> *)value {
    if (_tabs != nil) {
        for (VideoRecorderTabPanelTab *t in _tabs) {
            [t.view removeFromSuperview];
        }
    }
    _tabs = value;
    _bar.selectedIndex = -1;
    _bar.tabs = [value video_recorder_map:^id(VideoRecorderTabPanelTab *t) {
      return t.icon == nil ? t.name : t.icon;
    }];
    for (int i = 0; i < _tabs.count; i++) {
        VideoRecorderTabPanelTab *t = _tabs[i];
        t.view.hidden = YES;
        [self addSubview:t.view];
        [t.view mas_makeConstraints:^(MASConstraintMaker *make) {
          make.left.right.bottom.equalTo(self);
          make.top.equalTo(_splitter.mas_bottom);
        }];
    }
    if (_tabs.count > 0) {
        VideoRecorderTabPanelTab *t = _tabs[0];
        _bar.selectedIndex = 0;
        t.view.hidden = NO;
    }
}
#pragma mark - VideoRecorderTabBarDelegate protocol
- (void)tabBar:(VideoRecorderTabBar *)bar selectedIndexChanged:(NSInteger)index {
    for (int i = 0; i < _tabs.count; i++) {
        VideoRecorderTabPanelTab *t = _tabs[i];
        t.view.hidden = i != index;
    }
    [_delegate tabPanel:self selectedIndexChanged:index];
}

@end

#pragma mark - VideoRecorderTabPanelTab
@implementation VideoRecorderTabPanelTab {
}
- (instancetype)initWithName:(NSString *)name icon:(UIImage *)icon view:(UIView *)view {
    self = [super init];
    if (self != nil) {
        _name = name;
        _icon = icon;
        _view = view;
    }
    return self;
}
@end

#pragma mark - VideoRecorderTabBar

@interface VideoRecorderTabBar () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    UICollectionView *_collectionView;
}
@end

@implementation VideoRecorderTabBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self initUI];
    return self;
}

- (void)initUI {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 10;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:VideoRecorderTabBarCell.class forCellWithReuseIdentifier:VideoRecorderTabBarCell.reuseIdentifier];
    [self addSubview:_collectionView];

    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self);
    }];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout protocol
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    _selectedIndex = indexPath.item;
    [collectionView reloadData];

    [_delegate tabBar:self selectedIndexChanged:_selectedIndex];
}

#pragma mark - UICollectionViewDataSource protocol
- (NSAttributedString *)getAttributedString:(NSString *)str selected:(BOOL)selected {
    UIColor *color;
    UIFont *font;
    if (selected) {
        color = UIColor.whiteColor;
        font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    } else {
        color = [UIColor colorWithWhite:1 alpha:0.6];
        font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    }
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:str
                                                               attributes:@{
                                                                   NSForegroundColorAttributeName : color,
                                                                   NSFontAttributeName : font,
                                                               }];
    return text;
}
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    VideoRecorderTabBarCell *cell = (VideoRecorderTabBarCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VideoRecorderTabBarCell.reuseIdentifier
                                                                                           forIndexPath:indexPath];
    cell.barCellSelected = indexPath.item == _selectedIndex;
    BOOL cellSelected = indexPath.item == _selectedIndex;
    id item = _tabs[indexPath.item];
    if ([item isKindOfClass:NSString.class]) {
        cell.attributedText = [self getAttributedString:item selected:cellSelected];
    } else if ([item isKindOfClass:UIImage.class]) {
        cell.contentView.backgroundColor = cellSelected ? [UIColor colorWithWhite:1 alpha:0.1] : UIColor.clearColor;
        cell.icon = item;
        cell.padding = 8;
    }

    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat h = _collectionView.bounds.size.height;
    CGSize size = CGSizeMake(h, h);
    id item = _tabs[indexPath.item];
    if ([item isKindOfClass:NSString.class]) {
        NSAttributedString *text = [self getAttributedString:_tabs[indexPath.item] selected:YES];
        CGSize textSize = [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, _collectionView.bounds.size.height)
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                             context:nil]
                              .size;
        size.width = MAX(size.width, textSize.width + 10);
        size.height = MAX(size.height, textSize.height + 8);
        return size;
    }
    return size;
}
- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _tabs.count;
}

@end

#pragma mark - VideoRecorderTabBarCell
@interface VideoRecorderTabBarCell () {
    UILabel *_label;
    UIImageView *_imgView;
}
@end
@implementation VideoRecorderTabBarCell
+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.contentView.layer.cornerRadius = 5;
        self.contentView.clipsToBounds = YES;

        _label = [[UILabel alloc] init];
        [self.contentView addSubview:_label];
        _label.textAlignment = NSTextAlignmentCenter;
        [_label mas_makeConstraints:^(MASConstraintMaker *make) {
          make.edges.equalTo(self);
        }];

        _imgView = [[UIImageView alloc] init];
        [self.contentView addSubview:_imgView];
        _imgView.contentMode = UIViewContentModeScaleAspectFit;
        [_imgView mas_makeConstraints:^(MASConstraintMaker *make) {
          make.edges.equalTo(self);
        }];
    }
    return self;
}
- (void)prepareForReuse {
    [super prepareForReuse];
    self.attributedText = nil;
    self.icon = nil;
    self.barCellSelected = NO;
    self.padding = 0;
}
- (NSAttributedString *)attributedText {
    return _label.attributedText;
}
- (UIImage *)icon {
    return _imgView.image;
}
- (void)setAttributedText:(NSAttributedString *)attributedText {
    _label.attributedText = attributedText;
}
- (void)setIcon:(UIImage *)icon {
    _imgView.image = icon;
}
- (void)setPadding:(CGFloat)padding {
    _padding = padding;
    [_label mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self).inset(_padding);
    }];
    [_imgView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self).inset(_padding);
    }];
}
@end
