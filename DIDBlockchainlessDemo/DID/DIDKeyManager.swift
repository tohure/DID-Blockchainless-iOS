// DIDKeyManager.swift
// DIDBlockchainlessDemo
//
// Gestiona el par de claves secp256k1 que define la identidad DID del dispositivo.
//
// Flujo:
//   1. Genera par secp256k1 con P256K (swift-secp256k1 v0.22+) en RAM
//   2. Cifra la clave privada con AES-256-GCM (clave wrap en Keychain biométrico)
//   3. Almacena: encrypted_priv + pub_bytes en Keychain
//   4. Deriva DID: did:key:z<base58btc([0xe7,0x01] + compressed_pub)>
//   5. Firma ES256K: descifra privada → ECDSA(SHA-256) → limpia RAM

import Foundation
import os
import CryptoKit
import P256K  // swift-secp256k1 v0.22+ (21-DOT-DEV/swift-secp256k1)

/// Gestiona el par de claves secp256k1 que define la identidad DID del dispositivo.
///
/// **Thread safety:** declarado como `actor` — todas las operaciones de Keychain son serializadas.
actor DIDKeyManager {

    // MARK: - Claves de Keychain

    private let encPrivKey = "DIDKeyManager.encPriv"
    private let pubBytesKey = "DIDKeyManager.pubBytes"
    private let wrapAESKey  = "DIDWrapKey"

    // MARK: - Constantes criptográficas

    /// Prefijo multicodec secp256k1-pub (varint 0xe7 0x01).
    private let multicodecPrefix: [UInt8] = [0xe7, 0x01]

    // MARK: - Generación de claves

    /// Genera el par secp256k1 si no existe aún.
    /// - Returns: `true` si se generaron claves nuevas, `false` si ya existían.
    func generateKeysIfNeeded() async throws -> Bool {
        let keychain = KeychainHelper.shared
        if await keychain.exists(forKey: pubBytesKey) { return false }

        // 1. Generar par secp256k1 en RAM (P256K v0.22 API)
        let privateKey = try P256K.Signing.PrivateKey(format: .compressed)

        // Clave pública comprimida (33 bytes: 0x02/0x03 + x)
        // En P256K v0.22, publicKey.dataRepresentation da los bytes en el formato solicitado
        let pubCompressed = Data(privateKey.publicKey.dataRepresentation)
        guard pubCompressed.count == 33 else {
            throw DIDKeyManagerError.keyGenerationFailed("La clave pública comprimida no tiene 33 bytes (\(pubCompressed.count))")
        }

        // Clave privada (32 bytes — escalar S)
        var privBytes = Data(privateKey.dataRepresentation)

        // 2. Cifrar clave privada con AES-GCM (clave wrap en Keychain)
        let wrapKey = try await getOrCreateWrapKey()
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(privBytes, using: wrapKey, nonce: nonce)

        // 3. Limpiar clave privada de RAM inmediatamente
        privBytes = Data(repeating: 0, count: privBytes.count)

        guard let encPriv = sealedBox.combined else {
            throw DIDKeyManagerError.keyGenerationFailed("AES.GCM.seal no produjo combined data")
        }

        // 4. Persistir en Keychain (sin biometría — la clave AES wrap sí tiene biometría)
        try await keychain.save(encPriv, forKey: encPrivKey, withBiometric: false)
        try await keychain.save(pubCompressed, forKey: pubBytesKey, withBiometric: false)

        AppLogger.did().debug_only("DIDKeyManager: par secp256k1 generado.")
        return true
    }

    /// Verifica si las claves DID existen en el Keychain.
    func keysExist() async -> Bool {
        await KeychainHelper.shared.exists(forKey: pubBytesKey)
    }

    /// Elimina todas las claves DID del Keychain.
    func deleteKeys() async throws {
        let keychain = KeychainHelper.shared
        try await keychain.delete(forKey: encPrivKey)
        try await keychain.delete(forKey: pubBytesKey)
        try await keychain.delete(forKey: wrapAESKey)
        AppLogger.did().info("DIDKeyManager: claves eliminadas")
    }

    // MARK: - Derivación DID

    /// Deriva el DID según el método did:key para secp256k1.
    /// ```
    /// [0xe7, 0x01] + compressed_pub(33) → base58btc → "z" + encoded → "did:key:z..."
    /// ```
    func getDID() async throws -> String {
        let pubBytes = try await publicKeyBytes()
        var multikey = Data(multicodecPrefix)
        multikey.append(pubBytes)
        let encoded = "z" + Base58.encode(multikey)
        return "did:key:\(encoded)"
    }

    /// Devuelve el key ID para el header JWT.
    ///
    /// Formato: `did:key:zQ3sh...#zQ3sh...`
    func getKeyID() async throws -> String {
        let did = try await getDID()
        let fragment = String(did.dropFirst("did:key:".count))
        return "\(did)#\(fragment)"
    }

    // MARK: - Firma ES256K

    /// Firma `data` con ES256K (ECDSA secp256k1 / SHA-256).
    func sign(_ data: Data) async throws -> Data {
        var privBytes = try await loadPrivateKey()
        defer {
            // Limpiar clave privada de RAM en el bloque defer (seguro incluso ante throws).
            privBytes = Data(repeating: 0, count: privBytes.count)
        }

        // Reconstruir la clave privada en RAM (formato comprimido)
        let privateKey = try P256K.Signing.PrivateKey(dataRepresentation: privBytes, format: .compressed)

        // ECDSA con SHA-256 (ES256K según RFC 8812)
        // signature(for: Digest) pasa Array(digest) directamente a secp256k1_ecdsa_sign sin hashing adicional
        // NO usar signature(for: Data): ese overload llama SHA256 internamente (doble hash).
        let signature = try privateKey.signature(for: SHA256.hash(data: data))

        // compactRepresentation = R‖S (64 bytes compact format guarantees via libsecp256k1)
        // IMPORTANTE: NO usar `signature.dataRepresentation` porque expone el struct opaco de C
        // de libsecp256k1, que no está garantizado que sea exactamente R||S.
        let rawSig = try signature.compactRepresentation
        guard rawSig.count == 64 else {
            throw DIDKeyManagerError.signingFailed("La firma no tiene el formato R‖S esperado (64 bytes, actual: \(rawSig.count))")
        }
        return rawSig
    }

    /// Nivel de seguridad del almacenamiento de claves.
    nonisolated func getSecurityLevel() -> SecurityLevel {
        KeychainHelper.shared.securityLevel()
    }

    // MARK: - Privado

    private func publicKeyBytes() async throws -> Data {
        do {
            return try await KeychainHelper.shared.load(forKey: pubBytesKey)
        } catch {
            throw DIDKeyManagerError.keysNotFound
        }
    }

    private func loadPrivateKey() async throws -> Data {
        let encPriv: Data
        do {
            encPriv = try await KeychainHelper.shared.load(forKey: encPrivKey)
        } catch {
            throw DIDKeyManagerError.keysNotFound
        }
        let wrapKey = try await getOrCreateWrapKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encPriv)
        return try AES.GCM.open(sealedBox, using: wrapKey)
    }

    private func getOrCreateWrapKey() async throws -> SymmetricKey {
        let keychain = KeychainHelper.shared
        if await keychain.exists(forKey: wrapAESKey) {
            let keyData = try await keychain.load(forKey: wrapAESKey)
            return SymmetricKey(data: keyData)
        }
        // Crear nueva clave AES-256 protegida con biometría
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try await keychain.save(keyData, forKey: wrapAESKey, withBiometric: true)
        AppLogger.did().debug_only("DIDKeyManager: clave AES wrap creada en Keychain con biometría")
        return newKey
    }
}

// MARK: - DIDKeyManagerError

enum DIDKeyManagerError: Error, LocalizedError {
    case keysNotFound
    case keyGenerationFailed(String)
    case signingFailed(String)

    var errorDescription: String? {
        switch self {
        case .keysNotFound:
            return "Claves DID no encontradas. Genera las claves primero."
        case .keyGenerationFailed(let msg):
            return "Error generando claves DID: \(msg)"
        case .signingFailed(let msg):
            return "Error firmando datos: \(msg)"
        }
    }
}
