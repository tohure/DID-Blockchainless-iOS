// JWTSigner.swift
// DIDBlockchainlessDemo
//
// Construye y firma JWTs con ES256K.

import Foundation
import CryptoKit

/// Tiempo de validez de los JWTs emitidos (5 minutos — igual que Android).
let jwtExpirySeconds: Int64 = 300

/// Construye y firma un JWT con el formato `header.payload.signature`.
///
/// - Parameters:
///   - header: Diccionario que se serializa como JSON → Base64URL para el header.
///   - payload: Diccionario que se serializa como JSON → Base64URL para el payload.
///   - keyManager: `DIDKeyManager` que provee la firma ES256K.
/// - Returns: JWT completo en formato `header.payload.signature`.
func buildSignedJWT(
    header: [String: Any],
    payload: [String: Any],
    keyManager: DIDKeyManager
) async throws -> String {
    let headerB64 = try jsonToBase64URL(header)
    let payloadB64 = try jsonToBase64URL(payload)
    let signingInput = "\(headerB64).\(payloadB64)"

    let signatureData = try await keyManager.sign(Data(signingInput.utf8))
    let signatureB64 = signatureData.base64URLEncodedString()

    return "\(signingInput).\(signatureB64)"
}

// MARK: - Helpers

private func jsonToBase64URL(_ dict: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
    // JSONSerialization escapa las '/' como '\/' (ej: "https:\/\/...").
    let jsonString = String(data: data, encoding: .utf8)!
        .replacingOccurrences(of: "\\/", with: "/")
    return Data(jsonString.utf8).base64URLEncodedString()
}
