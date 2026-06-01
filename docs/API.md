# 📡 API Documentation - KART Backend

**Base URL** : `https://backend.kart.business/api`  
**Storage URL** : `https://backend.kart.business/storage`  
**Protocol** : REST + JSON  
**Authentication** : JWT Bearer Token  
**Version** : 1.0

---

## 🔑 Authentication Overview

### Token format

```
Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token lifecycle

```
POST /auth/login → receives access_token
    ↓
Add to request headers: Authorization: Bearer {token}
    ↓
Each request includes token
    ↓
Token expires (typically 1-24 hours)
    ↓
Receive 401 Unauthorized
    ↓
Call refresh endpoint (if available)
    ↓
Retry original request with new token
    ↓
If refresh fails → Logout user
```

---

## 👤 Authentication Endpoints

### 1. Login

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response 200 OK:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

**Response 401 Unauthorized:**
```json
{
  "message": "The provided credentials are incorrect."
}
```

**Response 422 Unprocessable Entity:**
```json
{
  "message": "The email field is required.",
  "errors": {
    "email": ["The email field is required."]
  }
}
```

### Implementation (Flutter)

```dart
// features/auth/data/auth_api.dart
Future<Response> login(String email, String password) {
  return ApiClient.dio.post(
    ApiEndpoints.login,
    data: {
      'email': email,
      'password': password,
    },
  );
}

// features/auth/providers/auth_provider.dart
Future<void> login(String email, String password) async {
  try {
    final response = await _api.login(email, password);
    final token = response.data['access_token'];
    await ApiClient.setToken(token);
    await loadMe();  // Load user data
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      error = 'Email ou mot de passe incorrect';
    }
  }
}
```

---

### 2. Register

```http
POST /auth/register
Content-Type: application/json

{
  "firstname": "Jean",
  "lastname": "Dupont",
  "phone": "+33612345678",
  "email": "jean@example.com",
  "password": "securePassword123",
  "password_confirmation": "securePassword123",
  "role": "user"
}
```

**Response 201 Created:**
```json
{
  "message": "Account created successfully",
  "user": {
    "id": 1,
    "firstname": "Jean",
    "lastname": "Dupont",
    "email": "jean@example.com",
    "phone": "+33612345678"
  }
}
```

**Response 422 Validation Error:**
```json
{
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

### Implementation

```dart
Future<void> register({
  required String firstname,
  required String lastname,
  required String phone,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  await _api.register({
    'firstname': firstname,
    'lastname': lastname,
    'phone': phone,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
    'role': 'user',
  });
  
  // Auto-login after registration
  await login(email, password);
}
```

---

### 3. Google OAuth

```http
POST /auth/google/token
Content-Type: application/json

{
  "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjEifQ..."
}
```

**Response 200 OK:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "is_new_user": false,
  "user": {
    "id": 5,
    "firstname": "Marie",
    "email": "marie@gmail.com",
    "avatar": "https://lh3.googleusercontent.com/..."
  }
}
```

### Implementation

```dart
Future<void> loginWithGoogle() async {
  final googleUser = await _googleSignIn.signIn();
  final auth = await googleUser.authentication;
  
  final response = await _api.googleLogin(auth.idToken!);
  final token = response.data['access_token'];
  
  await ApiClient.setToken(token);
  await loadMe();
}
```

---

### 4. Get Current User

```http
GET /me
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "id": 1,
  "firstname": "Jean",
  "lastname": "Dupont",
  "email": "jean@example.com",
  "phone": "+33612345678",
  "avatar": "https://backend.kart.business/storage/avatars/1.jpg",
  "plan": "pro",
  "company_id": 2,
  "company": {
    "id": 2,
    "name": "Tech Corp",
    "logo": "https://...",
    "primary_color": "#3B82F6",
    "card_theme": "modern",
    "branding_enabled": true,
    "max_users": 10,
    "is_active": true
  }
}
```

### Implementation

```dart
Future<void> loadMe() async {
  try {
    final response = await _api.me();
    user = User.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      await logout();  // Token invalide
    }
  }
}
```

---

### 5. Update Profile

```http
PUT /me
Authorization: Bearer {token}
Content-Type: application/json

