# 🎨 UI Components & Screens - KART

**Scope** : Widgets, screens, navigation, responsive design  
**Date** : 18 Mai 2026  
**Version** : 1.0

---

## 🏗️ Component Architecture

```
UI Layer
├── Screens (Pages)
│   ├── SplashScreen
│   ├── LoginPage
│   ├── RegisterPage
│   ├── HomeShell
│   └── Feature screens
├── Widgets (Reusable)
│   ├── Auth components
│   ├── Card widgets
│   ├── Common widgets
│   └── Custom buttons/inputs
└── Dialogs & Modals
    ├── Error dialogs
    ├── Confirmation dialogs
    └── Bottom sheets
```

---

## 🎯 Navigation Structure

### Route hierarchy

```
/ (SplashScreen)
├─ /login (LoginPage)
├─ /register (RegisterPage)
├─ /complete-profile (CompleteProfilePage)
├─ /plans (PlanSelectionPage)
├─ /onboarding
│  ├─ /onboarding-choice (OnboardingCompanyChoicePage)
│  ├─ /create-company (CreateCompanyPage)
│  └─ /join-company (JoinCompanyPage)
├─ /payment
│  ├─ /payment/plans (PlansScreen)
│  ├─ /payment/methods (PaymentMethodScreen)
│  ├─ /payment/processing (PaymentProcessingScreen)
│  └─ /payment/result (PaymentResultScreen)
├─ /card-scanner
│  ├─ /card-scanner (CardScannerScreen)
│  ├─ /card-preview (ImagePreviewScreen)
│  └─ /scan-result (ScanResultScreen)
└─ /home (HomeShell - Auth required)
   ├─ /digital-card (MyDigitalCardPage)
   ├─ /scan (ScanPage)
   ├─ /contacts (ContactsPage)
   └─ /profile (ProfilePage)
```

### Bottom navigation tabs (HomeShell)

```
HomeShell (BottomNavigationBar)
├─ Index 0: Digital Card (🎴)
│  └─ MyDigitalCardPage
│     ├─ QR code display
│     ├─ Card info
│     ├─ Analytics
│     └─ Settings
├─ Index 1: Scan (📱)
│  └─ ScanPage / CardScanSwitcherPage
│     ├─ Camera view (mobile)
│     ├─ QR scanner
│     └─ Card scanner
├─ Index 2: Contacts (👥)
│  └─ ContactsPage
│     ├─ Contact list
│     ├─ Search
│     └─ Export
└─ Index 3: Profile (👤)
   └─ ProfilePage
      ├─ User info
      ├─ Company info
      ├─ Settings
      └─ Logout
```

---

## 🎨 Shared Components Library

### Button components

#### AuthPrimaryButton
```dart
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final Color? backgroundColor;

  const AuthPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  // UI: Blue button with icon, rounded corners
  // States: enabled, disabled, loading
  // Animations: scale on press, loading spinner
}
```

**Usage** :
```dart
AuthPrimaryButton(
  label: 'Se connecter',
  icon: Icons.arrow_forward_rounded,
  loading: auth.isLoading,
  onTap: isFormValid ? () => _submit() : null,
)
```

#### AuthOutlineButton
```dart
class AuthOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  // UI: Transparent with border
}
```

---

### Input components

#### AuthTextField
```dart
class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  // UI: Glass-morphism style input
  // Features: Error handling, password visibility toggle
  // Responsive: Adjusts to keyboard
}
```

**Usage** :
```dart
AuthTextField(
  label: 'Email',
  controller: _emailCtrl,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.mail_outline_rounded,
)
```

---

### Specialized components

#### QrCard
```dart
class QrCard extends StatefulWidget {
  final String qrSvg;
  final String theme;
  final String name;
  final String jobTitle;

  // Displays QR code with animation
  // Theme support (modern, minimal, premium, etc.)
  // Share button
  // Analytics display
}
```

#### CardHeader
```dart
class CardHeader extends StatelessWidget {
  final User user;
  final Company? company;

  // Header with user avatar/info
  // Company logo if member
}
```

#### DigitalCard
```dart
class DigitalCard extends StatelessWidget {
  final CardProvider card;
  final VoidCallback? onEdit;

  // Displays full card
  // Theme styling
  // Interactive elements
}
```

#### ContactTile
```dart
class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  // Contact list item
  // Company badge
  // Quick actions
}
```

