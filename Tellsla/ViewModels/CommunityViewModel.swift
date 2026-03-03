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
        defer { isLoading = false }
        
        do {
            let nearby = try await BackendService.shared.getNearbyReports(
                lat: coordinate.latitude,
                lon: coordinate.longitude,
                radius: 10
            )
            await MainActor.run {
                self.reports = nearby.sorted { $0.timestamp > $1.timestamp }
            }
        } catch {
            await CrashLogService.shared.log(.error, message: "Failed to load reports: \(error.localizedDescription)", context: "CommunityViewModel")
        }
    }

    func submitReport(type: ReportType, coordinate: CLLocationCoordinate2D, description: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await BackendService.shared.submitReport(
                lat: coordinate.latitude,
                lon: coordinate.longitude,
                type: type.rawValue,
                message: description
            )
            
            let report = CommunityReport(
                id: response.reportId,
                userId: "current_user",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                reportType: type.rawValue,
                message: description,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.reports.insert(report, at: 0)
            }
        } catch {
            await CrashLogService.shared.log(.error, message: "Failed to submit report: \(error.localizedDescription)", context: "CommunityViewModel")
        }
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
