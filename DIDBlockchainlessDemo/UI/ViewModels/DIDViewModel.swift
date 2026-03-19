// DIDViewModel.swift
// DIDBlockchainlessDemo
//
// ViewModel para la pantalla DID — lógica completa de identidad descentralizada.
// Equivalente a DidViewModel.kt de Android.

import Foundation
import Observation

/// ViewModel que orquesta el flujo DID completo:
/// 1. Generar / eliminar claves secp256k1
/// 2. Registrar DID en el backend
/// 3. Obtener nonce → construir Proof JWT
/// 4. Solicitar Verifiable Credential
/// 5. Cifrar y guardar la VC
/// 6. Construir y verificar VP JWT
@Observable
@MainActor
final class DIDViewModel: BiometricAwareViewModel<DIDUIState> {

    // MARK: - Dependencias

    @ObservationIgnored private let keyManager = DIDKeyManager()
    @ObservationIgnored private let proofBuilder: ProofJWTBuilder
    @ObservationIgnored private let vpBuilder: VPJWTBuilder
    @ObservationIgnored private let cryptoManager = CryptoManager()
    @ObservationIgnored private let store = CredentialStore()
    @ObservationIgnored private let repository = CredentialRepository()

    private static let credentialID = "demo_vc"

    // MARK: - Init

    init() {
        // Compartir la misma instancia del actor DIDKeyManager entre builders
        let sharedKeyManager = DIDKeyManager()
        proofBuilder = ProofJWTBuilder(keyManager: sharedKeyManager)
        vpBuilder = VPJWTBuilder(keyManager: sharedKeyManager)
        super.init(initialState: DIDUIState())
        Task { await refreshKeyStatus() }
    }

    // MARK: - Acciones

    /// Genera el par de claves secp256k1 si no existe aún.
    func generateDIDKeys() {
        launch { [self] in
            let generated = try await keyManager.generateKeysIfNeeded()
            let level = keyManager.getSecurityLevel()
            let did = try await keyManager.getDID()
            let keyID = try await keyManager.getKeyID()

            let msg = generated
                ? "Identidad DID creada (secp256k1) en: \(level.rawValue)"
                : "Las claves DID ya existían"

            await MainActor.run {
                state.didKeysExist = true
                state.did = did
                state.keyID = keyID
                state.didSecurityLevel = level
                state.statusMessage = msg
            }
        }
    }

    /// Elimina las claves DID del Keychain.
    func deleteDIDKeys() {
        launch { [self] in
            try await keyManager.deleteKeys()
            await MainActor.run {
                state.didKeysExist = false
                state.did = ""
                state.keyID = ""
                state.didSecurityLevel = .unknown
                state.lastProofJWT = ""
                state.statusMessage = "Claves DID eliminadas"
            }
        }
    }

    func clearProofJWT() {
        state.lastProofJWT = ""
        state.statusMessage = "Proof JWT limpiado"
    }

    func clearDecryptedMetadata() {
        state.decryptedMetadata = ""
        state.statusMessage = "Metadatos limpiados"
    }

    /// Flujo completo de solicitud de credential:
    /// Registrar DID → Nonce → Proof JWT → Issue VC → Cifrar → Guardar
    func requestCredentialWithNonce(
        credentialType: String = "UniversityDegreeCredential",
        subjectClaims: [String: String] = [
            "givenName": "Jonh", "familyName": "Doe", "email": "jonhdoe@example.com"
        ]
    ) {
        launch { [self] in
            guard await keyManager.keysExist() else {
                throw DIDViewModelError.keysNotFound("Primero genera las claves DID")
            }

            let did = try await keyManager.getDID()
            let clientID = subjectClaims["email"] ?? ""

            await update(status: "Registrando DID...")
            let result1 = await repository.registerDID(did: did, clientID: clientID)
            if case .failure(let e) = result1 { throw e }

            await update(status: "Solicitando nonce...")
            let nonceResult = await repository.fetchNonce(holderDID: did)
            guard case .success(let nonce) = nonceResult else {
                if case .failure(let e) = nonceResult { throw e }
                return
            }

            await update(status: "Construyendo Proof JWT...")
            let proofJWT = try await proofBuilder.build(
                issuerURL: AppConfig.getBaseURL().absoluteString,
                nonce: nonce,
                credentialType: credentialType,
                subjectClaims: subjectClaims
            )
            await MainActor.run { state.lastProofJWT = proofJWT }

            await update(status: "Enviando Proof JWT...")
            let issueResult = await repository.registerProof(did: did, proof: proofJWT)
            guard case .success(let vcResponse) = issueResult else {
                if case .failure(let e) = issueResult { throw e }
                return
            }

            await update(status: "Obteniendo metadatos...")
            let metaResult = await repository.getMetadata(holderDID: did)
            guard case .success(let metadata) = metaResult else {
                if case .failure(let e) = metaResult { throw e }
                return
            }
            let metaJSON = (try? JSONEncoder().encode(metadata)).flatMap {
                String(data: $0, encoding: .utf8)
            } ?? "[]"

            await update(status: "Cifrando y guardando credencial...")
            let generated = try await cryptoManager.generateKeyIfNeeded()
            let encrypted = try await cryptoManager.encrypt(vcResponse.credential)
            try await store.save(id: Self.credentialID, encryptedPayload: encrypted)

            await MainActor.run {
                state.lastProofJWT = proofJWT
                state.decryptedMetadata = metaJSON
                state.encryptedCredential = encrypted
                state.statusMessage = "Credencial recibida y cifrada correctamente ✓"
            }
        }
    }

    /// Verifica una VP JWT construida a partir de la VC almacenada.
    func verifyVP() {
        launch { [self] in
            guard let encPayload = try await store.load(id: Self.credentialID) else {
                throw DIDViewModelError.keysNotFound("No hay credencial guardada")
            }

            await update(status: "Descifrando credencial...")
            let credentialJWT = try await cryptoManager.decrypt(encPayload)

            await update(status: "Construyendo VP JWT...")
            let vpJWT = try await vpBuilder.build(
                verifiableCredentialJWT: credentialJWT,
                audience: AppConfig.getBaseURL().absoluteString
            )

            await update(status: "Verificando VP en backend...")
            let result = await repository.validateCredentials(vpJWT: vpJWT)
            switch result {
            case .success(let response):
                let json = (try? JSONEncoder().encode(response)).flatMap {
                    String(data: $0, encoding: .utf8)
                } ?? "{}"
                let status = response.valid ? "VP Válida ✓" : "VP Inválida ✗"
                await MainActor.run {
                    state.validationResponseJSON = json
                    state.statusMessage = "\(status) — Holder: \(response.holderDid)"
                }
            case .failure(let e):
                throw e
            }
        }
    }

    // MARK: - Privado

    private func refreshKeyStatus() async {
        let exists = await keyManager.keysExist()
        let did = exists ? (try? await keyManager.getDID()) ?? "" : ""
        let keyID = exists ? (try? await keyManager.getKeyID()) ?? "" : ""
        let level = exists ? keyManager.getSecurityLevel() : SecurityLevel.unknown
        state.didKeysExist = exists
        state.did = did
        state.keyID = keyID
        state.didSecurityLevel = level
    }

    private func update(status: String) async {
        await MainActor.run { state.statusMessage = status }
    }
}

// MARK: - DIDViewModelError

enum DIDViewModelError: Error, LocalizedError {
    case keysNotFound(String)
    var errorDescription: String? {
        switch self { case .keysNotFound(let m): return m }
    }
}
