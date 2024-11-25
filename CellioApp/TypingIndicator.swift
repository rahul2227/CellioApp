//
//  TypingIndicator.swift
//  CellioApp
//
//  Created by Rahul Sharma on 25/11/24.
//

import SwiftUI

// MARK: Typing Indicator
struct TypingIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Bot is typing...")
                .italic()
                .foregroundColor(.gray)
                .padding(.trailing, 60)
        }
        .padding(.bottom, 5)
    }
}


// MARK: preview
struct TypingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        TypingIndicator()
            .previewLayout(.sizeThatFits)
    }
}
