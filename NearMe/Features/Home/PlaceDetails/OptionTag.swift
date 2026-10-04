//
//  OptionTag.swift
//  NearMe
//
//  Created by Utsav Hitendrabhai Pandya on 04/10/26.
//

import SwiftUI

struct OptionTag : View {
    
    @State var isActive : Bool
    
    var body: some View {
        VStack(spacing: 10) {
            
            Image(systemName: "car")
                .foregroundStyle(isActive ? .white : .blue)
            Text("Directions")
                .foregroundStyle(isActive ? .white : .blue)
                .font(.footnote.bold())
            
        }
        .padding()
        .background( isActive ? .blue : .gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        
    }
}

#Preview {
    OptionTag(isActive: true)
}
