// APIError.swift
// DIDBlockchainlessDemo
//
// Errores tipados de la capa de red.

import Foundation

/// Errores de la capa de red (APIClient / CredentialRepository).
enum APIError: Error, LocalizedError {
    /// El servidor devolvió un código HTTP de error con cuerpo opcional.
    case httpError(statusCode: Int, body: String?)
    /// La respuesta no se pudo decodificar al tipo esperado.
    case decodingError(Error)
    /// Error de red (sin conexión, timeout, etc.).
    case networkError(Error)
    /// URL inválida.
    case invalidURL
    /// Error no categorizado.
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body):
            return "Error HTTP \(code)\(body.map { ": \($0)" } ?? "")."
        case .decodingError(let err):
            return "Error de decodificación: \(err.localizedDescription)"
        case .networkError(let err):
            return "Error de red: \(err.localizedDescription)"
        case .invalidURL:
            return "URL inválida."
        case .unknown(let err):
            return "Error desconocido: \(err.localizedDescription)"
        }
    }
}
