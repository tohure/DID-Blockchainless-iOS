// RSAUIState.swift
// DIDBlockchainlessDemo
//
// Estado inmutable de la pantalla RSA/Cifrado.

import Foundation

/// Estado de la pantalla de cifrado (CryptoManager).
struct RSAUIState: BiometricAwareState {

    // ── Claves ────────────────────────────────────────────────────────
    var keyExists: Bool = false
    var securityLevel: SecurityLevel = .unknown

    // ── Cifrado / Descifrado ──────────────────────────────────────────
    var inputText: String = ""
    var encryptedText: String = ""
    var decryptedText: String = ""

    // ── Estado general ────────────────────────────────────────────────
    var statusMessage: String = ""
    var isLoading: Bool = false
    var showBiometricPrompt: Bool = false
}
