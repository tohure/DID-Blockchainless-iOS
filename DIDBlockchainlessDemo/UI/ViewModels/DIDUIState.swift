// DIDUIState.swift
// DIDBlockchainlessDemo
//
// Estado inmutable de la pantalla DID.
// Equivalente a DidUiState.kt de Android.

import Foundation

/// Estado de la pantalla DID.
///
/// Se modela como `struct` para que `@Observable` detecte cambios
/// por value-type semantics, igual que `data class` en Kotlin.
struct DIDUIState: BiometricAwareState {

    // ── Identidad DID (secp256k1) ─────────────────────────────────────
    var didKeysExist: Bool = false
    var did: String = ""
    var keyID: String = ""
    var didSecurityLevel: SecurityLevel = .unknown

    // ── Flujo de emisión (nonce → ProofJWT) ──────────────────────────
    var lastProofJWT: String = ""

    // ── Credencial y Metadatos ────────────────────────────────────────
    var encryptedCredential: String = ""   // Payload cifrado (AES-GCM)
    var decryptedMetadata: String = ""     // JSON de metadatos (para mostrar)

    // ── Validación ────────────────────────────────────────────────────
    var validationResponseJSON: String = ""

    // ── Estado general ────────────────────────────────────────────────
    var statusMessage: String = ""
    var isLoading: Bool = false
    var showBiometricPrompt: Bool = false
}
