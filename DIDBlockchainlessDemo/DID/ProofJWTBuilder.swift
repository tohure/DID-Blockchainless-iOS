// ProofJWTBuilder.swift
// DIDBlockchainlessDemo
//
// Construye el Proof JWT para solicitar una Verifiable Credential al issuer.
// Equivalente exacto a ProofJWTBuilder.kt de Android.

import Foundation

/// Construye un Proof JWT firmado con ES256K.
///
/// El Proof JWT demuestra al issuer que el holder posee la clave privada
/// correspondiente a su DID, sin revelarla. Es el mecanismo central de
/// autenticación del protocolo (OpenID4VCI draft).
///
/// Header:
/// ```json
/// { "alg": "ES256K", "typ": "openid4vci-proof+jwt", "kid": "did:key:z...#z..." }
/// ```
///
/// Payload:
/// ```json
/// {
///   "iss": "did:key:z...",
///   "aud": "https://issuer/",
///   "iat": <unix>,
///   "exp": <unix + 300>,
///   "nonce": "<nonce>",
///   "credential_type": "UniversityDegreeCredential",
///   "subject_claims": { "givenName": "...", ... }
/// }
/// ```
final class ProofJWTBuilder: Sendable {

    private let keyManager: DIDKeyManager

    init(keyManager: DIDKeyManager) {
        self.keyManager = keyManager
    }

    /// Construye y firma el Proof JWT.
    ///
    /// - Parameters:
    ///   - issuerURL: URL del issuer (campo `aud`).
    ///   - nonce: Nonce de un solo uso obtenido del backend.
    ///   - credentialType: Tipo de credencial (ej. `"UniversityDegreeCredential"`).
    ///   - subjectClaims: Claims del sujeto (ej. givenName, familyName, email).
    /// - Returns: JWT firmado en formato estándar `header.payload.signature`.
    func build(
        issuerURL: String,
        nonce: String,
        credentialType: String,
        subjectClaims: [String: String]
    ) async throws -> String {
        let did = try await keyManager.getDID()
        let kid = try await keyManager.getKeyID()
        let now = Int64(Date().timeIntervalSince1970)

        let header: [String: Any] = [
            "alg": "ES256K",
            "typ": "openid4vci-proof+jwt",
            "kid": kid
        ]

        let payload: [String: Any] = [
            "iss": did,
            "aud": issuerURL,
            "iat": now,
            "exp": now + jwtExpirySeconds,
            "nonce": nonce,
            "credential_type": credentialType,
            "subject_claims": subjectClaims
        ]

        return try await buildSignedJWT(header: header, payload: payload, keyManager: keyManager)
    }
}
