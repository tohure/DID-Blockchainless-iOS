// RSAViewModel.swift
// DIDBlockchainlessDemo
//
// ViewModel para la pantalla de cifrado AES-256-GCM.
// Equivalente a RsaViewModel.kt de Android.

import Foundation
import Observation

/// ViewModel para la pantalla de cifrado / descifrado de VCs.
@Observable
@MainActor
final class RSAViewModel: BiometricAwareViewModel<RSAUIState> {

    @ObservationIgnored private let cryptoManager = CryptoManager()

    init() {
        super.init(initialState: RSAUIState())
        Task { await refreshKeyStatus() }
    }

    // MARK: - Acciones

    /// Genera la clave AES-256 si no existe.
    func generateKey() {
        launch { [self] in
            let generated = try await cryptoManager.generateKeyIfNeeded()
            let level = cryptoManager.getSecurityLevel()
            let msg = generated
                ? "Clave AES-256 generada en: \(level.rawValue)"
                : "La clave ya existía"
            await MainActor.run {
                state.keyExists = true
                state.securityLevel = level
                state.statusMessage = msg
            }
        }
    }

    /// Elimina la clave AES del Keychain.
    func deleteKey() {
        launch { [self] in
            try await cryptoManager.deleteKey()
            await MainActor.run {
                state.keyExists = false
                state.securityLevel = .unknown
                state.encryptedText = ""
                state.decryptedText = ""
                state.statusMessage = "Clave eliminada"
            }
        }
    }

    /// Cifra `inputText` con AES-256-GCM.
    func encrypt() {
        guard !state.inputText.isEmpty else {
            state.statusMessage = "Escribe algo para cifrar"
            return
        }
        launch { [self] in
            let encrypted = try await cryptoManager.encrypt(state.inputText)
            await MainActor.run {
                state.encryptedText = encrypted
                state.statusMessage = "Texto cifrado con AES-256-GCM ✓"
            }
        }
    }

    /// Descifra `encryptedText` con AES-256-GCM.
    func decrypt() {
        guard !state.encryptedText.isEmpty else {
            state.statusMessage = "No hay texto cifrado para descifrar"
            return
        }
        launch { [self] in
            let decrypted = try await cryptoManager.decrypt(state.encryptedText)
            await MainActor.run {
                state.decryptedText = decrypted
                state.statusMessage = "Texto descifrado correctamente ✓"
            }
        }
    }

    // MARK: - Privado

    private func refreshKeyStatus() async {
        let exists = await cryptoManager.keyExists()
        let level = cryptoManager.getSecurityLevel()
        state.keyExists = exists
        state.securityLevel = level
    }
}