{
  "firstname": "Jean",
  "lastname": "Dupont",
  "phone": "+33612345678",
  "email": "jean.new@example.com",
  "password": "newPassword123",
  "password_confirmation": "newPassword123"
}
```

**Response 200 OK:**
```json
{
  "message": "Profile updated successfully",
  "user": { ... }
}
```

---

## 💳 Plans API

### Get all plans

```http
GET /plans
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
[
  {
    "id": 1,
    "name": "Free",
    "slug": "free",
    "price": 0,
    "currency": "XOF",
    "billing_cycle": "monthly",
    "features": {
      "max_contacts": 50,
      "max_cards": 1,
      "analytics": false
    }
  },
  {
    "id": 2,
    "name": "Pro",
    "slug": "pro",
    "price": 4990,
    "currency": "XOF",
    "billing_cycle": "monthly",
    "features": {
      "max_contacts": 500,
      "max_cards": 5,
      "analytics": true
    }
  }
]
```

### Implementation

```dart
class PlanProvider extends ChangeNotifier {
  Future<void> loadPlans() async {
    try {
      plans = await _service.fetchPlans();
    } catch (e) {
      error = 'Unable to load plans';
    }
    notifyListeners();
  }
}
```

---

## 💰 Payment Endpoints

### Get payment methods

```http
GET /payments/methods
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "methods": [
    {
      "id": "stripe",
      "name": "Credit Card",
      "icon": "credit_card"
    },
    {
      "id": "wave",
      "name": "Wave Money",
      "icon": "wave"
    }
  ]
}
```

---

### Initialize payment

```http
POST /payments/initialize
Authorization: Bearer {token}
Content-Type: application/json

{
  "plan_id": 2,
  "payment_method": "stripe"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "reference": "PAY_20260518_12345",
  "payment_url": "https://checkout.stripe.com/pay/pcs_...",
  "plan": {
    "id": 2,
    "name": "Pro",
    "price": 4990
  }
}
```

**Flow d'intégration** :

```
1. App: POST /payments/initialize
2. Backend: Crée transaction, retourne payment_url
3. App: Ouvre WebView avec payment_url
4. WebView: Utilisateur rentre infos carte
5. Backend: Traite le paiement
6. Backend: Redirige vers confirmation URL
7. App: Détecte redirection, vérifie statut
```

### Implementation

```dart
class PaymentProvider extends ChangeNotifier {
  Future<void> initializePayment(int planId) async {
    final result = await _service.initializePayment(
      planId: planId,
      paymentMethod: 'stripe',
    );
    
    if (result.success) {
      // Ouvrir WebView
      final webViewController = WebViewController();
      await webViewController.loadRequest(
        Uri.parse(result.paymentUrl!),
      );
    }
  }
}
```

---

### Check payment status

```http
GET /payments/{reference}/status
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "payment": {
    "reference": "PAY_20260518_12345",
    "status": "successful",
    "amount": 4990,
    "currency": "XOF",
    "payment_method": "stripe",
    "plan": {
      "id": 2,
      "name": "Pro"
    },
    "paid_at": "2026-05-18T10:30:00Z"
  }
}
```

**Statuts possibles** :
- `pending` - En attente
- `successful` - Paiement validé
- `failed` - Paiement échoué

---

### Payment history

```http
GET /payments/history?page=1
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "data": [
    {
      "reference": "PAY_20260518_12345",
      "status": "successful",
      "amount": 4990,
      "currency": "XOF",
      "paid_at": "2026-05-18T10:30:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total": 5,
    "per_page": 15
  }
}
```

---

## 🎴 Digital Card Endpoints

### Get card summary

```http
GET /me/card
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "card": {
    "id": 1,
    "user_id": 1,
    "slug": "jean-dupont-xyz123",
    "share_url": "https://kart.business/jean-dupont-xyz123",
    "qr_code_svg": "<svg>...</svg>",
    "theme": "modern",
    "job_title": "Software Engineer",
    "company": "Tech Corp",
    "phone": "+33612345678",
    "email": "jean@example.com",
    "website": "https://jean-dupont.com",
    "linkedin": "https://linkedin.com/in/jean-dupont",
    "twitter": "https://twitter.com/jeandupont",
    "instagram": "https://instagram.com/jeandupont",
    "facebook": "https://facebook.com/jean.dupont",
    "github": "https://github.com/jeandupont",
    "experiences": [
      {
        "title": "Senior Engineer",
        "company": "Tech Corp",
        "start_date": "2020-01",
        "end_date": null,
        "description": "Leading the mobile team..."
      }
    ],
    "educations": [
      {
        "school": "University of Tech",
        "degree": "Master's",
        "field": "Computer Science",
        "start_year": 2016,
        "end_year": 2018
      }
    ],
    "scan_count": 145,
    "share_count": 32,
    "created_at": "2026-01-01T00:00:00Z"
  }
}
```

---

### Update card

```http
PUT /me/card
Authorization: Bearer {token}
Content-Type: application/json

