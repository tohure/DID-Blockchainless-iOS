// Data+Base64URL.swift
// DIDBlockchainlessDemo
//
// Extensiones para Base64URL encoding/decoding (RFC 4648 §5, sin padding).
// Equivalente a JwtExtensions.kt → ByteArray.toBase64Url() de Android.

import Foundation

extension Data {

    /// Codifica en Base64URL **sin padding** ('=' eliminado, '+' → '-', '/' → '_').
    ///
    /// Formato estándar para el contenido de JWT (RFC 7515 §2).
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Decodifica desde Base64URL (con o sin padding).
    init?(base64URLEncoded string: String) {
        // Restaurar padding estándar
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        guard let data = Data(base64Encoded: base64) else { return nil }
        self = data
    }
}

extension String {
    /// Codifica este String (UTF-8) en Base64URL sin padding.
    func base64URLEncoded() -> String {
        Data(utf8).base64URLEncodedString()
    }
}
