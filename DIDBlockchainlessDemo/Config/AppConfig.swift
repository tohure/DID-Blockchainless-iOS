// AppConfig.swift
// DIDBlockchainlessDemo
//
// Lee la configuración inyectada en Info.plist desde los archivos .xcconfig.
// Equivalente a BuildConfig.BASE_URL de Android.
//
// NOTA XCCONFIG: el formato xcconfig trata `//` como inicio de comentario,
// por lo que almacenar `https://host` trunca el valor a `https:`.
// Solución: guardar SOLO el hostname en Secrets.xcconfig y añadir el
// scheme en código aquí abajo.

import Foundation

/// Acceso centralizado a la configuración del entorno.
///
/// `BASE_URL` en `Secrets.xcconfig` debe contener **solo el hostname**, sin scheme:
/// ```
/// BASE_URL = mi-backend.azurecontainerapps.io
/// ```
/// El scheme `https://` se añade aquí en tiempo de ejecución.
enum AppConfig {

    /// URL base del backend (Issuer / Verifier).
    static func getBaseURL() -> URL {
        guard
            let host = Bundle.main.infoDictionary?["BASE_URL"] as? String,
            !host.isEmpty,
            host != "$(BASE_URL)",
            // Construir URL completa: xcconfig no puede contener `://` (lo trata como comentario)
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
