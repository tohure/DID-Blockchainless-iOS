// SecurityLevel.swift
// DIDBlockchainlessDemo
//
// Equivalente a SecurityLevel.kt de Android.

/// Nivel de seguridad del almacenamiento de claves en el dispositivo.
///
/// En iOS todos los dispositivos con iOS 17+ tienen Secure Enclave,
/// análogo a StrongBox/TEE en Android.
enum SecurityLevel: String, Sendable {
    /// Clave almacenada y operada dentro del Secure Enclave (máxima seguridad).
    case secureEnclave = "Secure Enclave"

    /// Clave en Keychain cifrada por hardware (sin Secure Enclave explícito).
    case keychain = "Keychain"

    /// Solo software — nunca debería ocurrir en dispositivos modernos con iOS 17+.
    case software = "Software"

    /// No se pudo determinar el nivel.
    case unknown = "Unknown"
}
