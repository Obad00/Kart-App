class ApiEndpoints {
  // static const baseUrl = 'https://backend.kart.business/api';
  // static const storageUrl = 'https://backend.kart.business/storage';

  static const baseUrl = 'http://127.0.0.1:8000/api';
  static const storageUrl = 'http://127.0.0.1:8000/storage';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const googleToken = '/auth/google/token';
  static const me = '/me';
  static const logout = '/auth/logout';

  // Plans
  static const plans = '/plans';

  // Payments
  static const paymentMethods = '/payments/methods';
  static const paymentInitialize = '/payments/initialize';
  static String paymentStatus(String reference) =>
      '/payments/$reference/status';
  static const paymentHistory = '/payments/history';
  static const activateFreePlan = '/subscriptions/activate-free-plan';

  // Card Scanner
  static const scanCard = '/card-scan';

  // Contacts
  static const contacts = '/contacts';
}
