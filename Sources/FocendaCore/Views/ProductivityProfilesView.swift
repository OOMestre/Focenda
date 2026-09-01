import SwiftUI

#if canImport(AppKit)
import AppKit
import Combine
#endif

/// Workspace for creating, editing, and activating productivity profiles.
public struct ProductivityProfilesView: View {
    @Bindable var viewModel: ProductivityProfileViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var profileToDelete: ProductivityProfile?
    @State private var isDeleteAlertPresented = false

    public init(viewModel: ProductivityProfileViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if let error = viewModel.persistenceErrorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.orange.opacity(0.10))

                    Divider()
                }

                HStack(spacing: 0) {
                    profileList
                        .frame(width: min(300, max(220, proxy.size.width * 0.30)))

                    Divider()

                    profileEditor
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Productivity Profiles")
        .onAppear {
            viewModel.refreshAccessibilityStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            viewModel.refreshAccessibilityStatus()
        }
        .alert("Delete profile?", isPresented: $isDeleteAlertPresented) {
            Button("Delete", role: .destructive) {
                if let profileToDelete {
                    viewModel.deleteProfile(id: profileToDelete.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(profileToDelete?.displayName ?? "This profile") and its saved app layouts will be removed from this Mac.")
        }
    }

    private var profileList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your profiles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("One click to set up a work context")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button {
                    _ = viewModel.addProfile()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textOnAccent)
                        .frame(width: 26, height: 26)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Create a productivity profile")
            }
            .padding(16)

            Divider()

            if viewModel.profiles.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accent)
                    Text("No profiles yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Create one to save a complete workspace.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.profiles) { profile in
                            profileListRow(profile)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(AppTheme.sidebarBackground)
    }

    private func profileListRow(_ profile: ProductivityProfile) -> some View {
        let isSelected = viewModel.selectedProfileID == profile.id
        let isActive = viewModel.activeProfileID == profile.id

        return Button {
            viewModel.selectProfile(id: profile.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "rectangle.3.group")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isActive ? AppTheme.success : (isSelected ? AppTheme.accent : AppTheme.textTertiary))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(profile.displayName)
                            .font(.subheadline.weight(isSelected ? .semibold : .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)

                        if isActive {
                            Text("ACTIVE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(AppTheme.success)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppTheme.success.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(profile.applications.count) app\(profile.applications.count == 1 ? "" : "s") • \(profile.globalShortcut?.displayString ?? "No shortcut")")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if viewModel.isActivatingProfileID == profile.id {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.accent.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Activate \(profile.displayName)") {
                viewModel.activateProfile(id: profile.id)
            }
            Divider()
            Button("Delete Profile", role: .destructive) {
                profileToDelete = profile
                isDeleteAlertPresented = true
            }
        }
    }

    @ViewBuilder
    private var profileEditor: some View {
        if let selectedProfileID = viewModel.selectedProfileID,
           viewModel.profiles.contains(where: { $0.id == selectedProfileID }) {
            ProductivityProfileEditor(
                profile: Binding(
                    get: {
                        viewModel.profiles.first(where: { $0.id == selectedProfileID })
                            ?? ProductivityProfile(id: selectedProfileID)
                    },
                    set: { viewModel.updateProfile($0) }
                ),
                viewModel: viewModel
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 38))
                    .foregroundStyle(AppTheme.accent)
                Text("Select a profile")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Choose a profile on the left or create a new one to get started.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }
}

private struct ProductivityProfileEditor: View {
    @Binding var profile: ProductivityProfile
    let viewModel: ProductivityProfileViewModel

    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !viewModel.isAccessibilityTrusted {
                    accessibilityPermissionCard
                }

                desktopSpaceInformationCard
                applicationsSection
                shortcutSection

                if let result = viewModel.lastActivationResult,
                   result.profileName == profile.displayName {
                    Text(result.summary)
                        .font(.caption)
                        .foregroundStyle(result.succeeded ? AppTheme.success : .orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let error = viewModel.lastErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 860, alignment: .leading)
            .padding(20)
        }
        .background(AppTheme.background)
        .confirmationDialog(
            "Delete \(profile.displayName)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Profile", role: .destructive) {
                viewModel.deleteProfile(id: profile.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Profile name", text: $profile.name)
                    .font(.title2.weight(.bold))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Open the apps you need and restore their window layout in one action.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    viewModel.activateProfile(id: profile.id)
                } label: {
                    Label(
                        viewModel.isActivatingProfileID == profile.id ? "Activating..." : "Activate",
                        systemImage: "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.small)
                .disabled(viewModel.isActivatingProfileID != nil)

                Menu {
                    Button("Delete Profile", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private var accessibilityPermissionCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Window organization needs Accessibility access")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("macOS requires your approval before Focenda can move and resize windows in other apps. If it was already enabled before an app update, turn the toggle off and on once so macOS can re-associate this version.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open Accessibility Settings") {
                    viewModel.requestAccessibilityAccess()
                    #if os(macOS)
                    AccessibilityWindowManager.openAccessibilitySettings()
                    #endif
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var desktopSpaceInformationCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Profiles arrange windows on the current desktop")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("macOS does not provide a supported way for Focenda to create a new desktop or move other apps between Spaces. Choose the desktop you want in Mission Control first, then use this profile's shortcut to open and arrange its windows there.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.20), lineWidth: 1)
        )
    }

    private var applicationsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Applications & window layouts")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Add an app, then choose its monitor, position, and size. Capture converts the current window to the nearest simple position.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        chooseApplication()
                    } label: {
                        Label("Add Application", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if profile.applications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("No applications in this profile")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Add the apps that make up this work context.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach($profile.applications) { $application in
                        ProductivityApplicationLayoutEditor(
                            application: $application,
                            profileID: profile.id,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Window layout", systemImage: "macwindow.on.rectangle")
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var shortcutSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Global activation shortcut")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Use this shortcut anywhere in macOS to open and arrange this profile. Global shortcuts must be enabled in Settings.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    #if canImport(AppKit)
                    ProfileShortcutRecorder(shortcut: $profile.globalShortcut)
                    #else
                    Text(profile.globalShortcut?.displayString ?? "Unavailable")
                    #endif
                }

                if viewModel.hasBuiltInShortcutConflict(for: profile.id) {
                    Label("This shortcut is already used by a focus timer shortcut.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if viewModel.hasShortcutConflict(for: profile.id) {
                    Label("Another profile already uses this shortcut.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(4)
        } label: {
            Label("Shortcut", systemImage: "keyboard")
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func chooseApplication() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = "Choose Applications for \(profile.displayName)"
        panel.message = "Select one or more .app bundles to open when this profile is activated."
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard let bundle = Bundle(url: url),
                  let bundleIdentifier = bundle.bundleIdentifier else {
                continue
            }

            let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent

            viewModel.addApplication(
                to: profile.id,
                bundleIdentifier: bundleIdentifier,
                name: displayName,
                applicationPath: url.path,
                applicationBookmarkData: try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            )
        }
        #endif
    }
}

private struct ProductivityApplicationLayoutEditor: View {
    @Binding var application: ProductivityProfileApplication
    let profileID: UUID
    let viewModel: ProductivityProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                applicationIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(application.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Text(application.bundleIdentifier)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                Button {
                    viewModel.captureWindowLayout(applicationID: application.id, in: profileID)
                } label: {
                    Label("Capture Current Window", systemImage: "scope")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Save this app's monitor, size, and nearest simple position")

                Button(role: .destructive) {
                    viewModel.removeApplication(applicationID: application.id, from: profileID)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Remove application from profile")
            }

            HStack(spacing: 10) {
                Label("Monitor", systemImage: "display")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Picker("Monitor", selection: screenSelection) {
                    if viewModel.availableScreens.isEmpty {
                        Text("Current display").tag(UInt32(0))
                    } else {
                        ForEach(viewModel.availableScreens) { screen in
                            Text(screen.name).tag(screen.id)
                        }
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 230)

                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Position", systemImage: "square.grid.3x3")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(application.windowLayout.position?.label ?? "Custom saved position")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)

                    Text("Choose where the window sits on this monitor.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ProductivityWindowPositionPicker(selection: positionSelection)

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Label("Window size", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)

                layoutNumberField("Width", value: $application.windowLayout.width)
                layoutNumberField("Height", value: $application.windowLayout.height)
                Spacer(minLength: 0)
            }

            Text("Saved target: \(application.windowLayout.monitorDescription)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AppTheme.cardBackgroundSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    private var screenSelection: Binding<UInt32> {
        Binding(
            get: { application.windowLayout.screenID ?? viewModel.availableScreens.first?.id ?? 0 },
            set: { newValue in
                guard let screen = viewModel.availableScreens.first(where: { $0.id == newValue }) else {
                    application.windowLayout.screenID = newValue == 0 ? nil : newValue
                    return
                }
                application.windowLayout.screenID = screen.id
                application.windowLayout.screenName = screen.name
            }
        )
    }

    private var positionSelection: Binding<ProductivityWindowPosition?> {
        Binding(
            get: { application.windowLayout.position },
            set: { application.windowLayout.position = $0 }
        )
    }

    private func layoutNumberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textTertiary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: title == "Width" || title == "Height" ? 76 : 60)
        }
    }

    @ViewBuilder
    private var applicationIcon: some View {
        #if canImport(AppKit)
        Image(nsImage: NSWorkspace.shared.icon(forFile: application.applicationPath))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
        #else
        Image(systemName: "app.fill")
            .frame(width: 30, height: 30)
        #endif
    }
}

private struct ProductivityWindowPositionPicker: View {
    @Binding var selection: ProductivityWindowPosition?

    private let columns = Array(
        repeating: GridItem(.fixed(30), spacing: 4),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(ProductivityWindowPosition.allCases) { position in
                let isSelected = selection == position

                Button {
                    selection = position
                } label: {
                    Image(systemName: position.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.textOnAccent : AppTheme.textSecondary)
                        .frame(width: 30, height: 26)
                        .background(isSelected ? AppTheme.accent : AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSelected ? AppTheme.accent : AppTheme.subtleBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(position.label)
                .accessibilityLabel(Text(position.label))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .fixedSize()
    }
}

#if canImport(AppKit)
private struct ProfileShortcutRecorder: View {
    @Binding var shortcut: ProductivityProfileShortcut?
    @StateObject private var recorder = ProfileShortcutRecorderController()
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if isRecording {
                    recorder.stop()
                    isRecording = false
                } else {
                    recorder.start()
                    isRecording = true
                }
            } label: {
                if isRecording {
                    Label("Press keys...", systemImage: "record.circle")
                } else if let shortcut {
                    Text(shortcut.displayString)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                } else {
                    Label("Record Shortcut", systemImage: "keyboard")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if shortcut != nil {
                Button {
                    shortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Clear profile shortcut")
            }
        }
        .onChange(of: recorder.lastCapturedShortcut) { _, capturedShortcut in
            guard let capturedShortcut else { return }
            shortcut = capturedShortcut
            recorder.lastCapturedShortcut = nil
            isRecording = false
        }
        .onDisappear {
            recorder.stop()
        }
    }
}

private final class ProfileShortcutRecorderController: NSObject, ObservableObject {
    @Published var lastCapturedShortcut: ProductivityProfileShortcut?

    private var eventMonitor: Any?
    private var isCapturing = false

    func start() {
        stop()
        isCapturing = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isCapturing else { return event }

            // Escape cancels recording without changing the saved shortcut.
            if event.keyCode == 53 {
                self.stop()
                return nil
            }

            guard let capturedShortcut = ProductivityProfileShortcut(event: event) else {
                return nil
            }

            self.lastCapturedShortcut = capturedShortcut
            self.stop()
            return nil
        }
    }

    func stop() {
        isCapturing = false
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    deinit {
        stop()
    }
}
#endif
