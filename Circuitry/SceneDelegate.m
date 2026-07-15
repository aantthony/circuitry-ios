#import "SceneDelegate.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    // The scene's window and root view controller are created from Main.storyboard.
    self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
}

@end
