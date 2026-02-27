import Foundation
import Network

@Observable
@MainActor
class NetworkMonitor {
    static let shared = NetworkMonitor()
    var isConnected: Bool = true
    var connectionType: NWInterface.InterfaceType?
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                }
            }
        }
        monitor.start(queue: queue)
    }
}
