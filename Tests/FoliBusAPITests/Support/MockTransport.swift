import Foundation
@testable import FoliBusAPI

actor MockTransport: FoliTransport {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private let handler: Handler
    private var recordedRequests: [URLRequest] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (data: Data, response: URLResponse) {
        recordedRequests.append(request)
        let (response, data) = try handler(request)
        return (data, response)
    }

    func requests() -> [URLRequest] {
        recordedRequests
    }
}

func makeDataResponse(for request: URLRequest, statusCode: Int = 200, data: Data, contentType: String = "application/json") throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
        throw URLError(.badURL)
    }

    guard let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": contentType]
    ) else {
        throw URLError(.badServerResponse)
    }

    return (response, data)
}

func makeJSONResponse(for request: URLRequest, statusCode: Int = 200, jsonObject: Any) throws -> (HTTPURLResponse, Data) {
    let data = try JSONSerialization.data(withJSONObject: jsonObject)
    return try makeDataResponse(for: request, statusCode: statusCode, data: data)
}
