//
//  WelcomeView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0
    @State private var animateGradient = false
    @Binding var showWelcome: Bool
    
    let welcomePages = [
        WelcomePage(
            title: "Welcome to Moodify",
            subtitle: "Music & Video Explorer Based on Your Mood",
            description: "Discover the perfect playlist that matches exactly how you're feeling right now",
            icon: "music.note",
            color: .purple
        ),
        WelcomePage(
            title: "Select Your Mood",
            subtitle: "Choose from Happy, Sad, Energetic, Chill & More",
            description: "Simply tap on your current mood and we'll curate the perfect playlist for you",
            icon: "heart.fill",
            color: .pink
        ),
        WelcomePage(
            title: "Shake to Shuffle",
            subtitle: "Random Mood Generator",
            description: "Can't decide? Just shake your phone and let us surprise you with a random mood!",
            icon: "iphone.and.arrow.forward",
            color: .orange
        ),
        WelcomePage(
            title: "Voice Search",
            subtitle: "Find Music with Your Voice",
            description: "Use the Voice tab to speak your mood or song preference. Just say what you're looking for!",
            icon: "mic.fill",
            color: .blue
        ),
        WelcomePage(
            title: "Live Concerts",
            subtitle: "Discover Events Near You",
            description: "Find live concerts and events happening around your location",
            icon: "map.fill",
            color: .green
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        welcomePages[currentPage].color.opacity(0.6),
                        welcomePages[currentPage].color.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
                
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showWelcome = false
                            }
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    TabView(selection: $currentPage) {
                        ForEach(0..<welcomePages.count, id: \.self) { index in
                            WelcomePageView(page: welcomePages[index], geometry: geometry)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<welcomePages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? welcomePages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation(.spring()) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(welcomePages[currentPage].color)
                            .font(.headline)
                        }
                        
                        Spacer()
                        
                        if currentPage < welcomePages.count - 1 {
                            Button("Next") {
                                withAnimation(.spring()) {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(welcomePages[currentPage].color)
                            .cornerRadius(25)
                        } else {
                            Button("Get Started") {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showWelcome = false
                                }
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                             startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(25)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
            .onAppear {
                animateGradient = true
            }
        }
    }
}

struct WelcomePageView: View {
    let page: WelcomePage
    let geometry: GeometryProxy
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: adaptiveSpacing(for: geometry.size)) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: adaptiveIconSize(for: geometry.size), weight: .thin))
                .foregroundColor(page.color)
                .scaleEffect(animateIcon ? 1.1 : 1.0)
                .rotationEffect(.degrees(animateIcon ? 5 : -5))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
            Text(page.title)
                .font(.system(size: adaptiveTitleSize(for: geometry.size), weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            Text(page.subtitle)
                .font(.system(size: adaptiveSubtitleSize(for: geometry.size), weight: .medium))
                .foregroundColor(page.color)
                .multilineTextAlignment(.center)
            Text(page.description)
                .font(.system(size: adaptiveBodySize(for: geometry.size)))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
            
            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        if screenHeight < 700 {
            return 20
        } else if screenHeight > 900 {
            return 35
        }
        return 30
    }
    
    private func adaptiveIconSize(for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        if screenHeight < 700 {
            return 65
        } else if screenHeight > 900 {
            return 90
        }
        return 80
    }
    
    private func adaptiveTitleSize(for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        if screenHeight < 700 {
            return 26
        } else if screenHeight > 900 {
            return 36
        }
        return 32
    }
    
    private func adaptiveSubtitleSize(for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        if screenHeight < 700 {
            return 18
        } else if screenHeight > 900 {
            return 24
        }
        return 20
    }
    
    private func adaptiveBodySize(for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        if screenHeight < 700 {
            return 14
        } else if screenHeight > 900 {
            return 18
        }
        return 16
    }
}
