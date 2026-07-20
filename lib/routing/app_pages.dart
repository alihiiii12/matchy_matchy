import 'package:get/get.dart';
import 'package:matchy_matchy/core/bindings/app_screen_bindings.dart';
import 'package:matchy_matchy/core/controllers/admin_coupon_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_coupons_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_broadcast_notification_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_categories_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_category_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisement_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisements_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_subcategories_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_subcategory_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_drivers_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_create_driver_controller.dart';
import 'package:matchy_matchy/core/controllers/driver_jobs_controller.dart';
import 'package:matchy_matchy/core/controllers/driver_subscriptions_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_sales_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_delivery_tracking_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_orders_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_users_controller.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/checkout_address_controller.dart';
import 'package:matchy_matchy/core/controllers/coordinate_delivery_controller.dart';
import 'package:matchy_matchy/core/controllers/change_password_controller.dart';
import 'package:matchy_matchy/core/controllers/edit_profile_controller.dart';
import 'package:matchy_matchy/core/controllers/create_account_controller.dart';
import 'package:matchy_matchy/core/controllers/forgot_password_controller.dart';
import 'package:matchy_matchy/core/controllers/new_password_controller.dart';
import 'package:matchy_matchy/core/controllers/delivery_options_controller.dart';
import 'package:matchy_matchy/core/controllers/google_phone_controller.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/controllers/login_controller.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/controllers/my_deliveries_controller.dart';
import 'package:matchy_matchy/core/controllers/my_orders_controller.dart';
import 'package:matchy_matchy/core/controllers/notifications_controller.dart';
import 'package:matchy_matchy/core/controllers/onboarding_controller.dart';
import 'package:matchy_matchy/core/controllers/order_history_controller.dart';
import 'package:matchy_matchy/core/controllers/order_track_controller.dart';
import 'package:matchy_matchy/core/controllers/otp_verification_controller.dart';
import 'package:matchy_matchy/core/controllers/payment_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/controllers/search_filter_controller.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/controllers/splash_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/routing/app_routes.dart';
import 'package:matchy_matchy/screens/admin/admin_coupon_form_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_coupons_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_broadcast_notification_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_categories_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_home_advertisement_form_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_home_advertisements_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_category_form_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_edit_driver_screen.dart';
import 'package:matchy_matchy/core/controllers/admin_edit_driver_controller.dart';
import 'package:matchy_matchy/screens/admin/admin_subcategories_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_subcategory_form_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_drivers_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_create_driver_screen.dart';
import 'package:matchy_matchy/screens/driver/driver_subscriptions_screen.dart';
import 'package:matchy_matchy/screens/driver/driver_job_detail_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_sales_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_delivery_tracking_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_orders_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_users_screen.dart';
import 'package:matchy_matchy/screens/auth/create_account_screen.dart';
import 'package:matchy_matchy/screens/auth/create_account_success_screen.dart';
import 'package:matchy_matchy/screens/auth/forgot_password_screen.dart';
import 'package:matchy_matchy/screens/auth/google_phone_screen.dart';
import 'package:matchy_matchy/screens/auth/login_screen.dart';
import 'package:matchy_matchy/screens/auth/new_password_screen.dart';
import 'package:matchy_matchy/screens/auth/otp_verification_screen.dart';
import 'package:matchy_matchy/screens/cart/cart_screen.dart';
import 'package:matchy_matchy/screens/cart/cart_selected_screen.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/screens/categories/categories_screen.dart';
import 'package:matchy_matchy/screens/categories/category_products_screen.dart';
import 'package:matchy_matchy/screens/categories/sub_categories_screen.dart';
import 'package:matchy_matchy/screens/checkout/add_card_screen.dart';
import 'package:matchy_matchy/screens/checkout/address_screen.dart';
import 'package:matchy_matchy/screens/checkout/change_payment_screen.dart';
import 'package:matchy_matchy/screens/checkout/checkout_address_screen.dart';
import 'package:matchy_matchy/screens/checkout/map_location_picker_screen.dart';
import 'package:matchy_matchy/screens/checkout/payment_screen.dart';
import 'package:matchy_matchy/screens/checkout/payment_success_screen.dart';
import 'package:matchy_matchy/screens/delivery/coordinate_delivery_screen.dart';
import 'package:matchy_matchy/screens/delivery/delivery_options_screen.dart';
import 'package:matchy_matchy/core/controllers/delivery_tracking_controller.dart';
import 'package:matchy_matchy/screens/delivery/delivery_tracking_screen.dart';
import 'package:matchy_matchy/screens/delivery/my_deliveries_screen.dart';
import 'package:matchy_matchy/screens/favorites/favorites_screen.dart';
import 'package:matchy_matchy/screens/main/main_shell.dart';
import 'package:matchy_matchy/screens/messages/message_detail_screen.dart';
import 'package:matchy_matchy/screens/messages/messages_screen.dart';
import 'package:matchy_matchy/screens/notifications/notifications_screen.dart';
import 'package:matchy_matchy/screens/onboarding/onboarding_screen.dart';
import 'package:matchy_matchy/screens/orders/my_orders_screen.dart';
import 'package:matchy_matchy/screens/orders/order_history_screen.dart';
import 'package:matchy_matchy/screens/orders/order_track_screen.dart';
import 'package:matchy_matchy/screens/product/product_detail_screen.dart';
import 'package:matchy_matchy/screens/product/store_detail_screen.dart';
import 'package:matchy_matchy/screens/profile/change_password_screen.dart';
import 'package:matchy_matchy/screens/profile/edit_profile_screen.dart';
import 'package:matchy_matchy/screens/profile/help_support_screen.dart';
import 'package:matchy_matchy/screens/profile/language_screen.dart';
import 'package:matchy_matchy/screens/profile/legal_policies_screen.dart';
import 'package:matchy_matchy/screens/profile/appearance_screen.dart';
import 'package:matchy_matchy/core/controllers/statistics_controller.dart';
import 'package:matchy_matchy/screens/profile/statistics_screen.dart';
import 'package:matchy_matchy/screens/search/search_filter_screen.dart';
import 'package:matchy_matchy/screens/search/search_result_screen.dart';
import 'package:matchy_matchy/screens/search/search_screen.dart';
import 'package:matchy_matchy/screens/splash_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_products_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_product_form_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_custom_outfits_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_store_settings_screen.dart';
import 'package:matchy_matchy/screens/admin/admin_size_guide_screen.dart';
import 'package:matchy_matchy/screens/home/describe_outfit_screen.dart';
import 'package:matchy_matchy/screens/profile/size_guide_screen.dart';
import 'package:matchy_matchy/screens/orders/rate_order_screen.dart';
import 'package:matchy_matchy/screens/driver/driver_earnings_screen.dart';

