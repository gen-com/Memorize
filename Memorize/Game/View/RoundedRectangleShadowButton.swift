//
//  RoundedRectangleShadowButton.swift
//  Memorize
//
//  Created by Byeongjo Koo on 2022/09/25.
//

import SwiftUI

struct RoundedRectangleShadowButton<Content>: View where Content: View {
    
    private let title: () -> Content
    private let radius: CGFloat
    private let shadowColor: Color
    private let shadowRadius: CGFloat
    private let action: () -> Void
    
    init(
        title: @escaping () -> Content,
        radius: CGFloat = 5,
        shadowColor: Color = .black,
        shadowRadius: CGFloat = 5,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.radius = radius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: radius)
                .shadow(color: shadowColor, radius: shadowRadius)
                .overlay { title() }
        }
    }
}
