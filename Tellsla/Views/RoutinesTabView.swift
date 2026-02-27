import SwiftUI

struct RoutinesTabView: View {
    @Bindable var viewModel: RoutinesViewModel
    let appState: AppState
    @State private var showNewRoutine: Bool = false
    @State private var showTemplates: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                templatesPreview
                suggestionsSection
                activeRoutinesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showNewRoutine) {
            RoutineEditorView(onSave: { routine in
                viewModel.addRoutine(routine)
            })
        }
        .sheet(isPresented: $showTemplates) {
            RoutineTemplatesSheet(viewModel: viewModel)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Routines")
                    .font(.title2.bold())
                Text("\(viewModel.routines.filter(\.isEnabled).count) active")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                appState.showTutorial = true
                appState.tutorialSection = "routines"
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
            Button {
                showNewRoutine = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var templatesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.blue)
                Text("Templates")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    showTemplates = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.routineTemplates.prefix(4)) { template in
                        Button {
                            viewModel.installTemplate(template)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: template.icon)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Circle())
                                Text(template.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.yellow)
                                    Text(String(format: "%.1f", template.rating))
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 90)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: template.id)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if !viewModel.suggestedRoutines.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "brain")
                        .foregroundStyle(.purple)
                    Text("AI Suggestions")
                        .font(.headline)
                }

                ForEach(viewModel.suggestedRoutines) { routine in
                    SuggestionCard(
                        routine: routine,
                        onAccept: { viewModel.acceptSuggestion(routine) },
                        onDismiss: { viewModel.dismissSuggestion(routine) }
                    )
                }
            }
        }
    }

    private var activeRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Routines")
                .font(.headline)

            if viewModel.routines.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No Routines Yet")
                        .font(.headline)
                    Text("Create your first automation, install a template, or accept an AI suggestion above.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Create Routine") {
                        showNewRoutine = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            } else {
                ForEach(viewModel.routines) { routine in
                    RoutineCard(
                        routine: routine,
                        onToggle: { viewModel.toggleRoutine(routine) },
                        onTrigger: { Task { await viewModel.triggerRoutine(routine) } },
                        onDelete: { viewModel.deleteRoutine(routine) }
                    )
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let routine: Routine
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: routine.icon)
                    .font(.title3)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.subheadline.weight(.semibold))
                    if let conf = routine.confidence {
                        Text("\(Int(conf * 100))% confidence based on your patterns")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(routine.triggers, id: \.self) { trigger in
                    Label(trigger.displayName, systemImage: trigger.icon)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 6) {
                ForEach(routine.actions, id: \.self) { action in
                    Label(action.displayName, systemImage: action.icon)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Add Routine")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(Color.purple.opacity(0.05))
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        }
    }
}

struct RoutineCard: View {
    let routine: Routine
    let onToggle: () -> Void
    let onTrigger: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: routine.icon)
                    .font(.title3)
                    .foregroundStyle(routine.isEnabled ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.subheadline.weight(.semibold))
                    Text(routine.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }

            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(routine.triggers, id: \.self) { trigger in
                        Text(trigger.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(routine.actions, id: \.self) { action in
                        Text(action.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)

            if routine.isEnabled {
                HStack(spacing: 8) {
                    Button("Run Now", action: onTrigger)
                        .font(.caption.weight(.medium))
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .sensoryFeedback(.impact(weight: .medium), trigger: routine.triggerCount)

                    Spacer()

                    Text("Triggered \(routine.triggerCount)×")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .contextMenu {
            Button("Edit", systemImage: "pencil") {}
            Button("Duplicate", systemImage: "doc.on.doc") {}
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Routine) -> Void
    @State private var name: String = ""
    @State private var selectedIcon: String = "gearshape.fill"
    @State private var selectedTriggers: [RoutineTrigger] = []
    @State private var selectedActions: [RoutineAction] = []

    private let icons = ["gearshape.fill", "car.fill", "bolt.fill", "house.fill", "sunrise.fill", "moon.fill", "figure.run", "cart.fill", "building.2.fill", "water.waves"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name & Icon") {
                    TextField("Routine Name", text: $name)

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.blue : Color(.tertiarySystemFill))
                                        .clipShape(.rect(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                Section("Triggers") {
                    Text("When these conditions are met:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Add Time Trigger") {
                        selectedTriggers.append(.timeOfDay(hour: 8, minute: 0))
                    }
                    Button("Add Location Trigger") {
                        selectedTriggers.append(.location(latitude: 0, longitude: 0, radius: 200, name: "Location"))
                    }
                    Button("Add Battery Trigger") {
                        selectedTriggers.append(.batteryBelow(level: 20))
                    }

                    ForEach(selectedTriggers, id: \.self) { trigger in
                        Label(trigger.displayName, systemImage: trigger.icon)
                    }
                }

                Section("Actions") {
                    Text("Do these things:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Pre-condition Cabin") {
                        selectedActions.append(.preconditionCabin(targetTemp: 21))
                    }
                    Button("Start Charging") {
                        selectedActions.append(.startCharging)
                    }
                    Button("Send Notification") {
                        selectedActions.append(.sendNotification(message: "Routine triggered"))
                    }
                    Button("Lock Vehicle") {
                        selectedActions.append(.lockVehicle)
                    }

                    ForEach(selectedActions, id: \.self) { action in
                        Label(action.displayName, systemImage: action.icon)
                    }
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let routine = Routine(
                            id: UUID().uuidString,
                            name: name,
                            icon: selectedIcon,
                            isEnabled: true,
                            triggers: selectedTriggers,
                            actions: selectedActions,
                            vehicleId: nil,
                            lastTriggered: nil,
                            triggerCount: 0,
                            isAISuggested: false,
                            confidence: nil,
                            createdAt: Date()
                        )
                        onSave(routine)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct RoutineTemplatesSheet: View {
    let viewModel: RoutinesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        let templates = viewModel.routineTemplates.filter { $0.category == category }
                        if !templates.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(category.rawValue)
                                    .font(.headline)
                                    .padding(.top, 8)

                                ForEach(templates) { template in
                                    HStack(spacing: 14) {
                                        Image(systemName: template.icon)
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                            .frame(width: 40, height: 40)
                                            .background(Color.blue.opacity(0.12))
                                            .clipShape(.rect(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.subheadline.weight(.semibold))
                                            Text(template.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.yellow)
                                                Text(String(format: "%.1f", template.rating))
                                                    .font(.caption2)
                                                Text("·")
                                                Text("\(template.installCount) installs")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Button("Install") {
                                            viewModel.installTemplate(template)
                                        }
                                        .font(.caption.weight(.semibold))
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(.rect(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Routine Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
