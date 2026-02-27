import SwiftUI
import CoreLocation

@Observable
@MainActor
class CommunityViewModel {
    var reports: [CommunityReport] = []
    var nearbyDrivers: [NearbyDriver] = []
    var isShowingOnMap: Bool = false
    var selectedReportType: ReportType?
    var showReportSheet: Bool = false
    var filterTypes: Set<ReportType> = Set(ReportType.allCases)
    var isLoading: Bool = false

    var filteredReports: [CommunityReport] {
        reports.filter { filterTypes.contains($0.type) && !$0.isExpired }
    }

    func loadReports(near coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        isLoading = false
    }

    func submitReport(type: ReportType, coordinate: CLLocationCoordinate2D, description: String) {
        let report = CommunityReport(
            id: UUID().uuidString,
            type: type,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            heading: nil,
            description: description,
            reporterDisplayName: "You",
            vehicleModel: .model3,
            upvotes: 1,
            downvotes: 0,
            isVerified: false,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(type.defaultExpiry),
            imageURL: nil
        )
        reports.insert(report, at: 0)
    }

    func upvoteReport(_ report: CommunityReport) {
        guard let index = reports.firstIndex(where: { $0.id == report.id }) else { return }
        reports[index].upvotes += 1
    }

    func downvoteReport(_ report: CommunityReport) {
        guard let index = reports.firstIndex(where: { $0.id == report.id }) else { return }
        reports[index].downvotes += 1
    }

    func toggleMapVisibility() {
        isShowingOnMap.toggle()
        UserDefaults.standard.set(isShowingOnMap, forKey: "showOnCommunityMap")
    }

    func toggleFilter(_ type: ReportType) {
        if filterTypes.contains(type) {
            filterTypes.remove(type)
        } else {
            filterTypes.insert(type)
        }
    }
}

nonisolated struct NearbyDriver: Identifiable, Sendable {
    let id: String
    let displayName: String
    let vehicleModel: TeslaModel
    let latitude: Double
    let longitude: Double
    let heading: Double
    let speed: Int
}
