// VPJWTBuilder.swift
// DIDBlockchainlessDemo
//
// Construye el Verifiable Presentation (VP) JWT para presentar credenciales.
// Equivalente exacto a VpJWTBuilder.kt de Android.

import Foundation

/// Construye un VP JWT firmado con ES256K.
///
/// El VP JWT empaqueta una o más VCs y permite al holder demostrar ante el Verifier
/// que las posee y que le pertenecen, sin necesitar un nonce previo del verifier.
///
/// Header:
/// ```json
/// { "alg": "ES256K", "typ": "JWT", "kid": "did:key:z...#z..." }
/// ```
///
/// Payload:
/// ```json
/// {
///   "iss": "did:key:z...",
///   "aud": "https://backend/",
///   "iat": <unix>,
///   "exp": <unix + 300>,
///   "vp": {
///     "@context": ["https://www.w3.org/2018/credentials/v1"],
///     "type": ["VerifiablePresentation"],
///     "verifiableCredential": ["<VC_JWT>"]
///   }
/// }
/// ```
final class VPJWTBuilder: Sendable {

    private let keyManager: DIDKeyManager

    init(keyManager: DIDKeyManager) {
        self.keyManager = keyManager
    }

    /// Construye y firma el VP JWT.
    ///
    /// - Parameters:
    ///   - verifiableCredentialJWT: El JWT de la VC a presentar (tal como fue emitido por el issuer).
    ///   - audience: URL del verifier (campo `aud`).
    /// - Returns: VP JWT firmado en formato `header.payload.signature`.
    func build(
        verifiableCredentialJWT: String,
        audience: String
    ) async throws -> String {
        let now = Int64(Date().timeIntervalSince1970)

        let header: [String: Any] = [
            "alg": "ES256K",
            "typ": "JWT",
            "kid": try await keyManager.getKeyID()
        ]

        let payload: [String: Any] = [
            "iss": try await keyManager.getDID(),
            "aud": audience,
            "iat": now,
            "exp": now + jwtExpirySeconds,
            "vp": [
                "@context": ["https://www.w3.org/2018/credentials/v1"],
                "type": ["VerifiablePresentation"],
                "verifiableCredential": [verifiableCredentialJWT]
            ] as [String: Any]
        ]

        return try await buildSignedJWT(header: header, payload: payload, keyManager: keyManager)
    }
}