---

## 📱 Main Screens

### 1. SplashScreen

**Purpose** : App initialization, auth check  
**Flow** :
```
1. Show splash UI
2. Check if JWT token exists
3. If token exists:
   - Verify it with /me endpoint
   - If valid → Navigate to /home
   - If invalid → Navigate to /login
4. If no token:
   - Navigate to /login
```

**Implementation** :
```dart
class SplashScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.waitForInit();

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
```

---

### 2. LoginPage

**Purpose** : User login with email/password  
**Features** :
- Email + password form
- Error messages
- "Forgot password" link (optional)
- "Sign up" link
- Google Sign-In button
- Form validation

**UI Elements** :
- Brand logo
- Email TextField
- Password TextField (obscured)
- Login button (animated)
- Social login buttons
- Register link

**Animations** :
- Fade-in on load
- Slide from bottom
- Button press feedback

---

### 3. RegisterPage

**Purpose** : Multi-step account creation  
**Steps** :
1. Step 1: First name + Last name
2. Step 2: Email + Phone
3. Step 3: Password + Confirmation

**Features** :
- Progress indicator (3 steps)
- Step validation
- Next/Previous buttons
- Submit button on last step
- Error handling per step
- Auto-login after registration

---

### 4. HomeShell

**Purpose** : Main app container with bottom navigation  
**Tabs** :

```dart
class HomeShell extends StatefulWidget {
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          MyDigitalCardPage(),
          ScanPage(),
          ContactsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) {
          setState(() => _index = index);
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Ma carte'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
```

**Animations** :
- Scale animation on tab press (0.85x)
- Smooth page transitions
- Tab indicator animation

---

### 5. MyDigitalCardPage

**Purpose** : Display and manage user's digital card  
**Sections** :

1. **QR Code Display**
   - SVG QR code rendered
   - Share button
   - Copy link button

2. **Card Information**
   - User name, job title
   - Contact info (email, phone)
   - Social links
   - Company branding

3. **Theme Selector**
   - Grid of theme options
   - Live preview
   - Apply button

4. **Analytics**
   - Scan count
   - Share count
   - Last scan date
   - Chart/graph

5. **Settings**
   - Edit button
   - Visibility toggle
   - Archive/Delete

---

### 6. ScanPage

**Purpose** : QR code or business card scanning  
**Two modes** :

1. **QR Code Mode**
   - Camera view
   - Scan QR code
   - Navigate to contact's card
   - Save to contacts

2. **Card Scan Mode**
   - Camera to capture card image
   - Automatic edge detection
   - Image preview with crop
   - OCR data extraction
   - Confirm and save

---

### 7. ContactsPage

**Purpose** : View and manage scanned contacts  
**Features** :
- List of contacts
- Grouped by company
- Search functionality
- Filter by date
- Quick actions (call, email, open card)
- Delete contact
- Export to CSV
- Batch selection

**UI** :
```dart
ListView(
  children: [
    // Grouped by company
    ExpansionTile(title: 'Tech Corp'),
    ...contacts,
    ExpansionTile(title: 'Marketing Inc'),
    ...contacts,
  ],
)
```

---

### 8. ProfilePage

**Purpose** : User profile, settings, logout  
**Sections** :

1. **Profile Section**
   - Avatar
   - Name, email, phone
   - Edit button

2. **Company Section**
   - Company name, logo
   - Role
   - Members (if admin)

3. **Subscription Section**
   - Current plan badge
   - Plan details
   - Upgrade button
   - Billing info

4. **Preferences Section**
   - Theme toggle
   - Language selection
   - Notifications settings

5. **Account Section**
   - Privacy policy
   - Terms of service
   - About app
   - Version info

6. **Logout Button**
   - Confirmation dialog
   - Clear all data
   - Redirect to login

---

## 🎭 Dialog & Modal Components

### ErrorDialog
```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Erreur'),
    content: Text(auth.error!),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
)
```

### ConfirmationDialog
```dart
Future<bool> showConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required String cancelText,
}) async {
  return await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  ) ?? false;
}
```

### LoadingDialog
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => Dialog(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement...'),
        ],
      ),
    ),
  ),
)
```

---

## 🎨 Design System

### Color Palette

**Dark Theme** (Default)
```dart
// Primary
const Color darkBg = Color(0xFF0A0A0A);      // Very dark
const Color darkSurface = Color(0xFF0D0D0E); // Slightly lighter
const Color darkCard = Color(0xFF1A1A1C);    // Card background

