class ApiEndpoints {
  // static const baseUrl = 'https://backend.kart.business/api';
  // static const storageUrl = 'https://backend.kart.business/storage';

  // static const baseUrl = 'https://kart.meblo.cloud/api';
  // static const storageUrl = 'https://kart.meblo.cloud/storage';

  static const baseUrl = 'http://127.0.0.1:8000/api';
  static const storageUrl = 'http://127.0.0.1:8000/storage';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const googleToken = '/auth/google/token';
  static const appleToken = '/auth/apple/token';
  static const me = '/me';
  static const logout = '/auth/logout';
  static const deleteAccount = '/auth/delete-account';
  static const activateAccount = '/auth/activate-account';
  static const resendVerificationEmail = '/auth/resend-verification-email';

  // Plans
  static const plans = '/plans';

  // Payments
  static const paymentMethods = '/payments/methods';
  static const paymentInitialize = '/payments/initialize';
  static String paymentStatus(String reference) =>
      '/payments/$reference/status';
  static const paymentHistory = '/payments/history';

  // Card Scanner
  static const scanCard = '/card-scan';

  // Contacts
  static const contacts = '/contacts';
}
