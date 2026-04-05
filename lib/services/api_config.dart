class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SWIFTCART_API_BASE_URL',
    defaultValue: 'http://localhost:5187',
  );
}
