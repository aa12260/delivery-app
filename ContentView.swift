import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: DeliveryStore
    @State private var showingAddDelivery = false
    @State private var filter: DeliveryFilter = .all

    enum DeliveryFilter: String, CaseIterable, Identifiable {
        case all = "הכול"
        case active = "פעילות"
        case delivered = "נמסרו"

        var id: String { rawValue }
    }

    private var filteredDeliveries: [Delivery] {
        switch filter {
        case .all:
            return store.deliveries
        case .active:
            return store.deliveries.filter { !$0.isDelivered }
        case .delivered:
            return store.deliveries.filter(\.isDelivered)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                summaryCard

                Picker("סינון", selection: $filter) {
                    ForEach(DeliveryFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if filteredDeliveries.isEmpty {
                    ContentUnavailableView(
                        "אין משלוחים",
                        systemImage: "shippingbox",
                        description: Text("לחץ על + כדי להוסיף משלוח חדש")
                    )
                } else {
                    List {
                        ForEach(filteredDeliveries) { delivery in
                            NavigationLink {
                                DeliveryDetailView(delivery: delivery)
                            } label: {
                                DeliveryRow(delivery: delivery)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if !delivery.isDelivered {
                                    Button {
                                        store.markDelivered(delivery)
                                    } label: {
                                        Label("נמסר", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("ניהול משלוחים")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAddDelivery = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddDelivery) {
                AddDeliveryView()
            }
        }
    }

    private var summaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("פעילות")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(store.activeCount)")
                    .font(.title.bold())
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("רווח שנמסר")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(store.totalEarnings, specifier: "%.0f") ₪")
                    .font(.title.bold())
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

struct DeliveryRow: View {
    let delivery: Delivery

    var body: some View {
        HStack(spacing: 12) {
            if
                let data = delivery.imageData,
                let image = UIImage(data: data)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "shippingbox.fill")
                    .frame(width: 58, height: 58)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    delivery.customerName.isEmpty
                    ? "ללא שם"
                    : delivery.customerName
                )
                .font(.headline)

                Text(delivery.type.rawValue)
                    .font(.subheadline)

                Text(delivery.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(delivery.fee, specifier: "%.0f") ₪")
                    .font(.headline)

                Text(delivery.isDelivered ? "נמסר" : "פעיל")
                    .font(.caption.bold())
                    .foregroundStyle(
                        delivery.isDelivered ? .green : .orange
                    )
            }
        }
        .padding(.vertical, 4)
    }
}
