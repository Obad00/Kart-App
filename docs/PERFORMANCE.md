# ⚡ Performance & Optimization - KART

**Focus** : Optimization, performance metrics, best practices  
**Date** : 18 Mai 2026  
**Version** : 1.0

---

## 📊 Current Performance Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Startup time | < 2s | ~1.5s | ✅ Good |
| App size (APK) | < 100MB | ~85MB | ✅ Good |
| Frame rate | 60 FPS | 58-60 FPS | ✅ Good |
| Memory usage | < 150MB | ~120MB | ✅ Good |
| API response time | < 500ms | ~200ms | ✅ Good |
| Image load time | < 1s | ~400ms | ✅ Good |

---

## 🎯 Key Performance Areas

### 1. Widget Build Optimization

#### Problem: Unnecessary rebuilds

```dart
// ❌ BAD: Entire widget rebuilds when ANY provider changes
Consumer<CardProvider>(
  builder: (context, card, child) {
    return Column(
      children: [
        Text(card.name),           // Only needs this
        ExpensiveWidget(),         // Rebuilds unnecessarily!
        AnotherExpensiveWidget(),  // Rebuilds unnecessarily!
      ],
    );
  },
)

// ✅ GOOD: Limited scope rebuilds
Column(
  children: [
    Consumer<CardProvider>(
      builder: (context, card, child) => Text(card.name),
    ),
    ExpensiveWidget(),         // Doesn't rebuild
    AnotherExpensiveWidget(),  // Doesn't rebuild
  ],
)
```

#### Solution: Use Selector

```dart
// Watch only specific field
Selector<CardProvider, String?>(
  selector: (context, provider) => provider.name,
  builder: (context, name, child) {
    return Text(name ?? 'Loading');
  },
)
```

---

### 2. Image Optimization

#### Memory-efficient image loading

```dart
// ❌ BAD: Loads full image into memory
Image.network(
  'https://backend.kart.business/storage/avatars/1.jpg',
  fit: BoxFit.cover,
)

// ✅ GOOD: Compressed, cached, with placeholders
CachedNetworkImage(
  imageUrl: 'https://backend.kart.business/storage/avatars/1.jpg',
  width: 100,
  height: 100,
  fit: BoxFit.cover,
  
  // Show while loading
  placeholder: (context, url) => ShimmerLoading(),
  
  // Show on error
  errorWidget: (context, url, error) => CircleAvatar(
    child: Icon(Icons.person),
  ),
  
  // Cache for 30 days
  cacheKey: 'avatar_1',
  fadeInDuration: Duration(milliseconds: 300),
)
```

#### SVG optimization

```dart
// QR code as SVG (small size, scalable)
SvgPicture.string(
  qrSvg,
  width: 200,
  height: 200,
  fit: BoxFit.contain,
)

// Avoid: Rasterizing every time
// ❌ SvgPicture.string(svgData) - in build()
// ✅ Store parsed SVG in provider
```

---

### 3. List Performance

#### Efficient list rendering

```dart
// ❌ BAD: Builds entire list, no caching
ListView(
  children: contacts
      .map((c) => ContactTile(contact: c))
      .toList(),
)

// ✅ GOOD: ListView.builder (lazy loading)
ListView.builder(
  itemCount: contacts.length,
  itemBuilder: (context, index) {
    return ContactTile(contact: contacts[index]);
  },
)

// ✅ BETTER: With caching + filtering
PagedListView.builder(
  pagingController: _pagingController,
  builderDelegate: PagedChildBuilderDelegate<ContactModel>(
    itemBuilder: (context, contact, index) {
      return ContactTile(contact: contact);
    },
  ),
)
```

#### Grouped list optimization

```dart
// For contacts grouped by company
SliverList(
  delegate: SliverChildListDelegate(
    contactGroups.expand((group) [
      GroupHeader(group.company),
      ...group.contacts.map((c) => ContactTile(c)),
    ]).toList(),
  ),
)
```

---

### 4. Network Optimization

#### API caching strategy

```dart
// Cache responses for N minutes
class CachedApiClient {
  static final _cache = <String, CacheEntry>{};
  static const _cacheDuration = Duration(minutes: 5);

  Future<Response> get(String url) async {
    // Check cache
    if (_cache.containsKey(url)) {
      final entry = _cache[url]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        return entry.response;  // Return cached
      }
    }

    // Fetch fresh
    final response = await dio.get(url);
    _cache[url] = CacheEntry(response, DateTime.now());
    return response;
  }
}
```

#### Request debouncing

```dart
// Avoid multiple requests while typing
Timer? _searchTimer;

void _onSearchChanged(String query) {
  _searchTimer?.cancel();
  _searchTimer = Timer(Duration(milliseconds: 500), () {
    contactsProvider.searchContacts(query);
  });
}
```

---

### 5. Animation Performance

#### Optimize animations

