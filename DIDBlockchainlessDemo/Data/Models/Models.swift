// Models.swift
// DIDBlockchainlessDemo

@preconcurrency import Foundation

// MARK: - DID Register

struct DIDRegisterRequest: Codable, Sendable {
    let clientId: String
    let did: String
    enum CodingKeys: String, CodingKey { case clientId = "client_id"; case did }
}

struct DIDRegisterResponse: Codable, Sendable {
    let did: String
    let clientId: String
    let active: Bool
    enum CodingKeys: String, CodingKey { case did; case clientId = "client_id"; case active }
}

// MARK: - Nonce

struct NonceResponse: Codable, Sendable {
    let nonce: String
}

// MARK: - Issue Verifiable Credential

struct IssueVCRequest: Codable, Sendable {
    let holderDid: String
    let proof: String
    enum CodingKeys: String, CodingKey { case holderDid = "holder_did"; case proof }
}

struct IssueVCResponse: Codable, Sendable {
    let credential: String
}

// MARK: - Validate VP

struct ValidateVPRequest: Codable, Sendable {
    let vpJwt: String
    enum CodingKeys: String, CodingKey { case vpJwt = "vp_jwt" }
}

struct ValidateVPResponse: Codable, Sendable {
    let valid: Bool
    let holderDid: String
    let credentials: [CredentialSummary]
    enum CodingKeys: String, CodingKey { case valid; case holderDid = "holder_did"; case credentials }
}

struct CredentialSummary: Codable, Sendable {
    let credentialId: String
    let credentialType: String
    let expiresAt: String
    let revoked: Bool
    let subject: [String: String]?

    enum CodingKeys: String, CodingKey {
        case credentialId = "credential_id"
        case credentialType = "credential_type"
        case expiresAt = "expires_at"
        case revoked
        case subject
    }
}

// MARK: - Metadata

struct MetaDataResponseItem: Codable, Identifiable, Sendable {
    var id: String { credentialId } // Para Identifiable de SwiftUI

    let credentialId: String
    let credentialType: String
    let expiresAt: String
    let issuedAt: String
    let revoked: Bool

    enum CodingKeys: String, CodingKey {
        case credentialId = "credential_id"
        case credentialType = "credential_type"
        case expiresAt = "expires_at"
        case issuedAt = "issued_at"
        case revoked
    }
}

// MARK: - Verifiable Credential

struct VerifiableCredentialResponse: Codable, Sendable {
    let credentialId: String
    let holderDid: String
    let jwt: String
    enum CodingKeys: String, CodingKey {
        case credentialId = "credential_id"; case holderDid = "holder_did"; case jwt
    }
}
