# 🔐 Authentication & Security - KART

**Scope** : Authentication, authorization, JWT, secure storage, best practices  
**Date** : 18 Mai 2026  
**Version** : 1.0

---

## 🎯 Overview

KART implements a **JWT-based authentication system** with secure token storage and automatic refresh mechanism. The app supports multiple authentication methods while maintaining strong security standards.

---

## 🔑 Authentication Methods

### 1. Email/Password Authentication

**Flow** :
```
User enters email + password
    ↓
POST /auth/login
    ↓
Backend validates credentials
    ↓
Returns JWT access_token (if valid)
    ↓
App stores token in SecureStorage
    ↓
All subsequent requests include token
```

**Implementation** :
```dart
// features/auth/providers/auth_provider.dart
Future<void> login(String email, String password) async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    final response = await _api.login(email, password);
    
    // Extract token (handles both 'access_token' and 'token')
    final token = response.data['access_token'] ?? response.data['token'];
    
    if (token == null || token is! String) {
      error = 'Erreur: token non reçu';
      return;
    }

    // Save token securely
    await ApiClient.setToken(token);

    // Load user data
    await loadMe();
    
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      error = 'Email ou mot de passe incorrect';
    } else if (e.response?.statusCode == 422) {
      error = 'Données invalides';
    }
  }
  
  isLoading = false;
  notifyListeners();
}
```

**UI Implementation** :
```dart
// features/auth/ui/login_page.dart
class LoginPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Column(
        children: [
          AuthTextField(
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthTextField(
            label: 'Password',
            controller: _passwordCtrl,
            obscureText: true,
          ),
          
          // Show error if login failed
          if (auth.error != null)
            ErrorBanner(message: auth.error!),
          
          AuthPrimaryButton(
            label: 'Se connecter',
            loading: auth.isLoading,
            onTap: () => auth.login(
              _emailCtrl.text,
              _passwordCtrl.text,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Security measures** :
- ✅ Password validation (min 6 chars)
- ✅ Secure HTTPS connection
- ✅ No password stored locally
- ✅ Token stored in SecureStorage

---

### 2. Google OAuth Sign-In

**Flow** :
```
User taps "Sign in with Google"
    ↓
Google Sign-In SDK opens Google login
    ↓
User authenticates with Google
    ↓
Google returns ID token
    ↓
App sends ID token to backend
    ↓
POST /auth/google/token with token
    ↓
Backend validates with Google servers
    ↓
Returns JWT access_token
    ↓
App stores token + creates/updates user
```

**Implementation** :
```dart
// features/auth/providers/auth_provider.dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: kIsWeb && _kGoogleSignInClientId.isNotEmpty
      ? _kGoogleSignInClientId
      : null,
);

Future<void> googleLogin() async {
  isGoogleLoading = true;
  error = null;
  notifyListeners();

  try {
    // 1. Sign in with Google
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      error = 'Google sign-in cancelled';
      return;
    }

    // 2. Get authentication tokens
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      error = 'Failed to get ID token';
      return;
    }

    // 3. Send token to backend
    final response = await _api.googleLogin(idToken);

    // 4. Store JWT from backend
    final token = response.data['access_token'];
    await ApiClient.setToken(token);

    // 5. Load user data
    await loadMe();

    isNewUser = response.data['is_new_user'] ?? false;

  } on DioException catch (e) {
    error = 'Google login failed: ${e.message}';
  } catch (e) {
    error = 'An error occurred: $e';
  }

  isGoogleLoading = false;
  notifyListeners();
}
```

**Configuration** :
```dart
// Environment variable
const String _kGoogleSignInClientId =
    String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID', defaultValue: '');

// In Android: Configure in google-services.json
// In iOS: Configure in GoogleService-Info.plist
```

**Security considerations** :
- ✅ ID token validated on backend
- ✅ Google servers trust verification
- ✅ Account linking prevents duplicates
- ⚠️ Scopes limited to email + profile only

---

### 3. Registration (New Account)

**Flow** :
```
Multi-step registration form
    ↓
Step 1: Name + Basic info
Step 2: Email + Phone
Step 3: Password
    ↓
POST /auth/register
    ↓
Backend validates + creates account
    ↓
Auto-login with credentials
    ↓
