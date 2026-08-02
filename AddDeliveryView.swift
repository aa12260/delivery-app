import SwiftUI
import PhotosUI
import Vision

struct AddDeliveryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DeliveryStore

    @State private var type: DeliveryType = .regular
    @State private var customerName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var imageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            Form {
                Section("סוג המשלוח") {
                    Picker("סוג", selection: $type) {
                        ForEach(DeliveryType.allCases) { item in
                            Text(
                                "\(item.rawValue) – \(item.fee, specifier: "%.0f") ₪"
                            )
                            .tag(item)
                        }
                    }
                }

                Section("פרטי הלקוח") {
                    TextField("שם הלקוח", text: $customerName)

                    TextField("מספר טלפון", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("כתובת", text: $address, axis: .vertical)

                    TextField("הערות", text: $notes, axis: .vertical)
                }

                Section("צילום התעודה") {
                    if
                        let imageData,
                        let image = UIImage(data: imageData)
                    {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )

                        Button {
                            scanImage(image)
                        } label: {
                            Label(
                                isScanning
                                ? "סורק..."
                                : "סריקת פרטים מהתמונה",
                                systemImage: "text.viewfinder"
                            )
                        }
                        .disabled(isScanning)
                    }

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Label(
                            "בחירה מהתמונות",
                            systemImage: "photo"
                        )
                    }

                    Button {
                        showingCamera = true
                    } label: {
                        Label(
                            "פתיחת מצלמה",
                            systemImage: "camera"
                        )
                    }
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Text("שמירת המשלוח")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .disabled(
                        customerName
                            .trimmingCharacters(in: .whitespaces)
                            .isEmpty
                        &&
                        phone
                            .trimmingCharacters(in: .whitespaces)
                            .isEmpty
                        &&
                        address
                            .trimmingCharacters(in: .whitespaces)
                            .isEmpty
                    )
                }
            }
            .navigationTitle("משלוח חדש")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else {
                    return
                }

                Task {
                    if let data = try? await newItem
                        .loadTransferable(type: Data.self)
                    {
                        imageData = data
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    imageData = image.jpegData(
                        compressionQuality: 0.75
                    )
                }
            }
        }
    }

    private func save() {
        let delivery = Delivery(
            type: type,
            customerName: customerName
                .trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone
                .trimmingCharacters(in: .whitespacesAndNewlines),
            address: address
                .trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes
                .trimmingCharacters(in: .whitespacesAndNewlines),
            loadingTime: Date(),
            deliveredTime: nil,
            imageData: imageData
        )

        store.add(delivery)
        dismiss()
    }

    private func scanImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            return
        }

        isScanning = true

        let request = VNRecognizeTextRequest { request, _ in
            let lines = (
                request.results as? [VNRecognizedTextObservation]
            )?
            .compactMap {
                $0.topCandidates(1).first?.string
            } ?? []

            DispatchQueue.main.async {
                applyRecognizedText(lines)
                isScanning = false
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = [
            "he-IL",
            "ar",
            "en-US"
        ]
        request.usesLanguageCorrection = true

        DispatchQueue.global(
            qos: .userInitiated
        ).async {
            try? VNImageRequestHandler(
                cgImage: cgImage
            ).perform([request])
        }
    }

    private func applyRecognizedText(
        _ lines: [String]
    ) {
        let allText = lines.joined(
            separator: "\n"
        )

        if
            phone.isEmpty,
            let match = allText.range(
                of: #"(?:\+972|0)[\d\-\s]{8,12}"#,
                options: .regularExpression
            )
        {
            phone = String(allText[match])
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        }

        if
            customerName.isEmpty,
            let first = lines.first
        {
            customerName = first
        }

        if address.isEmpty {
            let addressHints = [
                "רחוב",
                "כתובת",
                "ירושלים",
                "רמאללה",
                "בית",
                "שכונה"
            ]

            if let line = lines.first(
                where: { candidate in
                    addressHints.contains(
                        where: {
                            candidate.contains($0)
                        }
                    )
                }
            ) {
                address = line
            }
        }

        if notes.isEmpty {
            notes = allText
        }
    }
}
