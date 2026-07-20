import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_coupon_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_coupons_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_broadcast_notification_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_categories_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_category_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisement_form_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisements_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_subcategories_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_subcategory_form_controller.dart';
import 'package:matchy_matchy/core/controllers/driver_subscriptions_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_sales_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_delivery_tracking_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_orders_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_drivers_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_create_driver_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_edit_driver_controller.dart';
import 'package:matchy_matchy/core/controllers/driver_jobs_controller.dart';
import 'package:matchy_matchy/core/controllers/admin_users_controller.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/checkout_address_controller.dart';
import 'package:matchy_matchy/core/controllers/coordinate_delivery_controller.dart';
import 'package:matchy_matchy/core/controllers/create_account_controller.dart';
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
import 'package:matchy_matchy/core/controllers/otp_verification_controller.dart';
import 'package:matchy_matchy/core/controllers/payment_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/controllers/search_filter_controller.dart';
import 'package:matchy_matchy/core/controllers/edit_profile_controller.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/controllers/splash_controller.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

/// Central registry of GetX route bindings for the infrastructure agent to wire into GetPages.
abstract final class AppScreenBindings {
  static Bindings forRoute(String route) {
    return switch (route) {
      AppRoutes.splash => SplashBinding(),
      AppRoutes.onboarding => OnboardingBinding(),
      AppRoutes.login => LoginBinding(),
      AppRoutes.createAccount => CreateAccountBinding(),
      AppRoutes.verifyOtp => OtpVerificationBinding(),
      AppRoutes.googlePhone => GooglePhoneBinding(),
      AppRoutes.main => MainShellBinding(),
      AppRoutes.driverJobDetail => DriverJobDetailBinding(),
      AppRoutes.driverSubscriptions => DriverSubscriptionsBinding(),
      AppRoutes.cart => CartBinding(),
      AppRoutes.checkoutAddress => CheckoutAddressBinding(),
      AppRoutes.payment => PaymentBinding(),
      AppRoutes.adminOrders => AdminOrdersBinding(),
      AppRoutes.adminDeliveryTracking => AdminDeliveryTrackingBinding(),
      AppRoutes.adminSales => AdminSalesBinding(),
      AppRoutes.adminUsers => AdminUsersBinding(),
      AppRoutes.adminDrivers => AdminDriversBinding(),
      AppRoutes.adminCreateDriver => AdminCreateDriverBinding(),
      AppRoutes.adminEditDriver => AdminEditDriverBinding(),
      AppRoutes.adminHomeAdvertisements => AdminHomeAdvertisementsBinding(),
      AppRoutes.adminHomeAdvertisementForm => AdminHomeAdvertisementFormBinding(),
      AppRoutes.adminCategories => AdminCategoriesBinding(),
      AppRoutes.adminCategoryForm => AdminCategoryFormBinding(),
      AppRoutes.adminSubCategories => AdminSubCategoriesBinding(),
      AppRoutes.adminSubCategoryForm => AdminSubCategoryFormBinding(),
      AppRoutes.adminBroadcastMessage => AdminBroadcastNotificationBinding(),
      AppRoutes.adminCoupons => AdminCouponsBinding(),
      AppRoutes.adminCouponForm => AdminCouponFormBinding(),
      AppRoutes.myOrders => MyOrdersBinding(),
      AppRoutes.orderHistory => OrderHistoryBinding(),
      AppRoutes.notifications => NotificationsBinding(),
      AppRoutes.myDeliveries => MyDeliveriesBinding(),
      AppRoutes.search => SearchBinding(),
      AppRoutes.searchFilter => SearchFilterBinding(),
      AppRoutes.appearance => ThemeBinding(),
      AppRoutes.language => LanguageBinding(),
      AppRoutes.editProfile => EditProfileBinding(),
      AppRoutes.coordinateDelivery => CoordinateDeliveryBinding(),
      AppRoutes.deliveryOptions => DeliveryOptionsBinding(),
      _ => _EmptyBinding(),
    };
  }
}

class _EmptyBinding extends Bindings {
  @override
  void dependencies() {}
}
