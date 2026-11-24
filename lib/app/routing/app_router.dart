import 'package:flutter/material.dart';

import '../../features/about/about_screen.dart';
import '../../features/legal/contact_support_screen.dart';
import '../../features/legal/data_deletion_screen.dart';
import '../../features/legal/election_disclaimer_screen.dart';
import '../../features/legal/help_center_screen.dart';
import '../../features/legal/refund_shipping_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/privacy/privacy_policy_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/admin/admin_client_screen.dart';
import '../../features/admin/admin_panel_screen.dart';
import '../../features/dashboard/screens/administrations_screen.dart';
import '../../features/dashboard/screens/dashboard_placeholder_screen.dart';
import '../../features/merchandise/screens/campaign_templates_screen.dart';
import '../../features/merchandise/screens/merchandise_screen.dart';
import '../../features/letter_generator/letter_generator_screen.dart';
import '../../features/speech_generator/speech_generator_screen.dart';
import '../../features/speech_generator/speech_preview_screen.dart';
import '../../features/onboarding/screens/basic_profile_screen.dart';
import '../../features/onboarding/screens/additional_profile_screen.dart';
import '../../features/onboarding/screens/domain_search_screen.dart';
import '../../features/onboarding/password_reset/forgot_password_screen.dart';
import '../../features/onboarding/password_reset/new_password_screen.dart';
import '../../features/onboarding/password_reset/otp_channel_screen.dart';
import '../../features/onboarding/password_reset/password_reset_request.dart';
import '../../features/onboarding/password_reset/reset_success_screen.dart';
import '../../features/onboarding/password_reset/verify_otp_screen.dart';
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/otp_login_screen.dart';
import '../../features/onboarding/screens/ready_screen.dart';
import '../../features/onboarding/blue_tik/blue_tik_screen.dart';
import '../../features/onboarding/voter_lists/voter_lists_screen.dart';
import '../../features/onboarding/screens/social_setup_screen.dart';
import '../../features/vrm/screens/vrm_get_more_screen.dart';
import '../../features/vrm/screens/vrm_records_screen.dart';
import '../../features/team/screens/team_management_screen.dart';
import '../../features/volunteers/screens/volunteer_management_screen.dart';
import '../../features/social_media/social_media_screen.dart';
import '../../features/social_integration/social_integration_screen.dart';
import '../../features/onboarding/screens/website_screen.dart';
import '../../features/website/screens/website_edit_screen.dart';
import '../../features/website/screens/website_generating_screen.dart';
import '../../features/website/screens/website_info_screen.dart';
import '../../features/website/screens/website_preview_screen.dart';
import '../../features/website/screens/website_publish_screen.dart';
import '../../features/website/screens/website_purchase_screen.dart';
import '../../features/website/screens/website_questions_screen.dart';
import '../../features/website/screens/website_sections_screen.dart';
import '../../core/widgets/global_footer.dart';
import 'app_routes.dart';
export 'app_routes.dart';

String? _phoneArgument(Object? arguments) {
  if (arguments is! String) return null;
  final value = arguments.trim();
  if (value.isEmpty || value == 'whatsapp') return null;
  return value;
}

