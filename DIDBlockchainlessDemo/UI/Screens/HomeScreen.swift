// HomeScreen.swift
// DIDBlockchainlessDemo
//
// Pantalla principal

import SwiftUI

struct HomeScreen: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            LinearGradient.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .symbolEffect(.pulse, options: .repeating)
                        .padding(.top, 40)

                    Text("DID Identity Wallet")
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text("Identidad descentralizada segura\nsin blockchain · iOS \(UIDevice.current.systemVersion)")
                        .font(.appBody)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 48)

                // Cards de destino
                VStack(spacing: 16) {
                    NavigationCard(
                        title: "Identidad DID",
                        subtitle: "Genera y gestiona tu clave secp256k1,\nyobtén Verifiable Credentials",
                        icon: "person.badge.key.fill",
                        gradient: LinearGradient(
                            colors: [Color.appPrimary, Color(red: 0.45, green: 0.25, blue: 0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    ) {
                        path.append(AppRoute.did)
                    }

                    NavigationCard(
                        title: "Cifrado AES-256",
                        subtitle: "Cifra y descifra datos con AES-256-GCM\nprotegido por biometría",
                        icon: "lock.rectangle.stack.fill",
                        gradient: LinearGradient(
                            colors: [Color(red: 0.15, green: 0.85, blue: 0.65), Color(red: 0.1, green: 0.55, blue: 0.45)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    ) {
                        path.append(AppRoute.cryptoManager)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Footer
                Text("Claves protegidas por Secure Enclave · biometría sin PIN")
                    .font(.appCaption)
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
                    .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - NavigationCard

private struct NavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.appHeadline)
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSecondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(16)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
        .animation(.spring(duration: 0.2), value: isPressed)
    }
}

// MARK: - Press gesture helper

private struct PressActions: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}
