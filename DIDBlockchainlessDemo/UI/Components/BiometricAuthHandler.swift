// BiometricAuthHandler.swift
// DIDBlockchainlessDemo
//
// ViewModifier que presenta el prompt biométrico de iOS sin fallback a passcode.

import SwiftUI
import os
import LocalAuthentication

/// ViewModifier que muestra el prompt biométrico (Face ID / Touch ID)
/// cuando `isPresented` se vuelve `true`.
struct BiometricAuthHandler: ViewModifier {

    @Binding var isPresented: Bool
    let reason: String
    let onSuccess: () -> Void
    let onFailure: () -> Void
    let onDismissed: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue { evaluateBiometry() }
            }
    }

    private func evaluateBiometry() {
        let context = LAContext()
        // deviceOwnerAuthenticationWithBiometrics — NO acepta passcode como fallback
        context.localizedCancelTitle = "Cancelar"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            AppLogger.ui().warning("Biometría no disponible: \(error?.localizedDescription ?? "?")")
            isPresented = false
            onFailure()
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, authError in
            DispatchQueue.main.async {
                isPresented = false
                if success {
                    AppLogger.ui().debug_only("Biometría exitosa")
                    onSuccess()
                } else if let err = authError as? LAError, err.code == .userCancel {
                    AppLogger.ui().debug_only("Biometría cancelada por el usuario")
                    onDismissed()
                } else {
                    AppLogger.ui().warning("Biometría fallida: \(authError?.localizedDescription ?? "?")")
                    onFailure()
                }
            }
        }
    }
}

extension View {
    /// Adjunta el handler biométrico al view.
    func biometricAuth(
        isPresented: Binding<Bool>,
        reason: String = "Autentícate para acceder a tus claves seguras",
        onSuccess: @escaping () -> Void,
        onFailure: @escaping () -> Void = {},
        onDismissed: @escaping () -> Void = {}
    ) -> some View {
        modifier(BiometricAuthHandler(
            isPresented: isPresented,
            reason: reason,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onDismissed: onDismissed
        ))
    }
}