// Text
const Color softWhite = Color(0xFFF6F6F8);   // Primary text
const Color lightGray = Color(0xFFB8B8C9);   // Secondary text
const Color darkGray = Color(0xFF6B6B7C);    // Tertiary text

// Accent
const Color accentBlue = Color(0xFF3B82F6);  // Primary action
const Color accentGreen = Color(0xFF10B981); // Success
const Color accentRed = Color(0xFFEF4444);   // Error
```

**Light Theme**
```dart
const Color lightBg = Color(0xFFF8F9FA);      // Background
const Color lightSurface = Color(0xFFFFFFFF); // Surface
const Color lightText = Color(0xFF1A1A2E);    // Text primary
const Color lightGrayText = Color(0xFF6B7280); // Text secondary
```

### Typography

**Font Family** : Google Fonts - Syne

```dart
// Headings
headline1: Syne 28 bold
headline2: Syne 24 w600
headline3: Syne 20 w600

// Body
bodyLarge: Syne 16 regular
bodyMedium: Syne 14 regular
bodySmall: Syne 12 regular

// Caption
caption: Syne 12 w500
```

### Spacing scale

```
xs:  4px
sm:  8px
md:  12px
lg:  16px
xl:  24px
2xl: 32px
3xl: 48px
```

### Border radius

```
sm: 8px
md: 12px
lg: 16px
xl: 24px
```

---

## 📐 Responsive Design

### Breakpoints

```dart
const double mobileWidth = 360;   // Phone
const double tabletWidth = 768;   // Tablet
const double desktopWidth = 1024; // Desktop
```

### Implementation

```dart
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return MobileLayout();
    } else if (width < 1000) {
      return TabletLayout();
    } else {
      return DesktopLayout();
    }
  }
}
```

---

## 🎬 Animations

### Lottie animations

```dart
// Used for:
// - Loading states
// - Empty states
// - Success confirmations
// - Error states

Lottie.asset(
  'assets/animations/loading.json',
  repeat: true,
  reverse: false,
  animate: true,
)
```

### Custom animations

```dart
// Fade transition
FadeTransition(
  opacity: animation,
  child: child,
)

// Slide transition
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 0.1),
    end: Offset.zero,
  ).animate(controller),
  child: child,
)

// Scale animation (button press)
ScaleTransition(
  scale: Tween<double>(begin: 1, end: 0.95)
      .animate(controller),
  child: GestureDetector(
    onTapDown: (_) => controller.forward(),
    onTapUp: (_) => controller.reverse(),
    child: child,
  ),
)
```

---

## ♿ Accessibility

### Semantic widgets

```dart
// Use Semantics for screen readers
Semantics(
  button: true,
  enabled: true,
  label: 'Se connecter',
  onTap: _submit,
  child: GestureDetector(
    onTap: _submit,
    child: Container(...),
  ),
)
```

### Color contrast

- Text on background: WCAG AA compliant
- Focus indicators visible
- Touch targets ≥ 48x48 dp

---

## 🧪 Widget Testing

```dart
testWidgets('LoginPage displays form', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockAuthProvider()),
      ],
      child: MaterialApp(home: LoginPage()),
    ),
  );

  expect(find.byType(AuthTextField), findsWidgets);
  expect(find.byType(AuthPrimaryButton), findsOneWidget);
});

testWidgets('Submit button is disabled when form invalid', (tester) async {
  await tester.pumpWidget(...);

  final button = find.byType(AuthPrimaryButton);
  expect(tester.widget<AuthPrimaryButton>(button).onTap, isNull);
});
```

---

## ✅ UI/UX Checklist

- [ ] All screens responsive (mobile/tablet)
- [ ] Dark/light theme working
- [ ] Loading states implemented
- [ ] Error states implemented
- [ ] Empty states implemented
- [ ] Animations smooth (60fps target)
- [ ] Touch targets ≥ 48x48 dp
- [ ] Color contrast WCAG AA
- [ ] Back button working everywhere
- [ ] Deep links working
- [ ] Keyboard handling correct
- [ ] No UI overflow on small screens

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : UI/UX Team  
**Status** : ✅ Complet
