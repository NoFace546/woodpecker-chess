import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/set_repository.dart';
import '../data/repositories/user_state_repository.dart';

/// Single non-consumable IAP that unlocks every Pro feature for life.
const String kProProductId = 'pro_lifetime';

/// DEV TOGGLE: when true, force the app into locked (free) state regardless
/// of debug build, grandfathering, or paid status. Use this to preview the
/// paywall flow as a non-paying user. Set back to false to resume normal
/// behaviour. Production releases must always have this as false.
const bool kDevForceLocked = false;

const _kPaidProKey = 'pro_paid';
const _kGrandfatheredKey = 'pro_grandfathered';
const _kGrandfatherAppliedKey = 'pro_grandfather_applied';

class ProStatus {
  const ProStatus({
    required this.isPro,
    required this.source,
  });

  final bool isPro;
  final ProSource source;

  static const ProStatus locked =
      ProStatus(isPro: false, source: ProSource.locked);
}

enum ProSource {
  locked,
  debugBuild,
  grandfathered,
  paid,
}

class ProStatusNotifier extends Notifier<ProStatus> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  ProStatus build() {
    ref.onDispose(() => _purchaseSub?.cancel());
    if (kDevForceLocked) {
      // Dev preview as free user. Skip bootstrap so grandfathering prefs
      // are not consumed.
      return ProStatus.locked;
    }
    if (kDebugMode) {
      // Debug builds always have Pro. No prefs touched so a release build on
      // the same device still goes through the real check.
      return const ProStatus(isPro: true, source: ProSource.debugBuild);
    }
    // Initial state is locked; bootstrap fills it in async.
    Future.microtask(_bootstrap);
    return ProStatus.locked;
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    // Grandfathering: any existing user (has attempts or sets) on first run of
    // the Pro version gets Pro for life. Done once, then remembered.
    if (!(prefs.getBool(_kGrandfatherAppliedKey) ?? false)) {
      final shouldGrandfather = await _shouldGrandfather();
      await prefs.setBool(_kGrandfatherAppliedKey, true);
      if (shouldGrandfather) {
        await prefs.setBool(_kGrandfatheredKey, true);
      }
    }

    if (prefs.getBool(_kGrandfatheredKey) ?? false) {
      state = const ProStatus(isPro: true, source: ProSource.grandfathered);
      return;
    }

    if (prefs.getBool(_kPaidProKey) ?? false) {
      state = const ProStatus(isPro: true, source: ProSource.paid);
    }

    // Subscribe to live purchase updates so a buy/restore in this session
    // immediately flips the flag.
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (Object e) => debugPrint('IAP stream error: $e'),
    );
    // Best-effort restore on cold start.
    InAppPurchase.instance.restorePurchases();
  }

  Future<bool> _shouldGrandfather() async {
    try {
      final user = await ref.read(userStateRepositoryProvider).get();
      if (user.attemptsTotal > 0) return true;
    } catch (_) {}
    try {
      final sets = await ref.read(setRepositoryProvider).listAll();
      if (sets.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != kProProductId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kPaidProKey, true);
        state = const ProStatus(isPro: true, source: ProSource.paid);
      } else if (p.status == PurchaseStatus.error) {
        debugPrint('IAP error: ${p.error}');
      }
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  /// Kicks off the buy flow. Caller should also have a listener UI; we update
  /// state via the purchase stream when the platform confirms.
  Future<bool> buyPro() async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) return false;
    final response = await iap.queryProductDetails({kProProductId});
    if (response.productDetails.isEmpty) return false;
    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    return iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await InAppPurchase.instance.restorePurchases();
  }
}

final proStatusProvider =
    NotifierProvider<ProStatusNotifier, ProStatus>(ProStatusNotifier.new);

/// Convenience: just the bool, for places that don't care about the source.
final isProProvider = Provider<bool>((ref) {
  return ref.watch(proStatusProvider).isPro;
});

/// Pro Product details for the paywall (price, currency, etc.).
final proProductProvider = FutureProvider<ProductDetails?>((ref) async {
  final iap = InAppPurchase.instance;
  if (!await iap.isAvailable()) return null;
  final response = await iap.queryProductDetails({kProProductId});
  if (response.productDetails.isEmpty) return null;
  return response.productDetails.first;
});
