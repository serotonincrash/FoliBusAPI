import Testing
import FoliBusUI
// Deliberately no `import FoliBusAPI`: this file verifies that FoliBusUI
// re-exports the FoliBusAPI surface, so it must compile with the single
// import above. If the `@_exported import` in FoliBusUI is ever removed,
// this file fails to compile.

@Suite("FoliBusAPI Re-Export")
struct ReExportTests {
    @Test("FoliBusAPI types are nameable through import FoliBusUI alone")
    func apiTypesAreVisibleThroughFoliBusUI() {
        let stopType: Foli.Stop.Type = Foli.Stop.self
        #expect(stopType == Foli.Stop.self)
        #expect(FoliClient.self == FoliClient.self)
        #expect(FoliClientConfiguration.self == FoliClientConfiguration.self)
        #expect(Foli.Route.self == Foli.Route.self)
    }
}
