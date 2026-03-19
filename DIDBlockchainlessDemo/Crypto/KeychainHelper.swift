// KeychainHelper.swift
// DIDBlockchainlessDemo

import Foundation
import os
import Security
import LocalAuthentication

/// Actor que encapsula CRUD del Keychain con soporte opcional de biometría.
///
/// **Thread safety:** declarado como `actor` — todas las llamadas son serializadas
/// automáticamente por el runtime de Swift Concurrency.
actor KeychainHelper {

    // MARK: - Singleton

    static let shared = KeychainHelper()
    private init() {}

    // MARK: - Constantes

    private let service = Bundle.main.bundleIdentifier ?? "dev.tohure.DIDBlockchainlessDemo"

    // MARK: - Save

    /// Guarda `data` en el Keychain bajo `key`.
    ///
    /// - Parameters:
    ///   - data: Bytes a almacenar.
    ///   - key: Identificador único del ítem.
    ///   - withBiometric: Si `true`, protege el ítem con `kSecAccessControlBiometryCurrentSet`
    ///     (Face ID / Touch ID, sin fallback a passcode, se invalida al cambiar biometría).
    ///
    /// - Throws: `KeychainError` en caso de fallo.
    func save(_ data: Data, forKey key: String, withBiometric: Bool = false) throws {
        // Eliminar entrada previa si existe
        try? delete(forKey: key)

        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            // Solo este dispositivo — nunca migra a iCloud ni backups
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        if withBiometric && CryptoConfig.useBiometrics() {
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                // BiometryCurrentSet: Face ID / Touch ID, SIN PIN fallback
                // Se invalida si se añade / elimina biometría
                .biometryCurrentSet,
                &error
            ) else {
                AppLogger.crypto().error("KeychainHelper: error creando AccessControl: \(error.debugDescription)")
                throw KeychainError.unexpectedStatus(errSecParam)
            }
            // Sobrescribir accesibilidad con el AccessControl biométrico
            query.removeValue(forKey: kSecAttrAccessible)
            query[kSecAttrAccessControl] = access
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            AppLogger.crypto().error("KeychainHelper save('\(key)'): OSStatus \(status)")
            throw KeychainError.unexpectedStatus(status)
        }
        AppLogger.crypto().debug_only("KeychainHelper: guardado '\(key)' (biometric=\(withBiometric))")
    }

    // MARK: - Load

    /// Lee los datos almacenados bajo `key`.
    ///
    /// Si el ítem requiere biometría, el sistema presentará el prompt automáticamente.
    /// Si el usuario cancela, se lanza `KeychainError.authFailed`.
    ///
    /// - Throws: `KeychainError.itemNotFound` si no existe, `KeychainError.authFailed`
    ///   si la autenticación biométrica falló o fue cancelada.
    func load(forKey key: String) throws -> Data {
        let context = LAContext()
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
            // Pasar el contexto LAContext permite reutilizar una autenticación reciente
            kSecUseAuthenticationContext: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedStatus(errSecInternalError)
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound(key)
        case errSecAuthFailed, errSecUserCanceled, -25293, -128:
            // -25293: errKCInteractionNotAllowed (biometría requerida pero no disponible)
            // -128: errSecUserCanceled
            AppLogger.crypto().warning("KeychainHelper: autenticación requerida para '\(key)'")
            throw KeychainError.authFailed
        default:
            AppLogger.crypto().error("KeychainHelper load('\(key)'): OSStatus \(status)")
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Delete

    /// Elimina el ítem con `key` del Keychain.
    /// No lanza error si el ítem no existe.
    func delete(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Exists

    /// Verifica si existe un ítem bajo `key` sin desencriptarlo.
    func exists(forKey key: String) -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: false,
            kSecMatchLimit: kSecMatchLimitOne,
            // Use local context without UI fallback
            kSecUseAuthenticationContext: context
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        // errSecInteractionNotAllowed significa que existe pero requiere biometría
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    // MARK: - Security Level

    /// Devuelve el nivel de seguridad del Keychain en este dispositivo.
    ///
    /// En iOS 17+ en dispositivos físicos siempre es `.secureEnclave`.
    nonisolated func securityLevel() -> SecurityLevel {
        // En iOS todos los iPhones con iOS 17 tienen Secure Enclave.
        // Podemos verificarlo intentando crear una clave en el SE.
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: false,
                kSecAttrTokenID: kSecAttrTokenIDSecureEnclave
            ] as CFDictionary
        ]
        var error: Unmanaged<CFError>?
        if let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error), error == nil {
            // Limpiar la clave temporal
            _ = key
            return .secureEnclave
        }
        return .keychain
    }
}

// MARK: - KeychainError

/// Errores tipados del Keychain.
enum KeychainError: Error, LocalizedError {
    case itemNotFound(String)
    case authFailed
    case biometryInvalidated
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound(let key):
            return "Keychain: ítem '\(key)' no encontrado."
        case .authFailed:
            return "Autenticación biométrica requerida o fallida."
        case .biometryInvalidated:
            return "Las claves fueron invalidadas por cambios en la biometría. Por favor, regenera las claves."
        case .unexpectedStatus(let status):
            return "Error de Keychain inesperado: OSStatus \(status)."
        }
    }

    /// `true` si el error indica que la biometría del dispositivo cambió
    /// y las claves deben ser regeneradas.
    var isBiometryInvalidated: Bool {
        self == .biometryInvalidated
    }
}

extension KeychainError: Equatable {
    static func == (lhs: KeychainError, rhs: KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.authFailed, .authFailed): return true
        case (.biometryInvalidated, .biometryInvalidated): return true
        case (.itemNotFound(let a), .itemNotFound(let b)): return a == b
        case (.unexpectedStatus(let a), .unexpectedStatus(let b)): return a == b
        default: return false
        }
    }
}
