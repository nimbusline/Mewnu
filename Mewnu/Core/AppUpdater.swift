import Combine
import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
protocol UpdateDriver: AnyObject {
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }
    var onChange: (() -> Void)? { get set }
    func checkForUpdates()
}

// Synthetic previews and tests never fetch or install updates.
@MainActor
final class DemoUpdateDriver: UpdateDriver {
    var canCheckForUpdates = true
    var automaticallyChecksForUpdates = false
    var automaticallyDownloadsUpdates = false
    var onChange: (() -> Void)?
    private(set) var checkCount = 0
    func checkForUpdates() { checkCount += 1 }
}

@MainActor
final class AppUpdater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecksForUpdates = false
    @Published private(set) var automaticallyInstallsUpdates = false
    private let driver: UpdateDriver

    init(driver: UpdateDriver? = nil) {
        let driver = driver ?? DemoUpdateDriver()
        self.driver = driver
        driver.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    func refresh() {
        canCheckForUpdates = driver.canCheckForUpdates
        automaticallyChecksForUpdates = driver.automaticallyChecksForUpdates
        automaticallyInstallsUpdates = driver.automaticallyDownloadsUpdates
    }

    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        driver.checkForUpdates()
        refresh()
    }

    func setAutomaticChecks(_ enabled: Bool) {
        // Turning checks off also turns off unattended downloads/installation.
        if !enabled { driver.automaticallyDownloadsUpdates = false }
        driver.automaticallyChecksForUpdates = enabled
        refresh()
    }

    func setAutomaticInstallation(_ enabled: Bool) {
        guard !enabled || automaticallyChecksForUpdates else { return }
        driver.automaticallyDownloadsUpdates = enabled
        refresh()
    }
}

#if canImport(Sparkle)
@MainActor
final class SparkleUpdateDriver: UpdateDriver {
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    private var observations: Set<AnyCancellable> = []
    var onChange: (() -> Void)?

    init() {
        let updater = controller.updater
        updater.publisher(for: \.canCheckForUpdates).sink { [weak self] _ in
            self?.onChange?()
        }.store(in: &observations)
        updater.publisher(for: \.automaticallyChecksForUpdates).sink { [weak self] _ in
            self?.onChange?()
        }.store(in: &observations)
        updater.publisher(for: \.automaticallyDownloadsUpdates).sink { [weak self] _ in
            self?.onChange?()
        }.store(in: &observations)
    }

    var canCheckForUpdates: Bool { controller.updater.canCheckForUpdates }
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
    var automaticallyDownloadsUpdates: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }
    func checkForUpdates() { controller.checkForUpdates(nil) }
}
#endif
