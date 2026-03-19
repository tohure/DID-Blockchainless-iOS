// SharedComponents.swift
// DIDBlockchainlessDemo
//
// Componentes SwiftUI reutilizables que replican los Composables compartidos de Android.

import SwiftUI

// MARK: - PrimaryButton

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title).font(.appHeadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .background(LinearGradient.primaryGradient)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(.appHeadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color.appError.opacity(0.15))
        .foregroundStyle(Color.appError)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appError.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - InfoCard

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(Color.appPrimary)
                Text(title).font(.appHeadline).foregroundStyle(Color.textPrimary)
            }
            content
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let level: SecurityLevel

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(level.rawValue)
                .font(.appCaption)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch level {
        case .secureEnclave: return .appSecondary
        case .keychain:      return .appPrimary
        case .software:      return .appWarning
        case .unknown:       return .textSecondary
        }
    }
}

// MARK: - StatusBar

struct StatusBar: View {
    let message: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView().tint(Color.appPrimary).scaleEffect(0.8)
            } else {
                Circle().fill(message.isEmpty ? Color.textSecondary : Color.appSecondary)
                    .frame(width: 6, height: 6)
            }
            Text(message.isEmpty ? "Listo" : message)
                .font(.appCaption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut, value: message)
    }
}

// MARK: - MonoText (para DID, JWT, etc.)

struct MonoText: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.appCaption).foregroundStyle(Color.textSecondary)
            Text(value.isEmpty ? "—" : value)
                .font(.appMono)
                .foregroundStyle(value.isEmpty ? Color.textSecondary : Color.textPrimary)
                .lineLimit(4)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    let step: Int

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(LinearGradient.primaryGradient)
                    .frame(width: 28, height: 28)
                Text("\(step)").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
            Text(title).font(.appTitle).foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}
