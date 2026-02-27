import Foundation

nonisolated struct TutorialPage: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let features: [TutorialFeature]
    let accentColorName: String
}

nonisolated struct TutorialFeature: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

nonisolated struct TutorialData: Sendable {
    static let onboardingPages: [TutorialPage] = [
        TutorialPage(
            id: "welcome",
            title: "Welcome to\nRoutines Connect",
            subtitle: "Your Tesla, Supercharged",
            description: "Transform your Tesla from a reactive machine into a proactive assistant that anticipates your needs.",
            icon: "bolt.car.fill",
            features: [
                TutorialFeature(id: "w1", title: "Intelligent Navigation", description: "Energy-aware routing with real-time Supercharger data", icon: "map.fill"),
                TutorialFeature(id: "w2", title: "Smart Routines", description: "Automated actions that learn your patterns", icon: "gearshape.2.fill"),
                TutorialFeature(id: "w3", title: "Community Reports", description: "Crowd-sourced road intelligence from Tesla drivers", icon: "person.3.fill"),
            ],
            accentColorName: "blue"
        ),
        TutorialPage(
            id: "navigate",
            title: "Intelligent\nNavigation",
            subtitle: "Energy-Aware Routing",
            description: "Navigate smarter with routes optimized for your Tesla's battery, real-time Supercharger availability, and electricity pricing.",
            icon: "map.fill",
            features: [
                TutorialFeature(id: "n1", title: "Battery Impact Per Turn", description: "See how each route segment affects your charge level in real time", icon: "battery.50percent"),
                TutorialFeature(id: "n2", title: "Smart Charger Selection", description: "Routes through chargers based on price, speed, wait time, and amenities", icon: "bolt.fill"),
                TutorialFeature(id: "n3", title: "Predictive Preconditioning", description: "Battery automatically warms before you reach a Supercharger", icon: "thermometer.medium"),
                TutorialFeature(id: "n4", title: "Alternative Route Analysis", description: "Compare routes by energy cost, time, and road quality", icon: "arrow.triangle.branch"),
            ],
            accentColorName: "green"
        ),
        TutorialPage(
            id: "routines",
            title: "Smart\nRoutines",
            subtitle: "Your Car Learns You",
            description: "Create powerful automations triggered by time, location, battery level, temperature, and driving patterns. AI suggests new routines based on your habits.",
            icon: "gearshape.2.fill",
            features: [
                TutorialFeature(id: "r1", title: "Pattern Recognition", description: "AI detects your weekly patterns — Tuesday soccer practice, Friday lake trips", icon: "brain"),
                TutorialFeature(id: "r2", title: "Multi-Trigger Chains", description: "Combine time + location + battery level for precise automation", icon: "link"),
                TutorialFeature(id: "r3", title: "Smart Actions", description: "Pre-condition, navigate, charge, notify contacts — all automatic", icon: "bolt.fill"),
                TutorialFeature(id: "r4", title: "Fleet Coordination", description: "Routines that span multiple vehicles in your household", icon: "car.2.fill"),
            ],
            accentColorName: "purple"
        ),
        TutorialPage(
            id: "energy",
            title: "Energy\nIntelligence",
            subtitle: "Optimize Every Kilowatt",
            description: "Maximize savings with solar-aware charging, time-of-use optimization, and fleet-wide energy coordination.",
            icon: "bolt.fill",
            features: [
                TutorialFeature(id: "e1", title: "Solar Integration", description: "Charge when your panels produce excess — skip the grid entirely", icon: "sun.max.fill"),
                TutorialFeature(id: "e2", title: "Price-Aware Charging", description: "Automatically delay charging to off-peak rates, saving up to 60%", icon: "dollarsign.circle"),
                TutorialFeature(id: "e3", title: "Fleet Load Balancing", description: "Stagger charging across vehicles to stay under panel capacity", icon: "gauge.with.dots.needle.67percent"),
                TutorialFeature(id: "e4", title: "Trip Energy Forecast", description: "Know exactly how much a trip will cost before you leave", icon: "chart.line.uptrend.xyaxis"),
            ],
            accentColorName: "orange"
        ),
        TutorialPage(
            id: "community",
            title: "Community\nDriving",
            subtitle: "Tesla Drivers United",
            description: "Join a network of Tesla owners sharing real-time road intelligence, charger reviews, and caravan coordination.",
            icon: "person.3.fill",
            features: [
                TutorialFeature(id: "c1", title: "Live Road Reports", description: "Report and see potholes, hazards, police, construction in real time", icon: "exclamationmark.triangle.fill"),
                TutorialFeature(id: "c2", title: "Show Your Tesla", description: "Optionally display your Tesla on the live map while driving", icon: "car.fill"),
                TutorialFeature(id: "c3", title: "Caravan Mode", description: "Synced navigation, group chat, and stop signals for road trips", icon: "point.3.connected.trianglepath.dotted"),
                TutorialFeature(id: "c4", title: "Charger Reviews", description: "Real-time wait times and reviews from the Tesla community", icon: "star.fill"),
            ],
            accentColorName: "cyan"
        ),
        TutorialPage(
            id: "vehicle",
            title: "Vehicle\nCommand Center",
            subtitle: "Total Control & Prediction",
            description: "Monitor every aspect of your Tesla with predictive maintenance, intelligent Sentry Mode, and comprehensive diagnostics.",
            icon: "car.fill",
            features: [
                TutorialFeature(id: "v1", title: "Predictive Maintenance", description: "AI predicts tire wear, brake life, and filter status per-component", icon: "wrench.and.screwdriver"),
                TutorialFeature(id: "v2", title: "Smart Sentry", description: "Computer vision filters false alarms, categorizes real threats", icon: "eye.fill"),
                TutorialFeature(id: "v3", title: "Live Diagnostics", description: "Tire pressures, temperatures, efficiency stats at a glance", icon: "gauge.with.dots.needle.50percent"),
                TutorialFeature(id: "v4", title: "Road Quality Map", description: "Crowd-sourced surface data suggests smoother alternative routes", icon: "road.lanes"),
            ],
            accentColorName: "red"
        ),
    ]

    static let featureTutorials: [String: [TutorialFeature]] = [
        "sentry": [
            TutorialFeature(id: "s1", title: "Smart Filtering", description: "AI analyzes Sentry events to filter out wind, rain, and passing pedestrians. Only real threats trigger alerts.", icon: "brain"),
            TutorialFeature(id: "s2", title: "Context-Aware Sensitivity", description: "Set high sensitivity at night in parking garages, low in your home garage. The system adapts automatically.", icon: "slider.horizontal.3"),
            TutorialFeature(id: "s3", title: "Event Categories", description: "Events are auto-categorized: Vehicle Touch, Person Approaching, Collision, Weather, Animal. Review only what matters.", icon: "folder.fill"),
            TutorialFeature(id: "s4", title: "Instant Alerts", description: "Get push notifications with thumbnail previews for verified threat events. No more scrubbing through hours of footage.", icon: "bell.badge.fill"),
        ],
        "fleet": [
            TutorialFeature(id: "f1", title: "Vehicle Roster", description: "See all your Teslas at a glance — charge levels, locations, and availability for upcoming trips.", icon: "car.2.fill"),
            TutorialFeature(id: "f2", title: "Trip Assignment", description: "Planning a road trip? The system recommends which vehicle to take based on charge, range, and efficiency.", icon: "arrow.triangle.branch"),
            TutorialFeature(id: "f3", title: "Staggered Charging", description: "Automatically schedules charging across vehicles to stay under your electrical panel's capacity limit.", icon: "bolt.horizontal.fill"),
            TutorialFeature(id: "f4", title: "Shared Routines", description: "Create routines that apply to any vehicle — the one that's home gets the action.", icon: "gearshape.2.fill"),
        ],
    ]
}
