import Foundation

@MainActor
final class DeliveryStore: ObservableObject {
    @Published var deliveries: [Delivery] = [] {
        didSet {
            save()
        }
    }

    private let fileName = "deliveries.json"

    init() {
        load()
    }

    var totalEarnings: Double {
        deliveries
            .filter(\.isDelivered)
            .reduce(0) { $0 + $1.fee }
    }

    var activeCount: Int {
        deliveries.filter { !$0.isDelivered }.count
    }

    func add(_ delivery: Delivery) {
        deliveries.insert(delivery, at: 0)
    }

    func markDelivered(_ delivery: Delivery) {
        guard let index = deliveries.firstIndex(where: {
            $0.id == delivery.id
        }) else {
            return
        }

        deliveries[index].deliveredTime = Date()
    }

    func delete(at offsets: IndexSet) {
        deliveries.remove(atOffsets: offsets)
    }

    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    private func save() {
        guard let fileURL else {
            return
        }

        do {
            let data = try JSONEncoder().encode(deliveries)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Save error: \(error)")
        }
    }

    private func load() {
        guard
            let fileURL,
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(
                [Delivery].self,
                from: data
            )
        else {
            deliveries = []
            return
        }

        deliveries = decoded
    }
}