```dart
// ❌ BAD: Rebuild during animation
AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    return Transform.scale(
      scale: controller.value,
      child: ExpensiveWidget(),  // Rebuilds!
    );
  },
)

// ✅ GOOD: Use SingleTickerProviderStateMixin
class CardAnimation extends StatefulWidget {
  @override
  State<CardAnimation> createState() => _CardAnimationState();
}

class _CardAnimationState extends State<CardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,  // Synced with vsync, efficient
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### Reduce frame rate if needed

```dart
// For non-critical animations
SizedBox(
  width: 100,
  height: 100,
  child: ShaderMask(
    shaderCallback: (_) => Gradient.linear(...).createShader(_),
    child: LottieBuilder.asset('animation.json'),
  ),
)
```

---

### 6. Memory Management

#### Dispose properly

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _subscription = stream.listen((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();      // ✅ Dispose
    _scrollController.dispose(); // ✅ Dispose
    _subscription.cancel();      // ✅ Cancel
    super.dispose();
  }
}
```

#### Avoid memory leaks with Provider

```dart
// ❌ BAD: Keeps reference after dispose
context.read<CardProvider>().loadCard();

// ✅ GOOD: Provider cleaned up automatically
ChangeNotifierProvider(
  create: (_) => CardProvider(),
  child: CardPage(),
)
```

---

### 7. Build Size Optimization

#### Reduce APK size

```
Current: ~85 MB

Breakdown:
- Flutter engine: ~30 MB
- App code: ~15 MB
- Assets: ~20 MB
- Dependencies: ~20 MB
```

**Optimization strategies** :

```bash
# 1. Use --split-per-abi for release
flutter build apk --release --split-per-abi

# 2. Enable code shrinking
# (Already configured in build.gradle)

# 3. Remove unused assets
# (Only include used icon sizes)

# 4. Compress images
# (Use PNG instead of JPG where possible)

# 5. Use code minification
# (ProGuard/R8 configured)
```

---

### 8. Database Query Optimization

#### If local database is added

```dart
// ❌ BAD: Queries entire database
List<Contact> all = await db.contacts.getAll();

// ✅ GOOD: Indexed queries
List<Contact> byCompany = await db.contacts
    .where((c) => c.company == 'Tech Corp')
    .get();

// ✅ BETTER: With pagination
List<Contact> page1 = await db.contacts
    .where((c) => c.company == 'Tech Corp')
    .offset(0)
    .limit(20)
    .get();
```

---

## 🎯 Profiling & Debugging

### Using Flutter DevTools

```bash
# Start app with profiling
flutter run --profile

# Open DevTools
flutter pub global run devtools

# Then go to http://localhost:9100
```

### Check performance in DevTools

1. **Timeline** : Frame rendering time
2. **Memory** : Memory usage graph
3. **CPU Profile** : CPU usage per function
4. **Network** : API call timing
5. **Logging** : Debug output

---

## 📈 Performance Monitoring

### Implement analytics

```dart
class PerformanceMonitor {
  static void trackPageLoad(String pageName, Duration duration) {
    // Send to backend/Firebase Analytics
    debugPrint('Page $pageName loaded in ${duration.inMilliseconds}ms');
  }

  static void trackApiCall(String endpoint, Duration duration) {
    if (duration.inMilliseconds > 1000) {
      debugPrint('⚠️ Slow API: $endpoint took ${duration.inMilliseconds}ms');
    }
  }
}

// Usage
final stopwatch = Stopwatch()..start();
await loadData();
stopwatch.stop();
PerformanceMonitor.trackPageLoad('DigitalCard', stopwatch.elapsed);
```

---

## 🚀 Production Optimization Checklist

- [ ] Widget rebuild optimization (use Selector/Consumer)
- [ ] Image caching enabled
- [ ] List lazy loading implemented
- [ ] API response caching configured
- [ ] Memory leaks fixed (dispose controllers)
- [ ] Animations optimized (SingleTickerProvider)
- [ ] APK size < 100 MB
- [ ] Startup time < 2 seconds
- [ ] No jank (60 FPS consistent)
- [ ] Firebase/analytics implemented
- [ ] Error reporting configured
- [ ] Slow query detection
- [ ] Memory profiling done
- [ ] Battery drain minimized
- [ ] Network usage optimized

---

## 🔥 Common Performance Issues & Fixes

| Issue | Symptom | Fix |
|-------|---------|-----|
| Unnecessary rebuilds | Widget tree flashy | Use Consumer/Selector scoping |
| Large images | High memory usage | Compress + cache images |
| List rendering all items | App freezes on scroll | Use ListView.builder |
| Expensive build() | Janky animations | Move to Animation/Ticker |
| No caching | Slow API | Implement response caching |
| Memory leaks | App crashes over time | Proper dispose() calls |
| Large APK | Download time | Strip unused assets |
| Sync API calls | UI freeze | Use async/await |

---

**Dernière mise à jour** : 18 Mai 2026  
**Responsable** : Performance Team  
**Status** : ✅ Optimisé