{
  "job_title": "Lead Engineer",
  "company": "Tech Corp",
  "phone": "+33612345678",
  "email": "jean@example.com",
  "website": "https://jean-dupont.com",
  "linkedin": "https://linkedin.com/in/jean-dupont",
  "theme": "minimalist",
  "experiences": [
    {
      "title": "Senior Engineer",
      "company": "Tech Corp",
      "start_date": "2020-01",
      "end_date": null,
      "description": "Leading the mobile team"
    }
  ]
}
```

---

### Change card theme

```http
PUT /me/card/theme
Authorization: Bearer {token}
Content-Type: application/json

{
  "theme": "modern"
}
```

**Thèmes disponibles** :
- `modern` - Design contemporain
- `minimalist` - Épuré et simple
- `premium` - Luxe et sophistiqué
- `corporate` - Professionnel classique
- `creative` - Coloré et dynamique

---

## 📇 Card Scanner Endpoints

### Submit scanned card

```http
POST /card-scan
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "image": <binary image>,
  "auto_extract": true
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "extracted_data": {
    "fullname": "Marie Martin",
    "email": "marie.martin@company.com",
    "phone": "+33612345678",
    "company": "Marketing Inc",
    "job": "Marketing Manager",
    "website": "https://company.com",
    "linkedin": "https://linkedin.com/in/marie-martin"
  },
  "confidence_score": 0.89
}
```

**Response 422 Invalid image:**
```json
{
  "success": false,
  "error": "Unable to extract data from image"
}
```

---

## 👥 Contacts Endpoints

### Get contacts (grouped)

```http
GET /contacts?group_by=company&sort=name
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "data": [
    {
      "company": "Tech Corp",
      "contacts": [
        {
          "id": 1,
          "fullname": "Marie Martin",
          "email": "marie@company.com",
          "phone": "+33612345678",
          "job": "Manager",
          "card_slug": "marie-martin-xyz"
        }
      ]
    }
  ]
}
```

---

### Search contacts

```http
GET /contacts/search?q=marie&limit=10
Authorization: Bearer {token}
```

---

### Delete contact

```http
DELETE /contacts/{id}
Authorization: Bearer {token}
```

**Response 204 No Content**

---

## 📊 Leads Endpoints

### Get leads

```http
GET /leads?page=1&limit=20
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "data": [
    {
      "id": 1,
      "contact_id": 5,
      "type": "share",
      "contact_name": "Jean Dupont",
      "shared_at": "2026-05-18T10:30:00Z"
    }
  ],
  "pagination": {
    "total": 45,
    "per_page": 20,
    "current_page": 1
  }
}
```

---

### Get analytics

```http
GET /me/analytics
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "total_scans": 245,
  "total_shares": 67,
  "unique_contacts": 45,
  "monthly_stats": [
    {
      "month": "2026-05",
      "scans": 89,
      "shares": 23
    }
  ]
}
```

---

## 🏢 Company Endpoints

### Create company

```http
POST /company
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Tech Corp",
  "logo": "https://...",
  "primary_color": "#3B82F6",
  "secondary_color": "#10B981",
  "card_theme": "modern",
  "max_users": 10
}
```

---

### Join company

```http
POST /company/join
Authorization: Bearer {token}
Content-Type: application/json

