using Microsoft.Extensions.Logging;
using iOSIssue.Controls;
using Microsoft.Maui.Controls.Hosting;
using Microsoft.Maui.Hosting;
#if IOS || MACCATALYST
using iOSIssue.Platforms.iOS.Handlers;
#endif

namespace iOSIssue;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            })
            .ConfigureMauiHandlers(handlers =>
            {
#if IOS || MACCATALYST
                handlers.AddHandler<SwiftUITextField, SwiftUITextFieldHandler>();
#endif
            });

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}