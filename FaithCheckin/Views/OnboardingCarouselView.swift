//
//  OnboardingCarouselView.swift
//  Centered
//
//  Created for onboarding carousel gallery
//

import SwiftUI

struct OnboardingCarouselView: View {
    let onComplete: () -> Void
    
    @State private var currentPage: Int = 0
    
    private let imageNames = ["Onboard 0", "Onboard 1", "Onboard 2", "Onboard 3", "Onboard 4", "Onboard 5", "Onboard 6", "Onboard 7", "Onboard 8"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Carousel Image Gallery
                    TabView(selection: $currentPage) {
                        ForEach(0..<imageNames.count, id: \.self) { index in
                            ZStack {
                                // Background to ensure rounded corners are visible
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.01))
                                
                                Image(imageNames[index])
                                    .renderingMode(.original)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.75)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Controls Section
                    VStack(spacing: 20) {
                        // Page Indicators (dots)
                        HStack(spacing: 8) {
                            ForEach(0..<imageNames.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Navigation Controls
                        HStack(spacing: 20) {
                            // Next Button (shown on all pages except last)
                            if currentPage < imageNames.count - 1 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPage += 1
                                    }
                                }) {
                                    HStack {
                                        Text("Next")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "772C2C"))
                                    .cornerRadius(12)
                                }
                                .scaleEffect(0.7)
                            } else {
                                // Done Button (shown only on last page)
                                Button(action: {
                                    onComplete()
                                }) {
                                    Text("Done")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(hex: "772C2C"))
                                        .cornerRadius(12)
                                }
                                .scaleEffect(0.7)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                    .background(Color(hex: "EEEDDD"))
                }
                .background(Color(hex: "EEEDDD"))
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
        }
    }
}