{
  "code": "COMPANY_INVITE_CODE_XYZ"
}
```

---

## 🔄 Complete Request/Response Flow Example

### Scenario: User login → view card → share card

```
Step 1: LOGIN
POST /auth/login
Request: { email: "user@example.com", password: "..." }
Response: { access_token: "token123" }

Step 2: GET CURRENT USER
GET /me
Headers: Authorization: Bearer token123
Response: { user data with company... }

Step 3: GET CARD
GET /me/card
Headers: Authorization: Bearer token123
Response: { card with QR code SVG, themes, stats }

Step 4: SHARE (tracked server-side)
App records share event locally
Optional: POST /leads (track externally)

Step 5: PAYMENT FLOW
POST /payments/initialize { plan_id, method }
Response: { payment_url }
App opens WebView with payment_url
User completes payment
Backend redirects to app
App verifies payment status
```

---

## ⚠️ Error Handling

### Standard error format

```json
{
  "message": "Error description",
  "errors": {
    "field_name": ["Error message for field"]
  }
}
```

### HTTP Status codes

| Code | Meaning | Handling |
|------|---------|----------|
| 200 | OK | Success |
| 201 | Created | Resource created |
| 204 | No Content | Success, no response body |
| 400 | Bad Request | Invalid request format |
| 401 | Unauthorized | Token invalid/expired |
| 403 | Forbidden | Not allowed |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limited |
| 500 | Internal Server Error | Server error |

### Implementation

```dart
Future<T> handleResponse<T>(Response response) {
  if (response.statusCode == 401) {
    // Token expiré - logout
  } else if (response.statusCode == 422) {
    // Validation errors
  } else if (response.statusCode! >= 500) {
    // Server error
  }
}
```

---

## 🔐 API Security

### Headers requis

```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

### HTTPS only
- Tous les appels doivent être en HTTPS
- Certificate pinning recommandé (optional)

### Rate limiting
- Typiquement 100 requests/minute
- Headers de rateLimit dans les responses

### Token validation
- Format: JWT Bearer token
- Expiration: 3600 secondes (1 heure)
- Refresh token disponible si implémenté

---

## 📋 API Endpoints Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/auth/login` | POST | ❌ | Login |
| `/auth/register` | POST | ❌ | Register |
| `/auth/google/token` | POST | ❌ | Google OAuth |
| `/me` | GET | ✅ | Get current user |
| `/me` | PUT | ✅ | Update profile |
| `/plans` | GET | ✅ | Get plans |
| `/payments/methods` | GET | ✅ | Get payment methods |
| `/payments/initialize` | POST | ✅ | Initialize payment |
| `/payments/{ref}/status` | GET | ✅ | Check status |
| `/payments/history` | GET | ✅ | Payment history |
| `/me/card` | GET | ✅ | Get card |
| `/me/card` | PUT | ✅ | Update card |
| `/me/card/theme` | PUT | ✅ | Change theme |
| `/card-scan` | POST | ✅ | Submit scanned card |
| `/contacts` | GET | ✅ | Get contacts |
| `/contacts/search` | GET | ✅ | Search |
| `/contacts/{id}` | DELETE | ✅ | Delete |
| `/leads` | GET | ✅ | Get leads |
| `/me/analytics` | GET | ✅ | Get analytics |
| `/company` | POST | ✅ | Create company |
| `/company/join` | POST | ✅ | Join company |

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : API Team  
**Status** : ✅ Complet
