class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SWIFTCART_API_BASE_URL',
    defaultValue: 'https://swiftcart-api-ea-9649.azurewebsites.net',
  );
}
