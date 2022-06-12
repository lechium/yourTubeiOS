
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "KBMenu.h"
NS_ASSUME_NONNULL_BEGIN

@class KBContextMenuView, KBButton;

typedef NS_ENUM(NSInteger, KBButtonType) {
    KBButtonTypeText,
    KBButtonTypeImage,
};

@protocol KBButtonMenuDelegate <NSObject>

- (void)menuShown:(KBContextMenuView *)menu from:(KBButton *)button;
- (void)menuHidden:(KBContextMenuView *)menu from:(KBButton *)button;
- (void)itemSelected:(KBMenuElement *)item menu:(KBContextMenuView *)menu from:(KBButton *)button;
@end

@interface KBButton: UIControl

@property (readwrite, assign) KBButtonType buttonType;
@property (nonatomic, strong, nullable) UILabel *titleLabel;
@property (nonatomic, strong, nullable) UIImageView *buttonImageView;
@property (nonatomic, strong, nullable) KBMenu *menu;
@property (nonatomic, assign, nullable) id <KBButtonMenuDelegate> menuDelegate;
@property (nonatomic, readwrite, assign) BOOL showsMenuAsPrimaryAction;

@property BOOL opened;
@property (nonatomic, copy, nullable) void (^focusChanged)(BOOL focused, UIFocusHeading direction);
+(instancetype)buttonWithType:(KBButtonType)buttonType;
- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state;
- (void)dismissMenuWithCompletion:(void(^)(void))block;
@end

NS_ASSUME_NONNULL_END
