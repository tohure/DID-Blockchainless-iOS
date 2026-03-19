// AppNavigation.swift
// DIDBlockchainlessDemo
//
// Grafo de navegación con NavigationStack.
// Equivalente a AppNavigation.kt de Android.

import SwiftUI

/// Rutas de navegación de la app.
enum AppRoute: Hashable {
    case did
    case cryptoManager
}

/// Contenedor de navegación principal.
///
/// Equivale a `navController + NavHost` de Android con destinos
/// `HomeScreen`, `DidScreen` y `RsaScreen`.
struct AppNavigation: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeScreen(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .did:
                        DIDScreen()
                    case .cryptoManager:
                        RSAScreen()
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}
