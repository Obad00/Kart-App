class FeatureFlags {
  static const bool businessFeaturesEnabled =
      bool.fromEnvironment('BUSINESS_FEATURES_ENABLED', defaultValue: false);
}
