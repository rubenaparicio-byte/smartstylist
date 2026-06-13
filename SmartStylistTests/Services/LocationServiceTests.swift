import CoreLocation
import XCTest
@testable import SmartStylist

@MainActor
final class LocationServiceTests: XCTestCase {

    // ── Initial state ─────────────────────────────────────────────────────────

    func test_init_coordinate_isNil() {
        let svc = LocationService()
        XCTAssertNil(svc.coordinate)
    }

    func test_init_authorizationStatus_notDetermined() {
        let svc = LocationService()
        XCTAssertEqual(svc.authorizationStatus, .notDetermined)
    }

    // ── requestCoordinate — fast path ─────────────────────────────────────────

    func test_requestCoordinate_withPresetCoord_returnsImmediately() async throws {
        let svc = LocationService()
        let expected = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        svc.coordinate = expected
        let result = try await svc.requestCoordinate()
        XCTAssertEqual(result.latitude,  expected.latitude,  accuracy: 0.0001)
        XCTAssertEqual(result.longitude, expected.longitude, accuracy: 0.0001)
    }

    func test_requestCoordinate_multipleCallsWithPreset_allReturnSameCoord() async throws {
        let svc = LocationService()
        svc.coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let r1 = try await svc.requestCoordinate()
        let r2 = try await svc.requestCoordinate()
        XCTAssertEqual(r1.latitude, r2.latitude, accuracy: 0.0001)
    }

    // ── Delegate: didUpdateLocations ──────────────────────────────────────────

    func test_didUpdateLocations_setsCoordinate() async {
        let svc = LocationService()
        let location = CLLocation(latitude: 40.7128, longitude: -74.0060)
        svc.locationManager(CLLocationManager(), didUpdateLocations: [location])
        // Yield to allow the Task { @MainActor in } inside the delegate to execute
        await Task.yield()
        XCTAssertEqual(svc.coordinate?.latitude ?? 0,  40.7128, accuracy: 0.0001)
        XCTAssertEqual(svc.coordinate?.longitude ?? 0, -74.0060, accuracy: 0.0001)
    }

    func test_didUpdateLocations_emptyArray_doesNotChangeCoordinate() async {
        let svc = LocationService()
        svc.locationManager(CLLocationManager(), didUpdateLocations: [])
        await Task.yield()
        XCTAssertNil(svc.coordinate)
    }

    func test_didUpdateLocations_usesLastLocation() async {
        let svc = LocationService()
        let first  = CLLocation(latitude: 10.0, longitude: 20.0)
        let second = CLLocation(latitude: 51.5074, longitude: -0.1278)
        svc.locationManager(CLLocationManager(), didUpdateLocations: [first, second])
        await Task.yield()
        XCTAssertEqual(svc.coordinate?.latitude ?? 0, 51.5074, accuracy: 0.0001)
    }

    // ── LocationError ─────────────────────────────────────────────────────────

    func test_locationError_denied_hasDescription() {
        let error = LocationError.denied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_locationError_denied_mentionsSettings() {
        let desc = LocationError.denied.errorDescription ?? ""
        // Description should guide the user to resolve the issue
        XCTAssertTrue(desc.lowercased().contains("settings") || desc.lowercased().contains("denied"))
    }
}
