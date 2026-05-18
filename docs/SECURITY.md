# 🛡️ Mobile Security - KART

**Focus** : Security vulnerabilities, mitigation, best practices  
**Date** : 18 Mai 2026  
**Version** : 1.0

---

## 🎯 Security Overview

KART is a mobile application handling sensitive user data:
- Personal information (name, email, phone)
- Professional data (job, company, experience)
- Digital cards (shareable but controlled)
- Contact lists
- Payment information (via 3rd party)

---

## 🔐 Current Security Measures

### ✅ Implemented

| Area | Measure | Status |
|------|---------|--------|
| **Communication** | HTTPS only | ✅ |
| **Storage** | SecureStorage for tokens | ✅ |
| **Authentication** | JWT with expiration | ✅ |
| **Validation** | Input validation | ✅ |
| **Sessions** | Logout on 401 | ✅ |
| **Logs** | No sensitive data logged | ✅ |
| **Code** | No hardcoded secrets | ✅ |

### ⏳ Recommended for future

| Feature | Priority | Timeline |
|---------|----------|----------|
| SSL Certificate Pinning | High | 3-6 months |
| Biometric Authentication | High | 3-6 months |
| App Attestation (Android) | High | 6+ months |
| Two-Factor Authentication | Medium | 6+ months |
| Device Fingerprinting | Medium | 6+ months |
| Advanced Rate Limiting | Medium | 6+ months |

---

## 🚨 Security Vulnerabilities & Risks

### 1. Token Exposure

**Risk Level** : HIGH  
**Description** : JWT token exposed in logs or network traffic

**Current Mitigation** :
- ✅ HTTPS enforced (no HTTP fallback)
- ✅ Token in Authorization header (not URL)
- ✅ SecureStorage encryption (Keychain iOS / Keystore Android)
- ✅ No token logged in debug output

**Recommended** :
```dart
// ❌ BAD
debugPrint('Token: $token');

// ✅ GOOD
debugPrint('Token saved successfully');
debugPrint('Token: ${token.substring(0, 10)}...');
```

---

### 2. Man-in-the-Middle (MITM) Attack

**Risk Level** : HIGH  
**Description** : Attacker intercepts HTTPS traffic

**Current Mitigation** :
- ✅ HTTPS enforced
- ✅ TLS 1.2+ required

**Recommended** :
```dart
// Implement Certificate Pinning
class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
    ),
  )..httpClientAdapter = CertificatePinningHttpClientAdapter(
    allowBadCertificates: false,
    certVerifier: CertVerifier(
      'backend.kart.business',
      {
        '/path/to/certificate.pem': SHA256Certificate(certificateHash),
      },
    ),
  );
}
```

---

### 3. Insecure Storage

**Risk Level** : MEDIUM  
**Description** : JWT stored in SharedPreferences (unencrypted)

**Current Mitigation** :
- ✅ Primary: flutter_secure_storage (encrypted)
- ⚠️ Fallback: SharedPreferences (only if SecureStorage fails)

**Recommended** :
- Use SecureStorage only, no fallback to SharedPreferences
- Or: Encrypt SharedPreferences data manually

---

### 4. Reverse Engineering

**Risk Level** : MEDIUM  
**Description** : App binary analyzed to extract logic/secrets

**Current Mitigation** :
- ✅ ProGuard/R8 minification enabled
- ✅ No hardcoded API keys
- ✅ Secrets in environment variables

**Recommended** :
```gradle
// build.gradle (already configured)
release {
  minifyEnabled true
  shrinkResources true
  proguardFiles getDefaultProguardFile('proguard-android.txt')
}
```

---

### 5. Weak Password

**Risk Level** : MEDIUM  
**Description** : Brute force attack on login

**Current Mitigation** :
- ✅ Minimum 6 characters
- ✅ Server-side rate limiting (3 attempts / 15 mins recommended)

**Recommended** :
```dart
// Client-side validation
bool isStrongPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&  // Uppercase
      RegExp(r'[0-9]').hasMatch(password) &&  // Number
      RegExp(r'[!@#$%^&*]').hasMatch(password);  // Special char
}
```

---

### 6. Insecure API Endpoints

**Risk Level** : MEDIUM  
**Description** : Sensitive data exposed via unprotected API

**Current Mitigation** :
- ✅ All endpoints require JWT
- ✅ User can only access their own data
- ✅ Backend validates permissions

**Example safe endpoint** :
```
GET /me
- Returns only current user data
- Cannot be called by another user
- Returns 401 if token invalid
```

---

### 7. Hardcoded Credentials

**Risk Level** : HIGH  
**Description** : API keys, secrets in source code

**Current Mitigation** :
- ✅ Google Sign-In client ID via environment variable
- ✅ API endpoints dynamic
- ✅ No password hardcoded

---

### 8. Lack of Certificate Pinning

**Risk Level** : MEDIUM  
**Description** : Compromised CA certificate could intercept traffic

**Current Mitigation** :
- ✅ HTTPS only

**Recommended** :
```dart
// Pin specific certificate
final certificatePin = 'pin-sha256/AAAAAAAAAAAAAAAAAAAAAA==';

SecurityContext sc = new SecurityContext.defaultContext;
sc.usePrivateKeyBytes(keyBytes);
sc.useCertificateChainBytes(certChainBytes);
```

---

### 9. Insecure Permission Handling

**Risk Level** : LOW  
**Description** : Requesting more permissions than needed

