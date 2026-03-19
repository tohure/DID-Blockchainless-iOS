// Colors.swift
// DIDBlockchainlessDemo

import SwiftUI

extension Color {
    // MARK: - Paleta principal
    static let appBackground    = Color("appBackground",    bundle: nil)
    static let appSurface       = Color("appSurface",       bundle: nil)
    static let appPrimary       = Color(red: 0.25, green: 0.53, blue: 1.0)      // Azul DID
    static let appSecondary     = Color(red: 0.15, green: 0.85, blue: 0.65)     // Verde éxito
    static let appError         = Color(red: 0.95, green: 0.33, blue: 0.35)     // Rojo error
    static let appWarning       = Color(red: 1.0,  green: 0.75, blue: 0.1)      // Amarillo
    static let textPrimary      = Color(white: 0.95)
    static let textSecondary    = Color(white: 0.65)
    static let cardBackground   = Color(white: 0.12)
    static let cardBorder       = Color(white: 0.22)
}

extension LinearGradient {
    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.08, blue: 0.18), Color(red: 0.03, green: 0.05, blue: 0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary, Color(red: 0.45, green: 0.25, blue: 0.9)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