abstract final class AppRouter {
  static String normalizeRouteName(String? name) {
    if (name == null || name.isEmpty) return AppRoutes.login;
    final path = Uri.parse(name).path;
    if (path.isEmpty) return AppRoutes.login;
    return path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final normalized = normalizeRouteName(settings.name);
    final page = switch (normalized) {
      AppRoutes.authCallback => const LoginScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.resetChannel => OtpChannelScreen(
        request:
            settings.arguments is PasswordResetRequest
                ? settings.arguments! as PasswordResetRequest
                : const PasswordResetRequest(identifier: '', isEmail: false),
      ),
      AppRoutes.resetOtp => VerifyOtpScreen(
        request:
            settings.arguments is PasswordResetRequest
                ? settings.arguments! as PasswordResetRequest
                : const PasswordResetRequest(identifier: '', isEmail: false),
      ),
      AppRoutes.resetPassword => NewPasswordScreen(
        request:
            settings.arguments is PasswordResetRequest
                ? settings.arguments! as PasswordResetRequest
                : const PasswordResetRequest(identifier: '', isEmail: false),
      ),
      AppRoutes.resetSuccess => const ResetSuccessScreen(),
      AppRoutes.otp => OtpLoginScreen(
        channel: 'whatsapp',
        initialPhone: _phoneArgument(settings.arguments),
      ),
      AppRoutes.profile => const BasicProfileScreen(),
      AppRoutes.additionalProfile => const AdditionalProfileScreen(),
      AppRoutes.domain => const DomainSearchScreen(),
      AppRoutes.website => const WebsiteScreen(),
      AppRoutes.websiteInfo => const WebsiteInfoScreen(),
      AppRoutes.websiteQuestions => const WebsiteQuestionsScreen(),
      AppRoutes.websiteSections => const WebsiteSectionsScreen(),
      AppRoutes.websiteGenerating => const WebsiteGeneratingScreen(),
      AppRoutes.websitePreview => const WebsitePreviewScreen(),
      AppRoutes.websiteEdit => const WebsiteEditScreen(),
      AppRoutes.websitePurchase => const WebsitePurchaseScreen(),
      AppRoutes.websitePublish => const WebsitePublishScreen(),
      AppRoutes.social => const SocialSetupScreen(),
      AppRoutes.blueTik => const BlueTikScreen(),
      AppRoutes.voterLists => const VoterListsScreen(),
      AppRoutes.campaignTemplates => const CampaignTemplatesScreen(),
      AppRoutes.speechPreview => const SpeechPreviewScreen(),
      AppRoutes.vrmRecords => const VrmRecordsScreen(),
      AppRoutes.vrmGetMore => const VrmGetMoreScreen(),
      AppRoutes.volunteers => VolunteerManagementScreen(
        openAddOnLoad: settings.arguments == 'add',
      ),
      AppRoutes.team => const TeamManagementScreen(),
      AppRoutes.socialContacts => const SocialMediaScreen(),
      AppRoutes.socialIntegration => const SocialIntegrationScreen(),
      AppRoutes.ready => const ReadyScreen(),
      AppRoutes.dashboard => const DashboardPlaceholderScreen(),
      AppRoutes.administrations => const AdministrationsScreen(),
      AppRoutes.admin => const AdminPanelScreen(),
      AppRoutes.adminClient => AdminClientScreen(
        clientId:
            settings.arguments is String ? settings.arguments! as String : '',
      ),
      AppRoutes.merchandise => const MerchandiseScreen(),
      AppRoutes.speech => const SpeechGeneratorScreen(),
      AppRoutes.letter => const LetterGeneratorScreen(),
      AppRoutes.about => const AboutScreen(),
      AppRoutes.privacyPolicy => const PrivacyPolicyScreen(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.helpCenter || AppRoutes.faqs => const HelpCenterScreen(),
      AppRoutes.terms => const TermsScreen(),
      AppRoutes.dataDeletion => const DataDeletionScreen(),
      AppRoutes.electionDisclaimer => const ElectionDisclaimerScreen(),
      AppRoutes.refundPolicy => const RefundShippingScreen(),
      AppRoutes.contactSupport => const ContactSupportScreen(),
      _ => const LoginScreen(),
    };

    final showFooter = AppRoutes.showsGlobalFooter(normalized);
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        if (!showFooter) return page;
        return AppFooterShell(child: page);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static void open(BuildContext context, String route, {Object? arguments}) {
    AppNav.open(context, route, arguments: arguments);
  }

  static void replace(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  static void back(BuildContext context, String fallbackRoute) {
    AppNav.back(context, fallbackRoute);
  }

  /// Returns to the previous route. Does nothing when this screen is the root,
  /// and ignores a second tap while the route is already leaving.
  static void popIfPossible(BuildContext context) {
    final current = ModalRoute.of(context);
    if (current != null && !current.isCurrent) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
