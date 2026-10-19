import SwiftUI
import UniformTypeIdentifiers

struct PosterBoardView: View {
    let simulator: Simulator

    @State private var wallpapers: [PosterBoardController.WallpaperTemplate] = []
    @State private var selectedWallpaper = ""
    private enum WallpaperSource: String, CaseIterable, Identifiable {
        case builtIn = "Built-in templates"
        case saved = "Saved wallpapers"
        var id: String { rawValue }
    }

    @State private var source = WallpaperSource.builtIn

    private var matchingWallpapers: [PosterBoardController.WallpaperTemplate] { wallpapers.filter { $0.isGallery == (source == .builtIn) } }
    @State private var isBusy = false
    @State private var isImporting = false
    @State private var confirmsReset = false
    @State private var confirmsReplacement = false
    @State private var selectedImage: URL?
    @State private var showsResult = false
    @State private var resultMessage = ""

    private var supportsPosterBoard: Bool {
        simulator.deviceFamily == .iPhone || simulator.deviceFamily == .iPad
    }

    private var canOperate: Bool {
        supportsPosterBoard && !simulator.isDefault && (simulator.state == .booted || simulator.state == .shutdown)
    }

    var body: some View {
        Section {
            LabeledContent("PosterBoard:") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create a wallpaper from a HEIC, JPEG, PNG, or other image, or replace the artwork of a supported saved wallpaper.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Source:", selection: $source) {
                        ForEach(WallpaperSource.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    if !matchingWallpapers.isEmpty {
                        Picker(source == .builtIn ? "Template:" : "Wallpaper:", selection: $selectedWallpaper) {
                            ForEach(matchingWallpapers) { wallpaper in
                                Text(wallpaper.displayName).tag(wallpaper.id)
                            }
                        }
                    } else {
                        Text(source == .builtIn
                             ? "No compatible built-in templates were found on \(simulator.name)."
                             : "No compatible saved wallpapers were found on \(simulator.name). Color and photo wallpapers cannot be changed here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button("Refresh", action: refresh)
                        Button("Apply Image…") { isImporting = true }
                            .disabled(selectedWallpaper.isEmpty)
                        Button("Restore Original") {
                            isBusy = true
                            PosterBoardController.restoreImages(simulator, wallpaperID: selectedWallpaper, completion: complete)
                        }
                        .disabled(!matchingWallpapers.contains(where: { $0.id == selectedWallpaper && $0.canRestore }))
                        Button("Reset PosterBoard…", role: .destructive) { confirmsReset = true }
                        if isBusy { ProgressView().controlSize(.small) }
                    }
                    .disabled(!canOperate || isBusy)

                    Text(source == .builtIn
                         ? "These templates ship with \(simulator.name) and may be hidden in iOS’s wallpaper gallery. They are not wallpapers you added. Applying an image creates and selects a new saved wallpaper."
                         : "These compatible wallpapers are already saved on \(simulator.name). "
                         + "Applying an image changes the selected wallpaper’s artwork and keeps its clock settings. Restore Original undoes the artwork change.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("A running simulator restarts. Editing in iOS can restore Apple’s artwork; apply the image again if needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: source) { _ in selectedWallpaper = matchingWallpapers.first?.id ?? "" }
        .task(id: simulator.udid) { if canOperate { refresh() } }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.image, .heic, .heif]) { result in
            switch result {
            case .success(let url):
                selectedImage = url
                confirmsReplacement = true
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError || (error as NSError).domain != NSCocoaErrorDomain {
                    show(error.localizedDescription)
                }
            }
        }
        .alert("Apply Wallpaper Image?", isPresented: $confirmsReplacement) {
            Button("Apply Image") { replaceImages() }
            Button("Cancel", role: .cancel) { selectedImage = nil }
        } message: {
            Text("This applies the image on \(simulator.name). Built-in templates create a new saved wallpaper; saved wallpapers are modified and support Restore Original. A running simulator restarts.")
        }
        .alert("Reset PosterBoard?", isPresented: $confirmsReset) {
            Button("Reset PosterBoard", role: .destructive) {
                isBusy = true
                PosterBoardController.reset(simulator, completion: complete)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes every saved Lock Screen and StandBy layout on \(simulator.name). The simulator will restart if it is running. App data and Photos are kept. No backup is retained.")
        }
        .alert("PosterBoard", isPresented: $showsResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resultMessage)
        }
    }

    private func refresh() {
        isBusy = true
        PosterBoardController.loadWallpapers(simulator) { result in
            isBusy = false
            switch result {
            case .success(let items):
                wallpapers = items
                if !matchingWallpapers.contains(where: { $0.id == selectedWallpaper }) { selectedWallpaper = matchingWallpapers.first?.id ?? "" }
            case .failure(let error):
                wallpapers = []
                selectedWallpaper = ""
                show(error.localizedDescription)
            }
        }
    }

    private func replaceImages() {
        guard let url = selectedImage else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        isBusy = true
        PosterBoardController.replaceImages(simulator, wallpaperID: selectedWallpaper, imageURL: url) { result in
            if scoped { url.stopAccessingSecurityScopedResource() }
            selectedImage = nil
            complete(result)
        }
    }

    private func complete(_ result: Result<String, Error>) {
        isBusy = false
        switch result {
        case .success(let message):
            refresh()
            show(message)
        case .failure(let error):
            show(error.localizedDescription)
        }
    }

    private func show(_ message: String) {
        resultMessage = message
        showsResult = true
    }
}
