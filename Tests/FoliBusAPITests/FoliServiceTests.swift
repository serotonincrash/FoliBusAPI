import Foundation
import Testing
@testable import FoliBusAPI
@testable import FoliBusUI

@Suite("FoliService Tests")
struct FoliServiceTests {
    private static let routesPayload = #"""
    [
      {
        "route_id": "25",
        "agency_id": "2",
        "route_short_name": "L14",
        "route_long_name": "Loukinainen-Avanti",
        "route_desc": "",
        "route_type": 3,
        "route_url": "",
        "route_color": "000000",
        "route_text_color": "ffffff"
      }
    ]
    """#

    private static let arrivalsPayload = #"""
    {
      "sys": "SM",
      "status": "OK",
      "servertime": 1432453114,
      "result": [
        {
          "recordedattime": 1432453110,
          "lineref": "15",
          "monitored": true,
          "latitude": 60.454883,
          "longitude": 22.2696,
          "originaimeddeparturetime": 1432451700,
          "destinationaimedarrivaltime": 1432455180,
          "destinationdisplay": "Kakskerta",
          "aimedarrivaltime": 1432453320,
          "expectedarrivaltime": 1432453229,
          "aimeddeparturetime": 1432453500,
          "expecteddeparturetime": 1432453409,
          "delay": -91
        }
      ]
    }
    """#

    private func makeService() -> (service: FoliService, transport: MockTransport) {
        let transport = MockTransport { request in
            let path = request.url?.path() ?? ""
            let payload = path.contains("/sm") ? Self.arrivalsPayload : Self.routesPayload
            return try makeDataResponse(for: request, data: Data(payload.utf8))
        }
        let client = FoliClient(transport: transport, cacheBehavior: .noCache)
        return (FoliService(client: client), transport)
    }

    @Test("FoliService with an explicit client delegates fetches to it")
    func explicitClientDelegation() async throws {
        let (service, transport) = makeService()

        let routes = try await service.fetchRoutes()
        #expect(routes.count == 1)
        #expect(routes[0].id == "25")

        let arrivals = try await service.fetchArrivals(for: "1000")
        #expect(arrivals.count == 1)
        #expect(arrivals[0].lineRef == "15")
        #expect(arrivals[0].destinationDisplay == "Kakskerta")

        let urls = await transport.requests().compactMap { $0.url?.absoluteString }
        #expect(urls.contains("https://data.foli.fi/gtfs/routes"))
        #expect(urls.contains("https://data.foli.fi/siri/sm/1000"))
    }

    @Test("wrappedValue is the service itself")
    func wrappedValueIsSelf() {
        let (service, _) = makeService()
        // The wrapper vends itself, so views call fetch methods directly on the wrapped value.
        let wrapped = service.wrappedValue
        #expect(wrapped.explicitClient != nil)
    }

    @Test("DefaultFoliClientProvider vends a stable shared client")
    func defaultProviderVendsStableClient() {
        let provider = DefaultFoliClientProvider()
        #expect(provider.client() === provider.client())

        let configured = DefaultFoliClientProvider(
            configuration: FoliClientConfiguration(cacheBehavior: .noCache)
        )
        #expect(configured.client() === configured.client())
        #expect(provider.client() !== configured.client())
    }
}
