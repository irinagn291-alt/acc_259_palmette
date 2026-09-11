import XCTest
@testable import Palmette

private actor ScriptedCarrier: EspalierCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class EspalierClientTests: XCTestCase {
    private let url = URL(string: "https://palmette-vine.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = EspalierClient(carrier: carrier)
        let dto = try await client.getJSON(EspalierProbeDTO.self, from: url)
        XCTAssertTrue(dto.ok)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), EspalierClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(EspalierClient.userAgent, "Palmette/1.0 (iOS; +https://palmette-vine.pro)")
        XCTAssertEqual(EspalierClient.contactURL.absoluteString, "https://palmette-vine.pro/contact-us")
        XCTAssertFalse(EspalierClient.userAgent.contains("OpenFoodFacts"))
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = EspalierClient(carrier: carrier)
        let dto = try await client.getJSON(EspalierProbeDTO.self, from: url)
        XCTAssertTrue(dto.ok)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), try http(404))),
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = EspalierClient(carrier: carrier)
        do {
            _ = try await client.getJSON(EspalierProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? EspalierWireFault, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_secondTransientFailureIsTransport() async {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.cannotConnectToHost)),
            .failure(URLError(.timedOut)),
        ])
        let client = EspalierClient(carrier: carrier)
        do {
            _ = try await client.getJSON(EspalierProbeDTO.self, from: url)
            XCTFail("expected transport")
        } catch {
            XCTAssertEqual(error as? EspalierWireFault, .transport)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_cancellationIsNotRetried() async {
        let carrier = ScriptedCarrier(results: [
            .failure(CancellationError()),
            .success((Data("{\"ok\":true}".utf8), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)),
        ])
        let client = EspalierClient(carrier: carrier)
        do {
            _ = try await client.getJSON(EspalierProbeDTO.self, from: url)
            XCTFail("expected cancelled")
        } catch {
            XCTAssertEqual(error as? EspalierWireFault, .cancelled)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), try http(200))),
        ])
        let client = EspalierClient(carrier: carrier)
        do {
            _ = try await client.getJSON(EspalierProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? EspalierWireFault, .decoding)
        }
    }

    private func http(_ status: Int) throws -> HTTPURLResponse {
        try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }
}
