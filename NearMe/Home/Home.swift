//
//  Home.swift
//  MyApp
//
//  Created by Utsav Hitendrabhai Pandya on 30/09/26.
//

import SwiftUI

struct Home: View {
    
    @State var searchText: String = ""
    
    var body: some View {
        
        ZStack {
            
            Color(.systemBackground)
                    .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hello,")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                                .fontWeight(.light)
                            Text("Utsav")
                                .font(.title2.bold())
                        }
                        
                        Spacer()
                        
                        Image(.person)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                        
                    }
                    
                    HStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("", text: $searchText, prompt: Text("Search places cities"))
                            .frame(maxWidth: .infinity, maxHeight: 40, alignment: .center)
                    }
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4, y: 2)
                    
                    
                    Spacer()
                    
                }
                .padding()
                
            }
        }
        
        
    }
}

#Preview {
    Home()
}
