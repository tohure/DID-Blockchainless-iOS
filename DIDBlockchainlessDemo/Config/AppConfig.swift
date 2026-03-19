// AppConfig.swift
// DIDBlockchainlessDemo
//

import Foundation

/// Acceso centralizado a la configuración del entorno.
enum AppConfig {

    /// URL base del backend (Issuer / Verifier).
    static func getBaseURL() -> URL {
        guard
            let host = Bundle.main.infoDictionary?["BASE_URL"] as? String,
            !host.isEmpty,
            host != "$(BASE_URL)",
            let url = URL(string: "https://\(host)/")
        else {
            fatalError(
                """
                BASE_URL no configurada.
                Edita Secrets.xcconfig y añade solo el hostname (sin https://):
                  BASE_URL = mi-backend.azurecontainerapps.io
                """
            )
        }
        return url
    }
}
