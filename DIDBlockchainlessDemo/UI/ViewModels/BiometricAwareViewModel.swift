// BiometricAwareViewModel.swift
// DIDBlockchainlessDemo
//
// Clase base @Observable para ViewModels que requieren autenticación biométrica.
// Equivalente a BiometricAwareViewModel.kt de Android.

import Foundation
import Observation
import os
import LocalAuthentication

/// Protocolo que todo estado de UI biométrico debe cumplir.
///
/// Equivalente a las funciones abstractas `withLoading`, `withBiometricPrompt`,
/// `withStatus` de `BiometricAwareViewModel.kt` de Android.
protocol BiometricAwareState {
    var isLoading: Bool { get set }
    var showBiometricPrompt: Bool { get set }
    var statusMessage: String { get set }
}

/// ViewModel base `@Observable` para pantallas con autenticación biométrica.
///
/// Centraliza:
/// - El estado de carga (`isLoading`)
/// - El prompt biométrico (`showBiometricPrompt`)
/// - Manejo de errores del Keychain:
///   - `KeychainError.authFailed` → muestra prompt y guarda acción pendiente
///   - `KeychainError.biometryInvalidated` → avisa que las claves deben regenerarse
/// - Re-ejecución automática de la acción pendiente tras autenticación exitosa
///
/// **Equivalencia Android:**
/// - `protected var pendingAction` → `pendingAction`
/// - `fun launch(block)` → `launch(_:)`
/// - `onBiometricSuccess()` → `onBiometricSuccess()`
@Observable
@MainActor
class BiometricAwareViewModel<State: BiometricAwareState> {

    // MARK: - Estado

    var state: State

    // MARK: - Pendiente

    /// Acción que se ejecutará tras una autenticación biométrica exitosa.
    @ObservationIgnored
    private var pendingAction: (@Sendable () async throws -> Void)?

    // MARK: - Init

    init(initialState: State) {
        self.state = initialState
    }

    // MARK: - Launch con manejo centralizado de errores

    /// Ejecuta `block` en background, manejando automáticamente:
    /// - `isLoading` durante la ejecución
    /// - `KeychainError.authFailed` → muestra prompt biométrico
    /// - `KeychainError.biometryInvalidated` → mensaje de claves invalidadas
    /// - Otros errores → `statusMessage`
    ///
    /// Equivalente a `protected fun launch(block)` de Android.
    func launch(_ block: @Sendable @escaping () async throws -> Void) {
        state.isLoading = true
        Task { [weak self] in
            do {
                try await block()
                await MainActor.run { self?.state.isLoading = false }
            } catch {
                await MainActor.run { self?.handleError(error, originalBlock: block) }
            }
        }
    }

    // MARK: - Callbacks biométricos

    /// Llamar cuando la autenticación biométrica fue exitosa.
    /// Re-ejecuta la acción pendiente si la hay.
    func onBiometricSuccess() {
        state.showBiometricPrompt = false
        guard let action = pendingAction else { return }
        pendingAction = nil
        launch(action)
    }

    /// Llamar cuando la autenticación biométrica falló.
    func onBiometricFailure() {
        state.showBiometricPrompt = false
        state.isLoading = false
        state.statusMessage = "Autenticación biométrica fallida"
        pendingAction = nil
    }

    /// Llamar cuando el usuario canceló el prompt biométrico.
    func onBiometricDismissed() {
        state.showBiometricPrompt = false
        state.isLoading = false
        pendingAction = nil
    }

    // MARK: - Manejo de errores interno

    private func handleError(_ error: Error, originalBlock: @Sendable @escaping () async throws -> Void) {
        state.isLoading = false

        // Extraer el error raíz (a veces llega envuelto)
        let root = (error as? KeychainError) ?? {
            if let keychainErr = (error as NSError).underlyingErrors.first as? KeychainError {
                return keychainErr
            }
            return nil
        }()

        if let keychainErr = root {
            switch keychainErr {
            case .authFailed:
                // Guardar bloque y mostrar prompt biométrico
                AppLogger.ui().warning("BiometricAwareViewModel: autenticación requerida")
                pendingAction = originalBlock
                state.showBiometricPrompt = true

            case .biometryInvalidated:
                // Equivalente a KeyPermanentlyInvalidatedException de Android
                AppLogger.ui().error("BiometricAwareViewModel: claves invalidadas por cambios biométricos")
                state.statusMessage = "Las claves fueron invalidadas por cambios en la biometría. Por favor, regenera las claves."
                pendingAction = nil

            default:
                state.statusMessage = "Error: \(error.localizedDescription)"
            }
        } else {
            AppLogger.ui().error("BiometricAwareViewModel: error inesperado: \(error)")
            state.statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}
