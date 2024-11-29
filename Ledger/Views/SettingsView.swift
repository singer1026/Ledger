import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外观")) {
                    Toggle("深色模式", isOn: $isDarkMode)
                }
                
                Section(header: Text("数据管理")) {
                    Button(action: exportData) {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingImportPicker = true }) {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let backupURL = DataManager.shared.backupData() {
                ShareSheet(activityItems: [backupURL])
            }
        }
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(
                types: [UTType.data],
                allowsMultipleSelection: false
            ) { urls in
                guard let url = urls.first else { return }
                importData(from: url)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportData() {
        showingExportSheet = true
    }
    
    private func importData(from url: URL) {
        if DataManager.shared.restoreData(from: url) {
            alertTitle = "成功"
            alertMessage = "数据导入成功，请重启应用以加载新数据"
        } else {
            alertTitle = "错误"
            alertMessage = "数据导入失败，请确保选择了正确的备份文件"
        }
        showingAlert = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let allowsMultipleSelection: Bool
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}

#Preview {
    SettingsView()
} 