abstract final class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen(), binding: SplashBinding()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen(), binding: OnboardingBinding()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen(), binding: LoginBinding()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen(), binding: ForgotPasswordBinding()),
    GetPage(name: AppRoutes.newPassword, page: () => const NewPasswordScreen(), binding: NewPasswordBinding()),
    GetPage(name: AppRoutes.createAccount, page: () => const CreateAccountScreen(), binding: CreateAccountBinding()),
    GetPage(name: AppRoutes.verifyOtp, page: () => const OtpVerificationScreen(), binding: OtpVerificationBinding()),
    GetPage(name: AppRoutes.googlePhone, page: () => const GooglePhoneScreen(), binding: GooglePhoneBinding()),
    GetPage(name: AppRoutes.createAccountSuccess, page: () => const CreateAccountSuccessScreen()),
    GetPage(name: AppRoutes.main, page: () => const MainShell(), binding: MainShellBinding()),
    GetPage(name: AppRoutes.categories, page: () => const CategoriesScreen()),
    GetPage(
      name: AppRoutes.subCategories,
      page: () {
        final args = Get.arguments;
        if (args is ShopCategory) {
          return SubCategoriesScreen(category: args);
        }
        return const CategoriesScreen();
      },
    ),
    GetPage(name: AppRoutes.categoryProducts, page: () {
      final args = Get.arguments;
      if (args is ShopCategory) {
        return CategoryProductsScreen(category: args);
      }
      if (args is (ShopCategory, SubCategory)) {
        return CategoryProductsScreen(category: args.$1, subCategory: args.$2);
      }
      if (args is (dynamic, dynamic)) {
        final category = args.$1;
        final sub = args.$2;
        if (category is ShopCategory && sub is SubCategory) {
          return CategoryProductsScreen(category: category, subCategory: sub);
        }
        if (category is ShopCategory) {
          return CategoryProductsScreen(category: category);
        }
      }
      return const CategoriesScreen();
    }),
    GetPage(name: AppRoutes.homeCategory, page: () => const CategoriesScreen()),
    GetPage(name: AppRoutes.search, page: () => const SearchScreen(), binding: SearchBinding()),
    GetPage(name: AppRoutes.searchResult, page: () => SearchResultScreen(query: Get.arguments as String?)),
    GetPage(name: AppRoutes.searchFilter, page: () => const SearchFilterScreen(), binding: SearchFilterBinding()),
    GetPage(name: AppRoutes.productDetail, page: () => ProductDetailScreen(product: Get.arguments)),
    GetPage(name: AppRoutes.storeDetail, page: () => const StoreDetailScreen()),
    GetPage(name: AppRoutes.cart, page: () => const CartScreen(), binding: CartBinding()),
    GetPage(name: AppRoutes.cartSelected, page: () => const CartSelectedScreen()),
    GetPage(name: AppRoutes.checkoutAddress, page: () => const CheckoutAddressScreen(), binding: CheckoutAddressBinding()),
    GetPage(name: AppRoutes.mapLocationPicker, page: () => const MapLocationPickerScreen()),
    GetPage(name: AppRoutes.payment, page: () => const PaymentScreen(), binding: PaymentBinding()),
    GetPage(name: AppRoutes.address, page: () => const AddressScreen()),
    GetPage(name: AppRoutes.addCard, page: () => const AddCardScreen()),
    GetPage(name: AppRoutes.changePayment, page: () => const ChangePaymentScreen()),
    GetPage(name: AppRoutes.paymentSuccess, page: () => const PaymentSuccessScreen()),
    GetPage(name: AppRoutes.myOrders, page: () => MyOrdersScreen(), binding: MyOrdersBinding()),
    GetPage(name: AppRoutes.orderHistory, page: () => const OrderHistoryScreen(), binding: OrderHistoryBinding()),
    GetPage(name: AppRoutes.orderTrack, page: () => const OrderTrackScreen(), binding: OrderTrackBinding()),
    GetPage(name: AppRoutes.deliveryOptions, page: () => const DeliveryOptionsScreen(), binding: DeliveryOptionsBinding()),
    GetPage(name: AppRoutes.myDeliveries, page: () => MyDeliveriesScreen(), binding: MyDeliveriesBinding()),
    GetPage(
      name: AppRoutes.deliveryTracking,
      page: () => DeliveryTrackingScreen(delivery: Get.arguments),
      binding: DeliveryTrackingBinding(),
    ),
    GetPage(name: AppRoutes.coordinateDelivery, page: () => const CoordinateDeliveryScreen(), binding: CoordinateDeliveryBinding()),
    GetPage(name: AppRoutes.adminOrders, page: () => const AdminOrdersScreen(), binding: AdminOrdersBinding()),
    GetPage(
      name: AppRoutes.adminDeliveryTracking,
      page: () => const AdminDeliveryTrackingScreen(),
      binding: AdminDeliveryTrackingBinding(),
    ),
    GetPage(name: AppRoutes.adminSales, page: () => const AdminSalesScreen(), binding: AdminSalesBinding()),
    GetPage(name: AppRoutes.adminUsers, page: () => const AdminUsersScreen(), binding: AdminUsersBinding()),
    GetPage(name: AppRoutes.adminDrivers, page: () => const AdminDriversScreen(), binding: AdminDriversBinding()),
    GetPage(name: AppRoutes.adminCreateDriver, page: () => const AdminCreateDriverScreen(), binding: AdminCreateDriverBinding()),
    GetPage(
      name: AppRoutes.adminEditDriver,
      page: () => const AdminEditDriverScreen(),
      binding: AdminEditDriverBinding(),
    ),
    GetPage(
      name: AppRoutes.adminHomeAdvertisements,
      page: () => const AdminHomeAdvertisementsScreen(),
      binding: AdminHomeAdvertisementsBinding(),
    ),
    GetPage(
      name: AppRoutes.adminHomeAdvertisementForm,
      page: () => const AdminHomeAdvertisementFormScreen(),
      binding: AdminHomeAdvertisementFormBinding(),
    ),
    GetPage(name: AppRoutes.adminCategories, page: () => const AdminCategoriesScreen(), binding: AdminCategoriesBinding()),
    GetPage(name: AppRoutes.adminCategoryForm, page: () => const AdminCategoryFormScreen(), binding: AdminCategoryFormBinding()),
    GetPage(name: AppRoutes.adminSubCategories, page: () => const AdminSubCategoriesScreen(), binding: AdminSubCategoriesBinding()),
    GetPage(name: AppRoutes.adminSubCategoryForm, page: () => const AdminSubCategoryFormScreen(), binding: AdminSubCategoryFormBinding()),
    GetPage(name: AppRoutes.adminBroadcastMessage, page: () => const AdminBroadcastNotificationScreen(), binding: AdminBroadcastNotificationBinding()),
    GetPage(name: AppRoutes.adminCoupons, page: () => const AdminCouponsScreen(), binding: AdminCouponsBinding()),
    GetPage(name: AppRoutes.adminCouponForm, page: () => const AdminCouponFormScreen(), binding: AdminCouponFormBinding()),
    GetPage(name: AppRoutes.favorites, page: () => const FavoritesScreen()),
    GetPage(name: AppRoutes.messages, page: () => const MessagesScreen()),
    GetPage(name: AppRoutes.messageDetail, page: () => MessageDetailScreen(title: Get.arguments as String? ?? AppStrings.chat)),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen(), binding: NotificationsBinding()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen(), binding: EditProfileBinding()),
    GetPage(name: AppRoutes.changePassword, page: () => const ChangePasswordScreen(), binding: ChangePasswordBinding()),
    GetPage(name: AppRoutes.appearance, page: () => const AppearanceScreen(), binding: ThemeBinding()),
    GetPage(name: AppRoutes.language, page: () => const LanguageScreen(), binding: LanguageBinding()),
    GetPage(name: AppRoutes.helpSupport, page: () => const HelpSupportScreen()),
    GetPage(name: AppRoutes.legalPolicies, page: () => const LegalPoliciesScreen()),
    GetPage(name: AppRoutes.statistics, page: () => const StatisticsScreen(), binding: StatisticsBinding()),
    GetPage(name: AppRoutes.driverJobDetail, page: () => const DriverJobDetailScreen(), binding: DriverJobDetailBinding()),
    GetPage(name: AppRoutes.driverSubscriptions, page: () => const DriverSubscriptionsScreen(), binding: DriverSubscriptionsBinding()),
    GetPage(name: AppRoutes.adminProducts, page: () => const AdminProductsScreen()),
    GetPage(name: AppRoutes.adminProductForm, page: () => const AdminProductFormScreen()),
    GetPage(name: AppRoutes.adminCustomOutfits, page: () => const AdminCustomOutfitsScreen()),
    GetPage(name: AppRoutes.adminStoreSettings, page: () => const AdminStoreSettingsScreen()),
    GetPage(name: AppRoutes.adminSizeGuide, page: () => const AdminSizeGuideScreen()),
    GetPage(name: AppRoutes.describeOutfit, page: () => const DescribeOutfitScreen()),
    GetPage(name: AppRoutes.sizeGuide, page: () => const SizeGuideScreen()),
    GetPage(name: AppRoutes.rateOrder, page: () => const RateOrderScreen()),
    GetPage(name: AppRoutes.driverEarnings, page: () => const DriverEarningsScreen()),
  ];

  static Bindings bindingFor(String route) => AppScreenBindings.forRoute(route);
}
