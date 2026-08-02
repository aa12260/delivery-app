import SwiftUI
import UIKit

struct DeliveryDetailView: View {
    @EnvironmentObject private var store: DeliveryStore

    let delivery: Delivery

    private var currentDelivery: Delivery {
        store.deliveries.first {
            $0.id == delivery.id
        } ?? delivery
    }

    var body: some View {
        List {
            if
                let data = currentDelivery.imageData,
                let image = UIImage(data: data)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
            }

            Section("פרטי המשלוח") {
                LabeledContent(
                    "סוג",
                    value: currentDelivery.type.rawValue
                )

                LabeledContent(
                    "תשלום",
                    value: "\(currentDelivery.fee, specifier: "%.0f") ₪"
                )

                LabeledContent(
                    "שם",
                    value: currentDelivery.customerName
                )

                LabeledContent(
                    "טלפון",
                    value: currentDelivery.phone
                )

                LabeledContent(
                    "כתובת",
                    value: currentDelivery.address
                )
            }

            Section("זמנים") {
                LabeledContent(
                    "זמן טעינה",
                    value: currentDelivery.loadingTime.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )

                if let deliveredTime = currentDelivery.deliveredTime {
                    LabeledContent(
                        "זמן מסירה",
                        value: deliveredTime.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                } else {
                    Text("טרם נמסר")
                        .foregroundStyle(.orange)
                }
            }

            if !currentDelivery.notes.isEmpty {
                Section("הערות") {
                    Text(currentDelivery.notes)
                }
            }

            if !currentDelivery.isDelivered {
                Section {
                    Button {
                        store.markDelivered(currentDelivery)
                    } label: {
                        Label(
                            "סימון כנמסר",
                            systemImage: "checkmark.circle.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .tint(.green)
                }
            }
        }
        .navigationTitle("פרטי משלוח")
    }
}