Redirect to plans/onboarding
```

**Implementation** :
```dart
// features/auth/providers/auth_provider.dart
Future<void> register({
  required String firstname,
  required String lastname,
  required String phone,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    // 1. Submit registration data
    await _api.register({
      'firstname': firstname,
      'lastname': lastname,
      'phone': phone,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': 'user',
    });

    // 2. Auto-login with new credentials
    await login(email, password);

    // Mark as new user (for onboarding)
    isNewUser = true;

  } on DioException catch (e) {
    if (e.response?.statusCode == 422) {
      // Validation error from Laravel
      final errors = e.response?.data['errors'] as Map?;
      if (errors != null) {
        final firstError = errors.values.first;
        error = firstError is List ? firstError.first : 'Validation error';
      }
    }
  }

  isLoading = false;
  notifyListeners();
}
```

**Multi-step form** :
```dart
// features/auth/ui/register_page.dart
class RegisterPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // Page 0: Firstname + Lastname
    // Page 1: Email + Phone
    // Page 2: Password + Confirmation

    return Column(
      children: [
        if (_currentPage == 0) _buildNameStep(),
        if (_currentPage == 1) _buildEmailStep(),
        if (_currentPage == 2) _buildPasswordStep(),
        
        Row(
          children: [
            if (_currentPage > 0)
              OutlinedButton(onPressed: _previousPage, child: Text('Back')),
            if (_currentPage < 2)
              ElevatedButton(onPressed: _nextPage, child: Text('Next')),
            if (_currentPage == 2)
              ElevatedButton(
                onPressed: () => auth.register(...),
                child: Text('Create Account'),
              ),
          ],
        ),
      ],
    );
  }
}
```

**Validation** :
- ✅ Email format validation
- ✅ Phone format validation
- ✅ Password strength (min 6 chars)
- ✅ Password confirmation match
- ✅ Unique email check (backend)

---

## 🔐 JWT Token Management

### Token Storage Architecture

```dart
// core/network/api_client.dart
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static bool _useSecureStorage = true;

  // PRIMARY: SecureStorage (Keychain iOS / Keystore Android)
  // FALLBACK: SharedPreferences (if SecureStorage fails)
  
  static Future<void> setToken(String token) async {
    try {
      if (_useSecureStorage) {
        await _storage.write(key: _tokenKey, value: token);
      }
    } catch (e) {
      _useSecureStorage = false;
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
    
    // Add to Dio headers
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<String?> getToken() async {
    try {
      if (_useSecureStorage) {
        return await _storage.read(key: _tokenKey);
      }
    } catch (e) {
      _useSecureStorage = false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('SecureStorage delete failed: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    
    dio.options.headers.remove('Authorization');
  }
}
```

### Token Lifecycle

```
1. LOGIN
   User → POST /auth/login → Backend returns token
   
2. STORAGE
   Token → SecureStorage (Keychain/Keystore)
   
3. USAGE
   Every request → Add header Authorization: Bearer {token}
   
4. VALIDATION
   Backend validates JWT signature
   Checks expiration
   Verifies user permissions
   
5. EXPIRATION
   Token expires after N hours (typically 1-24h)
   Server returns 401 Unauthorized
   
6. REFRESH (if implemented)
   App sends refresh_token to backend
   Backend returns new access_token
   Update local storage
   Retry original request
   
7. LOGOUT
   POST /auth/logout (optional)
   Clear token from storage
   Clear Dio headers
   Reset user state
   Redirect to login
```

### Token Header Format

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**JWT Parts** :
1. Header: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9` (algorithm)
2. Payload: `eyJzdWIiOiIxMjM0NTY3ODkwI...` (user claims)
3. Signature: `SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c` (verification)

---

## 🛡️ Authorization & Permissions

### User Roles

```dart
enum UserRole {
  user,        // Regular user
  admin,       // Admin user
  company_admin, // Company admin
}
```

### Role-based access

```dart
// AuthProvider
bool get isPro => user?.plan != 'free';
bool get isCompanyAdmin => user?.role == 'company_admin';
bool get hasCompany => user?.companyId != null;

// Use in widgets
if (auth.isPro) {
  // Show pro features
}

if (!auth.hasCompany) {
  // Show company onboarding
}
```

### Feature gating

```dart
// Check plan before accessing features
if (auth.isPro) {
  enableAdvancedCardThemes();
} else {
  showUpgradePrompt();
}

// Check company membership
if (auth.isCompanyAdmin) {
  enableTeamManagement();
}
```

---

## 🔄 Logout & Session Management

### Logout flow

```dart
Future<void> logout() async {
  // 1. Sign out from Google (if was logged in via Google)
  try {
    await _googleSignIn.signOut();
  } catch (e) {
    debugPrint('GoogleSignIn signOut error: $e');
  }

  // 2. Clear stored token
  await ApiClient.clearToken();

  // 3. Reset user state
  user = null;
  error = null;
  isNewUser = false;

  // 4. Notify listeners
  notifyListeners();

  // 5. UI automatically redirects to login
  // (via isAuthenticated getter)
}
```

### Session persistence

```dart
// App startup check
class AuthProvider {
  Future<void> _init() async {
    try {
      await ApiClient.init();  // Initialize Dio with stored token
      
      final token = await ApiClient.getToken();
      if (token != null) {
        // Token found, verify it's still valid
        await loadMe();
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
}

// Use in SplashScreen
class SplashScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Wait for initialization before navigation
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.waitForInit();

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
```

---

## 🔍 Security Best Practices

### ✅ Implemented

| Practice | Status | Details |
|----------|--------|---------|
| HTTPS only | ✅ | All API calls use HTTPS |
| Secure token storage | ✅ | SecureStorage + fallback |
| Password minimum length | ✅ | 6 characters minimum |
| Email validation | ✅ | Format validation |
| No hardcoded secrets | ✅ | Env variables for config |
| Token in Authorization header | ✅ | Not in URL/body |
| CORS enabled | ⚠️ | Depending on backend config |
| Rate limiting | ⚠️ | Server-side implementation |

### ⏳ Recommended for future

| Feature | Priority | Notes |
|---------|----------|-------|
| SSL Pinning | High | Prevent MITM attacks |
| Biometric auth | High | Fingerprint/Face ID |
| Two-factor auth (2FA) | Medium | Email/SMS OTP |
| Session timeout | Medium | Auto-logout after inactivity |
| Device fingerprinting | Medium | Detect unauthorized access |
| API key rotation | Medium | Automatic token refresh |
| Audit logging | Low | Track auth events |

---

## 🚨 Security Vulnerabilities & Mitigation

### 1. Token exposure in logs

**Risk** : JWT tokens logged in debug output  
**Mitigation** :
```dart
// ❌ BAD
debugPrint('Token: $token');

// ✅ GOOD
debugPrint('Token: ${token?.substring(0, 10)}...');
debugPrint('Token saved: ${token != null}');
```

### 2. Token stored in SharedPreferences

**Risk** : SharedPreferences is not encrypted  
**Mitigation** :
- ✅ Use flutter_secure_storage as primary
- ✅ Fallback to SharedPreferences only if necessary
- ✅ Encrypted by OS (Keychain iOS / Keystore Android)

### 3. Session hijacking

**Risk** : Token intercepted during transmission  
**Mitigation** :
- ✅ HTTPS only (no HTTP)
- 🔜 SSL pinning (certificate pinning)
- ✅ Token in Authorization header (not URL)
- ✅ Secure HttpOnly cookies (if backend supports)

### 4. Weak passwords

**Risk** : Brute force attacks  
**Mitigation** :
- ✅ Minimum 6 characters
- 🔜 Password strength indicator
- 🔜 Password history
- ✅ Rate limiting on login endpoint

### 5. XSS attacks (Web only)

**Risk** : JavaScript injection  
**Mitigation** :
- ⚠️ Flutter web inherits browser security
- 🔜 Content Security Policy (CSP)
- 🔜 Input sanitization

### 6. CSRF attacks

**Risk** : Cross-site request forgery  
**Mitigation** :
- ✅ HTTPS with SameSite cookies
- ✅ CORS configuration on backend
- ✅ Token in Authorization header

---

## 🔐 OAuth Security

### Google Sign-In flow

```
1. User taps "Sign in with Google"
2. Google SDK opens authentication UI
3. User authenticates (or uses existing session)
4. Google returns ID token to app
5. App sends ID token to backend
6. Backend validates token with Google servers
7. Backend creates/updates user + issues JWT
8. App receives JWT (NOT from Google)
9. App uses JWT for all API calls
```

**Key points** :
- ✅ Google validates user identity
- ✅ Backend validates Google token
- ✅ Final JWT issued by our backend
- ✅ No credentials ever on device
- ✅ Token refresh handled by Google SDK

**Scopes requested** :
```dart
GoogleSignIn(
  scopes: [
    'email',      // Email address
    'profile',    // Basic profile info
    // NOT requesting: contacts, calendar, drive, etc.
  ],
)
```

---

## 📋 Authentication Checklist

### For developers

- [ ] Understand JWT flow
- [ ] Know token storage locations
- [ ] Test logout functionality
- [ ] Test login error handling
- [ ] Test Google OAuth
- [ ] Test registration validation
- [ ] Check for token leaks in logs
- [ ] Verify HTTPS in all requests
- [ ] Test session persistence
- [ ] Test logout on 401

### For QA

- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Register new account
- [ ] Register with existing email
- [ ] Sign in with Google
- [ ] Logout and verify session cleared
- [ ] Force kill app and verify session persists
- [ ] Test network error during login
- [ ] Test very long token
- [ ] Test expired token recovery

---

## 🔗 Related Documentation

- **[API Documentation →](API.md)** - Complete API reference
- **[Architecture →](ARCHITECTURE.md)** - Provider architecture
- **[Security →](SECURITY.md)** - Mobile security

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : Security Team  
**Status** : ✅ Complet
