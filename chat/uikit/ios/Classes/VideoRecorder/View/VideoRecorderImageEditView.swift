// Copyright (c) 2024 Tencent. All rights reserved.
// Author: eddardliu

import UIKit
import AlbumPickerCore

@objc public class VideoRecorderImageEditView: UIView {
    @objc public var onEditConfirmed: ((UIImage) -> Void)?
    @objc public var onEditCancelled: (() -> Void)?

    private let editView: ImageEditView

    @objc public init(image: UIImage) {
        editView = ImageEditView(sourceImage: image)
        super.init(frame: .zero)
        backgroundColor = .black
        editView.editDelegate = self
        addSubview(editView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        editView.frame = bounds
    }
}

extension VideoRecorderImageEditView: ImageEditDelegate {
    public func imageEditView(_ editView: ImageEditView, didCompleteWithImage editedImage: UIImage) {
        onEditConfirmed?(editedImage)
    }

    public func imageEditViewDidCancel(_ editView: ImageEditView) {
        onEditCancelled?()
    }
}
