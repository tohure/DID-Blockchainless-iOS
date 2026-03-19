// CredentialRepository.swift
// DIDBlockchainlessDemo
//
// Orquesta las llamadas de red. Devuelve Result<T, Error>

@preconcurrency import Foundation
import os

/// Repositorio que expone operaciones de red con `Result<T, Error>`.
///
/// Cada método captura errores internamente y los retorna como `.failure`
final class CredentialRepository: Sendable {

    private let client = APIClient.shared

    // MARK: - DID

    /// `POST /dids/register` — Registra el DID del holder en el backend.
    ///
    /// - Parameters:
    ///   - did: DID del holder (`did:key:z...`)
    ///   - clientID: Identificador del cliente (ej. email)
    func registerDID(did: String, clientID: String) async -> Result<Void, Error> {
        await runCatching(tag: "registerDID") {
            try await self.client.requestVoid(.registerDID(DIDRegisterRequest(clientId: clientID, did: did)))
        }
    }

    // MARK: - Nonce

    /// `GET /credentials/nonce?holder_did=<did>` — Obtiene un nonce de un solo uso.
    func fetchNonce(holderDID: String) async -> Result<String, Error> {
        await runCatching(tag: "fetchNonce") {
            let response: NonceResponse = try await self.client.request(.getNonce(holderDID: holderDID))
            return response.nonce
        }
    }

    // MARK: - Issue VC

    /// `POST /credentials/issue` — Envía el Proof JWT y recibe la VC.
    func registerProof(did: String, proof: String) async -> Result<IssueVCResponse, Error> {
        await runCatching(tag: "registerProof") {
            try await self.client.request(.issueCredential(IssueVCRequest(holderDid: did, proof: proof)))
        }
    }

    // MARK: - Metadata

    /// `GET /credentials?holder_did=<did>` — Metadatos de las VCs del holder.
    func getMetadata(holderDID: String) async -> Result<[MetaDataResponseItem], Error> {
        await runCatching(tag: "getMetadata") {
            try await self.client.request(.getMetadata(holderDID: holderDID))
        }
    }

    // MARK: - Verify VP

    /// `POST /credentials/verify` — Valida un VP JWT.
    func validateCredentials(vpJWT: String) async -> Result<ValidateVPResponse, Error> {
        await runCatching(tag: "validateCredentials") {
            try await self.client.request(.verifyVP(ValidateVPRequest(vpJwt: vpJWT)))
        }
    }

    // MARK: - (Legacy) Get Credential by ID

    /// `GET /credentials/<id>` — Descarga una VC por su ID con token bearer.
    func fetchCredential(id: String, token: String) async -> Result<VerifiableCredentialResponse, Error> {
        await runCatching(tag: "fetchCredential") {
            try await self.client.request(.getCredential(id: id, token: token))
        }
    }
}

// MARK: - Helper runCatching

/// Captura cualquier error lanzado en `block` y lo convierte en `Result`,
/// logueando el error con la etiqueta `tag`.
private func runCatching<T: Sendable>(
    tag: String,
    _ block: @Sendable () async throws -> T
) async -> Result<T, Error> {
    do {
        let value = try await block()
        return .success(value)
    } catch {
        AppLogger.network().error("[\(tag)] Error: \(error.localizedDescription)")
        return .failure(error)
    }
}
