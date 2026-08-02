import Foundation

enum DeliveryType: String, Codable, CaseIterable, Identifiable {
    case regular = "משלוח רגיל"
    case drinks = "משלוח שתיה"
    case vegetables = "משלוח ירקות"

    var id: String { rawValue }

    var fee: Double {
        switch self {
        case .regular, .vegetables:
            return 10
        case .drinks:
            return 20
        }
    }
}

struct Delivery: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: DeliveryType
    var customerName: String
    var phone: String
    var address: String
    var notes: String
    var loadingTime: Date
    var deliveredTime: Date?
    var imageData: Data?

    var isDelivered: Bool {
        deliveredTime != nil
    }

    var fee: Double {
        type.fee
    }
}
