import SwiftUI
import AppKit

struct AttachmentView: View {
    let attachment: NtfyAttachment
    var token: String? = nil
    var maxImageHeight: CGFloat = 160

    var body: some View {
        if attachment.isImage, let url = attachment.fileURL {
            imageView(url: url)
        } else {
            fileChip
        }
    }

    private func imageView(url: URL) -> some View {
        AuthAsyncImage(url: url, token: token) { phase in
            switch phase {
            case .empty:
                placeholder
                    .frame(height: 60)
                    .overlay(ProgressView().controlSize(.small))
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: maxImageHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .failure:
                fileChip
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture { Attachments.open(attachment, token: token) }
        .help(attachment.name)
    }

    private var fileChip: some View {
        Button {
            Attachments.open(attachment, token: token)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperclip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attachment.name)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let size = attachment.sizeText {
                        Text(verbatim: size)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.secondary.opacity(0.15))
            }
        }
        .buttonStyle(.plain)
        .help(attachment.name)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.secondary.opacity(0.12))
    }
}

// MARK: - Auth-aware AsyncImage replacement

enum AuthAsyncImagePhase {
    case empty
    case success(Image)
    case failure
}

struct AuthAsyncImage<Content: View>: View {
    let url: URL
    let token: String?
    @ViewBuilder let content: (AuthAsyncImagePhase) -> Content

    @State private var phase: AuthAsyncImagePhase = .empty

    var body: some View {
        content(phase)
            .task(id: cacheKey) { await load() }
    }

    private var cacheKey: String { url.absoluteString + "|" + (token ?? "") }

    private func load() async {
        phase = .empty
        var req = URLRequest(url: url)
        if let token, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                phase = .failure
                return
            }
            if Task.isCancelled { return }
            if let nsImage = NSImage(data: data) {
                phase = .success(Image(nsImage: nsImage))
            } else {
                phase = .failure
            }
        } catch {
            phase = .failure
        }
    }
}

// MARK: - Auth-aware open

enum Attachments {
    @MainActor
    static func open(_ attachment: NtfyAttachment, token: String?) {
        guard let url = attachment.fileURL else { return }

        // No token → no auth needed → let the system handler take it.
        guard let token, !token.isEmpty else {
            NSWorkspace.shared.open(url)
            return
        }

        // Otherwise download with the Bearer header, save to temp, then
        // hand the local file off to the default handler. Falls back to
        // opening the raw URL if the download fails (the system handler
        // can prompt for credentials).
        Task.detached {
            do {
                var req = URLRequest(url: url)
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                let dir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ntfyme-attachments", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let dest = dir.appendingPathComponent(attachment.name.isEmpty ? "attachment" : attachment.name)
                try data.write(to: dest, options: .atomic)
                await MainActor.run { NSWorkspace.shared.open(dest) }
            } catch {
                await MainActor.run { NSWorkspace.shared.open(url) }
            }
        }
    }
}
