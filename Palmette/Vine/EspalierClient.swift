import Foundation

/// Role: Vine. Typed transport failures. This product has no remote catalog; contact is a Settings link.
enum EspalierWireFault: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Vine. One HTTP hop. Injected so tests never leave the process.
protocol EspalierCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Vine. URLSession hop, 15 s timeout, app User-Agent on every request.
struct EspalierSession: EspalierCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": EspalierClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Vine. DTO that mirrors a JSON object exactly. Never decoded into Garden or Vine.
struct EspalierProbeDTO: Decodable, Sendable {
    var ok: Bool
}

/// Role: Vine. Owns the session. No required remote catalog — contact URL is a Settings link, not fetched into a WebView.
actor EspalierClient {
    static let userAgent = "Palmette/1.0 (iOS; +https://palmette-vine.pro)"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://palmette-vine.pro/contact-us")!

    private let carrier: any EspalierCarrying

    init(carrier: any EspalierCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = EspalierSession()
    }

    func getJSON<DTO: Decodable & Sendable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw EspalierWireFault.cancelled
        } catch {
            throw EspalierWireFault.decoding
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as EspalierWireFault {
            throw fault
        } catch is CancellationError {
            throw EspalierWireFault.cancelled
        } catch {
            if Self.cancelled(error) {
                throw EspalierWireFault.cancelled
            }
            guard Self.transient(error) else { throw EspalierWireFault.transport }
            do {
                return try await send(request)
            } catch let fault as EspalierWireFault {
                throw fault
            } catch is CancellationError {
                throw EspalierWireFault.cancelled
            } catch {
                if Self.cancelled(error) { throw EspalierWireFault.cancelled }
                throw EspalierWireFault.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw EspalierWireFault.invalidResponse
        }
        if http.statusCode == 404 {
            throw EspalierWireFault.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw EspalierWireFault.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
