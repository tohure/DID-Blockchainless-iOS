// CryptoManager.swift
// DIDBlockchainlessDemo
//
// Cifrado AES-256-GCM para Verifiable Credentials usando el Keychain como
// almacén seguro de la clave simétrica.
//
// Equivalente a CryptoManager.kt de Android, pero simplificado:
// En iOS el Keychain ya protege la clave simétrica a nivel de hardware
// (Secure Enclave backed), por lo que no necesitamos el paso intermedio
// de RSA que requería Android. El resultado es más elegante y igualmente seguro.

import Foundation
import os
import CryptoKit

/// Gestiona el cifrado y descifrado de Verifiable Credentials con AES-256-GCM.
///
/// **Esquema de cifrado:**
/// ```
/// Clave AES-256 (32 bytes aleatorios)
///     │  almacenada en Keychain (Secure Enclave backed)
///     │  protegida con biometría (kSecAccessControlBiometryCurrentSet)
///     ▼
/// AES-256-GCM con nonce de 96 bits (12 bytes) generado por CryptoKit
///     │
///     ▼
/// Payload cifrado = [nonce(12)] + [ciphertext + tag(16)]
/// → Base64 para almacenamiento/transmisión
/// ```
///
/// **Por qué solo AES y no RSA+AES como en Android:**
/// En iOS el Keychain protege la clave AES a nivel de hardware (Secure Enclave).
/// No necesitamos RSA como envoltorio adicional — la clave nunca sale del hardware.
final class CryptoManager: Sendable {

    // MARK: - Claves de Keychain

    private let aesKeyKeychainKey = "CryptoManagerAESKey"

    // MARK: - Pública API

    /// Genera la clave AES si no existe aún.
    /// - Returns: `true` si se generó una clave nueva, `false` si ya existía.
    func generateKeyIfNeeded() async throws -> Bool {
        let keychain = KeychainHelper.shared
        if await keychain.exists(forKey: aesKeyKeychainKey) { return false }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        try await keychain.save(keyData, forKey: aesKeyKeychainKey, withBiometric: true)
        AppLogger.crypto().debug_only("CryptoManager: clave AES-256 generada y guardada en Keychain")
        return true
    }

    /// Verifica si la clave AES existe en el Keychain.
    func keyExists() async -> Bool {
        await KeychainHelper.shared.exists(forKey: aesKeyKeychainKey)
    }

    /// Elimina la clave AES del Keychain.
    func deleteKey() async throws {
        try await KeychainHelper.shared.delete(forKey: aesKeyKeychainKey)
    }

    /// Cifra `plainText` con AES-256-GCM.
    ///
    /// - Parameter plainText: Texto plano (JSON o JWT de la VC).
    /// - Returns: Base64 del payload `[nonce(12)] + [ciphertext+tag]`.
    /// - Throws: `KeychainError.authFailed` si se requiere biometría.
    func encrypt(_ plainText: String) async throws -> String {
        let key = try await loadAESKey()
        let data = Data(plainText.utf8)

        // CryptoKit genera el nonce de 96 bits (12 bytes) de forma segura
        let sealedBox = try AES.GCM.seal(data, using: key)

        // Combinar: nonce (12) + ciphertext + tag (16)
        guard let combined = sealedBox.combined else {
            throw CryptoManagerError.encryptionFailed("AES.GCM.seal no produjo combined data")
        }
        return combined.base64URLEncodedString()
    }

    /// Descifra un payload producido por `encrypt(_:)`.
    ///
    /// - Parameter ciphertext: Base64URL del payload cifrado.
    /// - Returns: Texto plano original.
    /// - Throws: `KeychainError.authFailed` si se requiere biometría.
    func decrypt(_ ciphertext: String) async throws -> String {
        let key = try await loadAESKey()

        guard let combined = Data(base64URLEncoded: ciphertext) else {
            throw CryptoManagerError.decryptionFailed("Formato de ciphertext inválido (no es Base64URL)")
        }

        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let plainData = try AES.GCM.open(sealedBox, using: key)

        guard let plainText = String(data: plainData, encoding: .utf8) else {
            throw CryptoManagerError.decryptionFailed("Los datos descifrados no son UTF-8 válido")
        }
        return plainText
    }

    /// Nivel de seguridad del almacenamiento de claves en este dispositivo.
    func getSecurityLevel() -> SecurityLevel {
        KeychainHelper.shared.securityLevel()
    }

    // MARK: - Privado

    private func loadAESKey() async throws -> SymmetricKey {
        let keyData = try await KeychainHelper.shared.load(forKey: aesKeyKeychainKey)
        return SymmetricKey(data: keyData)
    }
}

// MARK: - CryptoManagerError

enum CryptoManagerError: Error, LocalizedError {
    case encryptionFailed(String)
    case decryptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .encryptionFailed(let msg): return "Error de cifrado: \(msg)"
        case .decryptionFailed(let msg): return "Error de descifrado: \(msg)"
        }
    }
}
