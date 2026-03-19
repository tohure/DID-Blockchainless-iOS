// CredentialStore.swift
// DIDBlockchainlessDemo
//
// Persiste VCs cifradas en el Keychain (en vez de SharedPreferences en Android).
// Equivalente a CredentialStore.kt de Android — pero con Keychain en lugar de
// SharedPreferences, dando mayor seguridad nativa sin necesidad de cifrarlo de nuevo.

import Foundation
import os
import LocalAuthentication

/// Almacén de Verifiable Credentials cifradas.
///
/// Persiste el payload ya cifrado (producido por `CryptoManager`) en el Keychain
/// de iOS bajo el prefijo `vc_`. Esto equivale a `CredentialStore.kt` de Android
/// que usa `SharedPreferences` (el cifrado ya viene de `CryptoManager`).
///
/// En iOS usamos Keychain directamente, que ofrece:
/// - Cifrado AES nativo del sistema operativo
/// - Aislamiento por app (`kSecAttrService`)
/// - No migra a backups ni a iCloud (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
final class CredentialStore: Sendable {

    private let keychain = KeychainHelper.shared
    private let keyPrefix = "vc_"

    // MARK: - CRUD

    /// Guarda el payload cifrado bajo `id`.
    func save(id: String, encryptedPayload: String) async throws {
        guard let data = encryptedPayload.data(using: .utf8) else {
            throw CredentialStoreError.encodingFailed
        }
        // Sin biometría — el payload ya está cifrado por CryptoManager
        try await keychain.save(data, forKey: keyPrefix + id, withBiometric: false)
        AppLogger.storage().debug_only("CredentialStore: guardado '\(id)'")
    }

    /// Recupera el payload cifrado para `id`, o `nil` si no existe.
    func load(id: String) async throws -> String? {
        do {
            let data = try await keychain.load(forKey: keyPrefix + id)
            return String(data: data, encoding: .utf8)
        } catch KeychainError.itemNotFound {
            return nil
        }
    }

    /// Elimina la credencial con `id`.
    func delete(id: String) async throws {
        try await keychain.delete(forKey: keyPrefix + id)
    }

    /// Lista todos los IDs de credenciales almacenadas.
    ///
    /// Busca todos los ítems del Keychain con el service de la app y el prefijo `vc_`.
    func listIDs() async -> [String] {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "dev.tohure.DIDBlockchainlessDemo",
            kSecReturnAttributes: true,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecUseAuthenticationContext: context
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[CFString: Any]] else {
            return []
        }
        return items
            .compactMap { $0[kSecAttrAccount] as? String }
            .filter { $0.hasPrefix(keyPrefix) }
            .map { String($0.dropFirst(keyPrefix.count)) }
    }

    /// Elimina todas las credenciales almacenadas.
    func clear() async throws {
        let ids = await listIDs()
        for id in ids {
            try await delete(id: id)
        }
    }

    /// Comprueba si existe una credencial bajo `id`.
    func exists(id: String) async -> Bool {
        await keychain.exists(forKey: keyPrefix + id)
    }
}

// MARK: - CredentialStoreError

enum CredentialStoreError: Error, LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        "Error al codificar el payload de la credencial."
    }
}
