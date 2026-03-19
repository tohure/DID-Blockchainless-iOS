// APIEndpoint.swift
// DIDBlockchainlessDemo
//
// Definición tipada de todos los endpoints del backend.

import Foundation

/// Enum que describe cada endpoint REST del backend.
///
/// Cada caso encapsula method, path, query params y body —
/// de forma similar a cómo Retrofit mapea anotaciones `@GET`/`@POST`.
enum APIEndpoint: Sendable {

    // MARK: - DID Management

    /// `POST /dids/register`
    case registerDID(DIDRegisterRequest)

    // MARK: - Credentials

    /// `GET /credentials/nonce?holder_did=<did>`
    case getNonce(holderDID: String)

    /// `POST /credentials/issue`
    case issueCredential(IssueVCRequest)

    /// `GET /credentials?holder_did=<did>`
    case getMetadata(holderDID: String)

    /// `POST /credentials/verify`
    case verifyVP(ValidateVPRequest)

    /// `GET /credentials/<id>`  (con Authorization bearer)
    case getCredential(id: String, token: String)

    // MARK: - URLRequest construction

    /// Construye un `URLRequest` listo para ejecutar con `URLSession`.
    func urlRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems?.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    // MARK: - Componentes por caso

    private var method: String {
        switch self {
        case .registerDID, .issueCredential, .verifyVP: return "POST"
        case .getNonce, .getMetadata, .getCredential: return "GET"
        }
    }

    private var path: String {
        switch self {
        case .registerDID:           return "dids/register"
        case .getNonce:              return "credentials/nonce"
        case .issueCredential:       return "credentials/issue"
        case .getMetadata:           return "credentials"
        case .verifyVP:              return "credentials/verify"
        case .getCredential(let id, _): return "credentials/\(id)"
        }
    }

    private var queryItems: [String: String]? {
        switch self {
        case .getNonce(let did):     return ["holder_did": did]
        case .getMetadata(let did):  return ["holder_did": did]
        default:                     return nil
        }
    }

    private var body: (any Encodable)? {
        switch self {
        case .registerDID(let req):   return req
        case .issueCredential(let req): return req
        case .verifyVP(let req):      return req
        default:                      return nil
        }
    }

    private var headers: [String: String]? {
        switch self {
        case .getCredential(_, let token):
            return ["Authorization": "Bearer \(token)"]
        default:
            return nil
        }
    }
}
