//
//  WelcomePage.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI

struct WelcomePage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    
    init(title: String, subtitle: String, description: String, icon: String, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.icon = icon
        self.color = color
    }
}
