import SwiftUI
import UIKit

/// UIViewRepresentable wrapping UITextField — this is the exact pattern described in the issue.
/// The UITextField is NOT added directly to the view hierarchy; it goes through SwiftUI's
/// hosting infrastructure, which introduces intermediate views (_UIHostingView, etc.)
/// that alter the responder chain.
struct NativeTextFieldWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = "Tap here — keyboard should appear"
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {}
}

/// SwiftUI View containing the UIViewRepresentable-wrapped UITextField.
struct TextFieldSwiftUIView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("SwiftUI hosted UITextField")
                .font(.headline)
            NativeTextFieldWrapper()
                .frame(height: 44)
                .padding(.horizontal)
        }
        .padding()
    }
}

/// Factory class exposed to ObjC/C# that creates a UIHostingController
/// hosting the SwiftUI view tree containing the UIViewRepresentable-wrapped UITextField.
@objc(SwiftUIViewFactory) public class SwiftUIViewFactory: NSObject {
    @objc public static func createTextFieldHostingController() -> UIViewController {
        return UIHostingController(rootView: TextFieldSwiftUIView())
    }
}
