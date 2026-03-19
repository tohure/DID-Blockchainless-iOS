// CryptoConfig.swift
// DIDBlockchainlessDemo
//
// Configuración global para las operaciones criptográficas.

import Foundation

/// Configuración de seguridad criptográfica de la app.
///
/// Equivalente a `CryptoConfig.kt` de Android.
enum CryptoConfig: Sendable {

    /// Si `true`, las claves del Keychain requieren autenticación biométrica.
    ///
    /// - En **dispositivo físico**: siempre `true` — Secure Enclave + Face ID/Touch ID.
    /// - En **Simulator**: `false` — sin Secure Enclave real; evita el prompt biométrico
    ///   simulado en cada operación de Keychain durante el desarrollo.
    ///
    /// Equivalente al flag `useBiometrics` de Android que se apaga para demos/testing.
    static func useBiometrics() -> Bool {
        #if targetEnvironment(simulator)
        return false   // Simulator: sin Secure Enclave real, sin biometría
        #else
        return true    // Dispositivo físico: biometría obligatoria
        #endif
    }

    /// Duración (segundos) en que la autenticación biométrica sigue válida
    /// para múltiples operaciones de Keychain consecutivas.
    static func biometricValiditySeconds() -> TimeInterval { 10 }
}
