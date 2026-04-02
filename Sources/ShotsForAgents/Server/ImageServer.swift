import Foundation
import FlyingFox

final class ImageServer: Sendable {
    let store: ImageStore
    let port: UInt16

    init(store: ImageStore, port: UInt16 = Constants.port) {
        self.store = store
        self.port = port
    }

    func start() async throws {
        let server = HTTPServer(port: port)
        let store = self.store

        await server.appendRoute("GET /s/:filename") { request in
            guard let filename = request.routeParameters["filename"] else {
                return HTTPResponse(statusCode: .badRequest)
            }

            let uuidString = filename.replacingOccurrences(of: ".png", with: "")
            guard let uuid = UUID(uuidString: uuidString) else {
                return HTTPResponse(statusCode: .badRequest)
            }

            guard let data = await store.fetch(uuid) else {
                // 410 Gone — image expired or was cleaned up
                return HTTPResponse(
                    statusCode: HTTPStatusCode(410, phrase: "Gone"),
                    body: "Gone".data(using: .utf8)!
                )
            }

            var headers = HTTPHeaders()
            headers[.contentType] = "image/png"
            return HTTPResponse(
                statusCode: .ok,
                headers: headers,
                body: data
            )
        }

        await server.appendRoute("GET /health") { _ in
            var headers = HTTPHeaders()
            headers[.contentType] = "text/plain"
            return HTTPResponse(
                statusCode: .ok,
                headers: headers,
                body: "ok".data(using: .utf8)!
            )
        }

        try await server.run()
    }
}
