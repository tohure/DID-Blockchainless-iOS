// APIClient.swift
// DIDBlockchainlessDemo
//
// Cliente HTTP centralizado con async/await y URLSession.

import Foundation
import os

/// Actor que gestiona todas las solicitudes HTTP al backend.
///
/// **Thread safety:** `actor` garantiza acceso serializado a la sesión y configuración.
actor APIClient {

    // MARK: - Singleton

    static let shared = APIClient()
    private init() {}

    // MARK: - Configuración

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // Los campos snake_case en JSON se mapean automáticamente si se usan CodingKeys
        return d
    }()

    // MARK: - Petición genérica

    /// Ejecuta `endpoint` y decodifica la respuesta en `T`.
    ///
    /// Lanza `APIError` tipado en caso de error HTTP o de decodificación.
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try endpoint.urlRequest(baseURL: AppConfig.getBaseURL())

        // Logging condicional (DEBUG solamente)
        #if DEBUG
        AppLogger.network().debug("→ \(urlRequest.httpMethod ?? "?") \(urlRequest.url?.absoluteString ?? "?")")
        if let body = urlRequest.httpBody, let bodyStr = String(data: body, encoding: .utf8) {
            AppLogger.network().debug("  body: \(bodyStr)")
        }
        #endif

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        #if DEBUG
        AppLogger.network().debug("← \(httpResponse.statusCode) (\(data.count) bytes)")
        if let responseStr = String(data: data, encoding: .utf8) {
            AppLogger.network().debug("  body: \(responseStr)")
        }
        #endif

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8)
            AppLogger.network().error("HTTP \(httpResponse.statusCode): \(errorBody ?? "(sin cuerpo)")")
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLogger.network().error("Decodificación fallida: \(error)")
            throw APIError.decodingError(error)
        }
    }

    /// Ejecuta `endpoint` y descarta el cuerpo de la respuesta (`Void`).
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try endpoint.urlRequest(baseURL: AppConfig.getBaseURL())

        #if DEBUG
        AppLogger.network().debug("→ \(urlRequest.httpMethod ?? "?") \(urlRequest.url?.absoluteString ?? "?")")
        #endif

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }
    }
}
