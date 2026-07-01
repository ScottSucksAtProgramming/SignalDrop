import Network

protocol NetworkPathProviding: AnyObject {
    var currentPath: NWPath { get }
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)? { get set }
    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor: NetworkPathProviding {}
