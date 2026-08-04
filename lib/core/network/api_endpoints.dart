class ApiEndpoints {
  // static const baseUrl = 'https://backend.kart.business/api';
  // static const storageUrl = 'https://backend.kart.business/storage';

  static const baseUrl = 'https://kart.meblo.cloud/api';
  static const storageUrl = 'https://kart.meblo.cloud/storage';

  // backend local pour tester la Phase  (lancer `php artisan serve`)
  // static const baseUrl = 'http://127.0.0.1:8000/api';
  // static const storageUrl = 'http://127.0.0.1:8000/storage';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const googleToken = '/auth/google/token';
  static const appleToken = '/auth/apple/token';
  static const me = '/me';
  static const logout = '/auth/logout';
  static const deleteAccount = '/me';
  static const changePassword = '/auth/change-password';
  static const forgotPassword = '/auth/forgot-password';

  // Entreprise (lecture seule)
  static const companyMe = '/companies/me';
  static const companyEmployees = '/company/employees';
  static const cardCreateContext = '/cards/create-context';

  // Plans
  static const plans = '/plans';
  static const activateFreePlan = '/subscriptions/activate-free-plan';

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

  // JobMatch
  static const jobMatchFeed = '/candidate/jobmatch/feed';
  static String jobMatchSwipe(int jobId) => '/candidate/jobmatch/jobs/$jobId/swipe';
  static const jobMatchMatches = '/candidate/jobmatch/matches';
  static const jobMatchLiked = '/candidate/jobmatch/liked';
  static const jobMatchSummary = '/candidate/jobmatch/summary';
}
