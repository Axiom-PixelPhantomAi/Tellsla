import SwiftUI
import CoreLocation

struct CommunityTabView: View {
    @Bindable var viewModel: CommunityViewModel
    let locationService: LocationService
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                visibilityToggle
                reportButtonsGrid
                filterSection
                reportsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $viewModel.showReportSheet) {
            NewReportSheet(viewModel: viewModel, locationService: locationService)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Community")
                    .font(.title2.bold())
                Text("\(viewModel.filteredReports.count) active reports nearby")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                appState.showTutorial = true
                appState.tutorialSection = "community"
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var visibilityToggle: some View {
        HStack(spacing: 14) {
            Image(systemName: viewModel.isShowingOnMap ? "eye.fill" : "eye.slash.fill")
                .font(.title3)
                .foregroundStyle(viewModel.isShowingOnMap ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Show My Tesla on Map")
                    .font(.subheadline.weight(.medium))
                Text(viewModel.isShowingOnMap ? "Visible to nearby Tesla drivers" : "Hidden from community map")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { viewModel.isShowingOnMap },
                set: { _ in viewModel.toggleMapVisibility() }
            ))
            .labelsHidden()
        }
        .padding(14)
        .background(viewModel.isShowingOnMap ? Color.green.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var reportButtonsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Report")
                    .font(.headline)
                Spacer()
                Button("All Reports") {
                    viewModel.showReportSheet = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickReportButton(type: .pothole, action: { quickReport(.pothole) })
                QuickReportButton(type: .roadHazard, action: { quickReport(.roadHazard) })
                QuickReportButton(type: .police, action: { quickReport(.police) })
                QuickReportButton(type: .construction, action: { quickReport(.construction) })
                QuickReportButton(type: .accident, action: { quickReport(.accident) })
                QuickReportButton(type: .brokenCharger, action: { quickReport(.brokenCharger) })
                QuickReportButton(type: .iceSnow, action: { quickReport(.iceSnow) })
                QuickReportButton(type: .debris, action: { quickReport(.debris) })
            }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filters")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Button {
                            viewModel.toggleFilter(type)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.caption2)
                                Text(type.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewModel.filterTypes.contains(type) ? Color.blue : Color(.tertiarySystemFill))
                            .foregroundStyle(viewModel.filterTypes.contains(type) ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Reports")
                .font(.headline)

            if viewModel.filteredReports.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Reports Nearby")
                        .font(.headline)
                    Text("Be the first to report road conditions in your area. Your reports help other Tesla drivers stay safe.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            } else {
                ForEach(viewModel.filteredReports) { report in
                    ReportRow(report: report, onUpvote: { viewModel.upvoteReport(report) }, onDownvote: { viewModel.downvoteReport(report) })
                }
            }
        }
    }

    private func quickReport(_ type: ReportType) {
        guard let coord = locationService.location?.coordinate else { return }
        viewModel.submitReport(type: type, coordinate: coord, description: type.rawValue)
    }
}

struct QuickReportButton: View {
    let type: ReportType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.body)
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                Text(type.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: UUID())
    }
}

struct ReportRow: View {
    let report: CommunityReport
    let onUpvote: () -> Void
    let onDownvote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: report.type.icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(report.type.rawValue)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(report.reporterDisplayName)
                    if let model = report.vehicleModel {
                        Text("·")
                        Text(model.rawValue)
                    }
                    Text("·")
                    Text(report.createdAt.formatted(.relative(presentation: .named)))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: onUpvote) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                }
                Text("\(report.upvotes)")
                    .font(.caption.weight(.medium))
                Button(action: onDownvote) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}

struct NewReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CommunityViewModel
    let locationService: LocationService
    @State private var selectedType: ReportType = .pothole
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Report Type") {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                Text(type.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Description (Optional)") {
                    TextField("Add details...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        guard let coord = locationService.location?.coordinate else { return }
                        viewModel.submitReport(
                            type: selectedType,
                            coordinate: coord,
                            description: description.isEmpty ? selectedType.rawValue : description
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
