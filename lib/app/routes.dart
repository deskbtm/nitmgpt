abstract final class AppRoutes {
  static const home = '/home';
  static const settings = '/settings';
  static const rules = '/settings/rules';
  static const localModels = '/settings/local-models';
  static const localModelSettings = '/settings/local-models/:modelId/settings';
  static const permissions = '/settings/permissions';
  static const developer = '/settings/developer';
  static const developerAdNotifications = '/settings/developer/ad-notifications';

  static String localModelSettingsFor(String modelId) =>
      '/settings/local-models/${Uri.encodeComponent(modelId)}/settings';
}
