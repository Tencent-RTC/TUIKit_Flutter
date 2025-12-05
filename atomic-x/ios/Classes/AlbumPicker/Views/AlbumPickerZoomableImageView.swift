//
//  AlbumPickerZoomableImageView.swift
//  AlbumPicker
//
//  Created by eddard on 2025/10/21..
//  Copyright © 2025 Tencent. All rights reserved.
//

import SwiftUI
import UIKit

struct AlbumPickerZoomableImageView: UIViewRepresentable {
    let image: UIImage
    @Binding var isZoomed: Bool
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let imageView = UIImageView(image: image)
        
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        scrollView.addSubview(imageView)
        
        context.coordinator.scrollView = scrollView
        context.coordinator.imageView = imageView
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
        
        if !isZoomed && uiView.zoomScale != 1.0 {
            uiView.setZoomScale(1.0, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: AlbumPickerZoomableImageView
        var scrollView: UIScrollView?
        var imageView: UIImageView?
        
        init(_ parent: AlbumPickerZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            
            imageView?.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                       y: scrollView.contentSize.height * 0.5 + offsetY)
            
            DispatchQueue.main.async {
                self.parent.isZoomed = scrollView.zoomScale > 1.0
            }
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let location = gesture.location(in: scrollView)
                let zoomScale: CGFloat = 2.0
                let zoomRect = zoomRectForScale(zoomScale, center: location, scrollView: scrollView)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        private func zoomRectForScale(_ scale: CGFloat, center: CGPoint, scrollView: UIScrollView) -> CGRect {
            let width = scrollView.bounds.width / scale
            let height = scrollView.bounds.height / scale
            let x = center.x - width / 2
            let y = center.y - height / 2
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

struct AlbumPickerImageView: View {
    let image: UIImage
    @State private var isZoomed = false
    
    var body: some View {
        ZStack {
            Color.black
            
            AlbumPickerZoomableImageView(image: image, isZoomed: $isZoomed)
                .clipped()
            
            if isZoomed {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: resetZoom) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func resetZoom() {
        isZoomed = false
    }
}