**Current Permissions** :
- ✅ INTERNET : For API calls
- ✅ CAMERA : For card scanning
- ⏳ LOCATION : Not used (don't request)
- ⏳ CONTACTS : Not used (don't request)
- ⏳ MICROPHONE : Not used (don't request)

---

### 10. Lack of Biometric Authentication

**Risk Level** : LOW  
**Description** : Device stolen → access to account

**Recommended** :
```dart
import 'package:local_auth/local_auth.dart';

Future<bool> authenticateWithBiometrics() async {
  final auth = LocalAuthentication();
  try {
    return await auth.authenticate(
      localizedReason: 'Authenticate to access your card',
      options: AuthenticationOptions(
        stickyAuth: true,
      ),
    );
  } catch (e) {
    return false;
  }
}
```

---

## 🔒 Data Protection

### Sensitive Data Classification

```
🔴 CRITICAL
- JWT tokens
- Password (never stored)
- Credit card info (3rd party only)

🟠 HIGH
- User email
- User phone
- Contact list
- Payment history

🟡 MEDIUM
- User profile data
- Card preferences
- Analytics data

🟢 LOW
- Theme settings
- Language preference
- Public card data
```

### Encryption Standards

```dart
// Encryption at rest (SecureStorage handles this)
// Encryption in transit (HTTPS/TLS 1.2+)
// No sensitive data in logs

// If adding local database
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

final db = await openDatabase(
  'kart_db.db',
  password: 'encryption-key',  // Enable encryption
);
```

---

## 🧪 Security Testing

### OWASP Top 10 Mobile Risks Check

| Risk | Status | Evidence |
|------|--------|----------|
| Improper Platform Usage | ✅ Safe | Using Flutter best practices |
| Insecure Data Storage | ✅ Safe | SecureStorage for tokens |
| Insecure Communication | ✅ Safe | HTTPS enforced |
| Insecure Authentication | ✅ Safe | JWT + device storage |
| Insufficient Cryptography | ⚠️ Medium | No certificate pinning yet |
| Insecure Authorization | ✅ Safe | Server-side permission checks |
| Client Code Quality | ✅ Safe | No eval() or dynamic code |
| Code Tampering | ✅ Safe | ProGuard/R8 enabled |
| Reverse Engineering | ✅ Safe | Minified, no secrets |
| Extraneous Functionality | ✅ Safe | No debug backdoors |

---

## 🔐 Authentication Security

### JWT Security

```dart
// Token structure validation
class JwtValidator {
  static Map<String, dynamic>? parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = utf8.decode(base64Url.decode(
        base64Url.normalize(parts[1]),
      ));
      return jsonDecode(payload);
    } catch (e) {
      return null;
    }
  }

  // Check expiration
  static bool isTokenExpired(String token) {
    final decoded = parseJwt(token);
    if (decoded == null) return true;

    final exp = decoded['exp'] as int?;
    if (exp == null) return true;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
        .isBefore(DateTime.now());
  }
}
```

---

## 🛡️ API Security Recommendations

### Rate Limiting (Server-side)

```
POST /auth/login → 3 attempts per 15 minutes
GET /contacts → 100 requests per minute
POST /card-scan → 10 uploads per hour
```

### Input Validation

```dart
// Sanitize all inputs
String sanitizeInput(String input) {
  return input
      .replaceAll('<script>', '')
      .replaceAll('javascript:', '')
      .trim();
}

// Validate email format
bool isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      .hasMatch(email);
}

// Validate phone format
bool isValidPhone(String phone) {
  return RegExp(r'^\+?[0-9\s-()]{10,}$').hasMatch(phone);
}
```

---

## 📋 Security Checklist

### For Developers

- [ ] No hardcoded secrets in code
- [ ] HTTPS only (verify in Dio config)
- [ ] Input validation on all forms
- [ ] Proper error messages (no oversharing)
- [ ] No sensitive data in logs
- [ ] Dispose all resources properly
- [ ] Validate all API responses
- [ ] Test on public networks (security concern)
- [ ] Use strong parameter names
- [ ] Review third-party dependencies

### For DevOps

- [ ] HTTPS certificate valid
- [ ] TLS 1.2+ enforced
- [ ] CORS configured correctly
- [ ] Rate limiting enabled
- [ ] WAF (Web Application Firewall) enabled
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS protection headers
- [ ] CSRF tokens on state-changing endpoints
- [ ] Regular security audits
- [ ] Penetration testing

### For QA

- [ ] Test login with weak password
- [ ] Test with wrong credentials
- [ ] Test with SQL injection attempts
- [ ] Test with XSS payloads
- [ ] Test on public WiFi
- [ ] Test with proxy (Charles/Fiddler)
- [ ] Force logout and verify no data leak
- [ ] Test with rooted device
- [ ] Test with burp suite
- [ ] Check permissions on device

---

## 🚀 Security Incident Response

### If JWT is compromised

```
1. Revoke token immediately
2. Force user logout
3. Send notification email
4. Force password reset
5. Audit account access
```

### If app version is exploited

```
1. Release patched version
2. Mark old version as vulnerable in backend
3. Force users to update
4. Monitor for abuse
5. Document incident
```

---

## 📚 Security Resources

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/json)
- [Android Security](https://developer.android.com/training/articles/security-tips)
- [iOS Security](https://developer.apple.com/security/)

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : Security Team  
**Status** : ✅ Audité
