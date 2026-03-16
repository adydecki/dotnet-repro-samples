#if IOS || MACCATALYST
using System.Runtime.InteropServices;
using Microsoft.Maui.Handlers;
using UIKit;
using Foundation;
using ObjCRuntime;
using iOSIssue.Controls;

namespace iOSIssue.Platforms.iOS.Handlers;

public class SwiftUITextFieldHandler : ViewHandler<SwiftUITextField, UIView>
{
    private UIViewController? _hostingController;

    public static IPropertyMapper<SwiftUITextField, SwiftUITextFieldHandler> Mapper =
        new PropertyMapper<SwiftUITextField, SwiftUITextFieldHandler>(ViewMapper);

    public SwiftUITextFieldHandler() : base(Mapper) { }

    protected override UIView CreatePlatformView()
    {
        // Step 1: Custom MAUI handler wraps a native UIView
        var containerView = new UIView { BackgroundColor = UIColor.SystemBackground };

        // Step 2: Create a real UIHostingController hosting a SwiftUI view that contains
        //         a UIViewRepresentable wrapping a UITextField.
        //         This is the EXACT pattern described in the issue — NOT a plain UIViewController.
        _hostingController = CreateHostingControllerFromSwiftUI();
        _hostingController.View!.TranslatesAutoresizingMaskIntoConstraints = false;

        containerView.AddSubview(_hostingController.View);

        NSLayoutConstraint.ActivateConstraints(new[]
        {
            _hostingController.View.LeadingAnchor.ConstraintEqualTo(containerView.LeadingAnchor),
            _hostingController.View.TrailingAnchor.ConstraintEqualTo(containerView.TrailingAnchor),
            _hostingController.View.TopAnchor.ConstraintEqualTo(containerView.TopAnchor),
            _hostingController.View.BottomAnchor.ConstraintEqualTo(containerView.BottomAnchor),
        });

        return containerView;
    }

    [DllImport("/usr/lib/libobjc.dylib", EntryPoint = "objc_msgSend")]
    private static extern IntPtr objc_msgSend(IntPtr receiver, IntPtr selector);

    /// Creates a UIHostingController&lt;TextFieldSwiftUIView&gt; via the @objc SwiftUIViewFactory
    /// from the NativeSwiftUILib framework. The hosted SwiftUI view contains a UIViewRepresentable
    /// that wraps a UITextField — reproducing the exact view hierarchy described in the issue.
    private static UIViewController CreateHostingControllerFromSwiftUI()
    {
        var factoryClass = Class.GetHandle("SwiftUIViewFactory");
        if (factoryClass == IntPtr.Zero)
            throw new InvalidOperationException(
                "SwiftUIViewFactory not found. Ensure NativeSwiftUILib.xcframework is linked.");

        var selector = new Selector("createTextFieldHostingController");
        var handle = objc_msgSend(factoryClass, selector.Handle);
        var viewController = Runtime.GetNSObject<UIViewController>(handle)
            ?? throw new InvalidOperationException("Failed to create UIHostingController.");

        return viewController;
    }

    protected override void ConnectHandler(UIView platformView)
    {
        base.ConnectHandler(platformView);

        if (_hostingController == null) return;
        var responder = platformView.NextResponder;
        while (responder != null)
        {
            if (responder is UIViewController parentVC)
            {
                parentVC.AddChildViewController(_hostingController);
                _hostingController.DidMoveToParentViewController(parentVC);
                break;
            }
            responder = responder.NextResponder;
        }
    }

    protected override void DisconnectHandler(UIView platformView)
    {
        _hostingController?.WillMoveToParentViewController(null);
        _hostingController?.View?.RemoveFromSuperview();
        _hostingController?.RemoveFromParentViewController();
        _hostingController = null;
        base.DisconnectHandler(platformView);
    }
}
#endif
