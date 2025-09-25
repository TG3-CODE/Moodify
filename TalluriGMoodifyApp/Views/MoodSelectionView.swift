//
//  MoodSelectionView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import CoreMotion

struct MoodSelectionView: View {
    @EnvironmentObject var moodManager: MoodManager
    @State private var selectedMoodScale: CGFloat = 1.0
    @State private var animationOffset: CGFloat = 0
    @State private var showingShakeHint = true
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(spacing: adaptiveSpacing(for: geometry.size)) {
                        VStack(spacing: 10) {
                            Text("🎵")
                                .font(.system(size: adaptiveFontSize(base: 50, for: geometry.size)))
                                .rotationEffect(.degrees(animationOffset))
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationOffset)
                                .padding(.top, max(geometry.safeAreaInsets.top, 20))
                            
                            Text("Moodify")
                                .font(.system(size: adaptiveFontSize(base: 32, for: geometry.size), weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                                 startPoint: .leading, endPoint: .trailing)
                                )
                            
                            Text("How are you feeling?")
                                .font(.system(size: adaptiveFontSize(base: 20, for: geometry.size)))
                                .foregroundColor(.primary)
                            
                            Text("Music that matches your mood")
                                .font(.system(size: adaptiveFontSize(base: 14, for: geometry.size)))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current mood:")
                                    .foregroundColor(.secondary)
                                Text(moodManager.selectedMood.emoji + " " + moodManager.selectedMood.rawValue.capitalized)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                            }
                            .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size)))
                            
                            if moodManager.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Finding songs...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("\(moodManager.currentPlaylist.count) songs ready")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        if showingShakeHint {
                            HStack {
                                Text("📱")
                                    .font(.title2)
                                    .offset(x: animationOffset * 0.1)
                                
                                Text("Shake for random mood!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(Array(MoodType.allCases.enumerated()), id: \.element) { index, mood in
                                MoodCard(
                                    mood: mood,
                                    isSelected: moodManager.selectedMood == mood,
                                    size: adaptiveCardSize(for: geometry.size)
                                ) {
                                    selectMoodWithAnimation(mood)
                                }
                                .scaleEffect(moodManager.selectedMood == mood ? 1.05 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(Double(index) * 0.1), value: moodManager.selectedMood)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            // Explore Music Button
                            NavigationLink(destination: PlaylistView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "music.note.list")
                                    Text("Explore Music")
                                }
                                .foregroundColor(.white)
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                                 startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(25)
                                .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            Button(action: {
                                moodManager.shuffleToRandomMood()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "shuffle")
                                    Text("Random Mood")
                                }
                                .foregroundColor(.purple)
                                .font(.system(size: adaptiveFontSize(base: 16, for: geometry.size), weight: .semibold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 100)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    moodManager.startShakeDetection()
                    withAnimation {
                        animationOffset = 15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showingShakeHint = false
                        }
                    }
                }
            }
        }
    }
    
    private func selectMoodWithAnimation(_ mood: MoodType) {
        print("👆 User tapped mood: \(mood.rawValue)")
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            moodManager.selectMood(mood)
            selectedMoodScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedMoodScale = 1.0
            }
        }
        if showingShakeHint {
            withAnimation(.easeOut(duration: 0.3)) {
                showingShakeHint = false
            }
        }
    }
    private func adaptiveSpacing(for size: CGSize) -> CGFloat {
        let baseSpacing: CGFloat = 16
        let screenHeight = size.height
        
        if screenHeight < 700 {
            return baseSpacing * 0.8
        } else if screenHeight > 900 {
            return baseSpacing * 1.1
        }
        return baseSpacing
    }
    
    private func adaptiveFontSize(base: CGFloat, for size: CGSize) -> CGFloat {
        let screenHeight = size.height
        let scaleFactor: CGFloat
        
        if screenHeight < 700 {
            scaleFactor = 0.85
        } else if screenHeight > 900 {
            scaleFactor = 1.1
        } else {
            scaleFactor = 1.0
        }
        
        return base * scaleFactor
    }
    
    private func adaptiveCardSize(for size: CGSize) -> CGFloat {
        let screenWidth = size.width
        let baseHeight: CGFloat = 110
        
        if screenWidth < 400 {
            return baseHeight * 0.85
        } else if screenWidth > 450 {
            return baseHeight * 1.0
        }
        return baseHeight
    }
}
struct MoodCard: View {
    let mood: MoodType
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void
    @State private var isPressed = false
    
    init(mood: MoodType, isSelected: Bool, size: CGFloat = 120, action: @escaping () -> Void) {
        self.mood = mood
        self.isSelected = isSelected
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(mood.emoji)
                    .font(.system(size: size * 0.4))
                    .shadow(color: isSelected ? mood.color : .clear, radius: 10)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text(mood.rawValue)
                    .font(.system(size: size * 0.15, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: size)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ?
                        LinearGradient(gradient: Gradient(colors: [mood.color, mood.color.opacity(0.7)]),
                                     startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]),
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? mood.color : Color.clear, lineWidth: 3)
                    )
            )
            .shadow(color: isSelected ? mood.color.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
