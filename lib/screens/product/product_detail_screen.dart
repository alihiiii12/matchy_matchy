import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/data/family_member_roles.dart';
import 'package:matchy_matchy/core/data/body_measurements.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class _MemberDraft {
  String role = FamilyMemberRoles.father;
  String gender = 'male';
  String age = '';
  String size = 'M';
  String? color;
  final measurements = <String, String>{
    for (final k in BodyMeasurements.keys) k: '',
  };
}

/// صفحة المنتج كالموقع: أفراد العائلة + زر أسفل لإضافة للسلة / تسجيل الدخول.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, this.product});

  final dynamic product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final List<_MemberDraft> _members;

  Product get _product {
    final args = widget.product;
    if (args is Product) return args;
    if (args is Map) {
      final p = args['product'];
      if (p is Product) return p;
    }
    return Product(
      id: '0',
      name: AppStrings.product,
      brand: AppStrings.appName,
      price: 0,
      categoryId: 'fashion',
      subCategoryId: 'fashion_family',
      sellerGovernorateId: 'damascus',
      icon: Icons.checkroom,
      points: 0,
    );
  }

  String? get _initialRole {
    final args = widget.product;
    if (args is Map) return args['role'] as String?;
    return null;
  }

  String? get _initialSize {
    final args = widget.product;
    if (args is Map) return args['size'] as String?;
    return null;
  }

  @override
  void initState() {
    super.initState();
    final role = _initialRole;
    final size = _initialSize;
    final draft = _MemberDraft();
    if (role != null && role.isNotEmpty) {
      draft.role = role;
      draft.gender = FamilyMemberRoles.genderFor(role);
    }
    if (size != null && size.isNotEmpty) {
      draft.size = size;
    }
    _members = [draft];
  }

  double get _displayPrice =>
      _members.fold<double>(0, (sum, m) => sum + _product.priceForRole(m.role));

  bool get _isLoggedInCustomer {
    final user = AuthService.instance.user;
    return user != null && user.isCustomer;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _buy() {
    final p = _product;
    if (_members.isEmpty) {
      _snack(AppStrings.familyMemberRequired);
      return;
    }
    for (final m in _members) {
      if (m.age.trim().isEmpty) {
        _snack(AppStrings.ageRequired);
        return;
      }
      if (m.size.trim().isEmpty) {
        _snack(AppStrings.sizeRequired);
        return;
      }
      final missingMeasure = BodyMeasurements.keys.any((k) => (m.measurements[k] ?? '').trim().isEmpty);
      if (missingMeasure) {
        _snack('يجب إدخال جميع قياسات ختمة المقاسات لكل فرد');
        return;
      }
    }

    if (!_isLoggedInCustomer) {
      Get.toNamed(AppRoutes.login, arguments: {'next': AppRoutes.cart, 'intent': 'buy'});
      return;
    }

    var addedAny = false;
    for (final m in _members) {
      final unit = p.priceForRole(m.role);
      final ok = CartController.instance.add(
        p,
        options: {
          'piece_role': m.role,
          'gender': m.gender.isNotEmpty ? m.gender : FamilyMemberRoles.genderFor(m.role),
          'age': int.tryParse(m.age.trim()) ?? m.age.trim(),
          'size': m.size,
          if (m.color != null && m.color!.isNotEmpty) 'color': m.color,
          'unit_price': unit,
          ...BodyMeasurements.pickFilled(m.measurements),
        },
      );
      if (ok) addedAny = true;
    }
    if (addedAny) {
      Get.toNamed(AppRoutes.cart);
    } else {
      _snack(AppStrings.addToCartFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.isRegistered<LanguageController>()) {
        LanguageController.instance.code.value;
      }
      return _buildScaffold();
    });
  }

  Widget _buildScaffold() {
    final p = _product;
    final category = CategoryCatalog.categoryById(p.categoryId);
    final subCategory = CategoryCatalog.subCategoryById(p.subCategoryId);
    final accent = category?.color ?? AppColors.accent;
    final subLabel = subCategory?.localizedName ?? AppStrings.product;
    final catLabel = category?.localizedName ?? AppStrings.appName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.08)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                    : Center(child: Icon(p.icon ?? Icons.checkroom, size: 120, color: accent)),
              ),
            ),
            actions: [
              Obx(() {
                if (!Get.isRegistered<FavoritesController>()) {
                  return const SizedBox.shrink();
                }
                final isFavorite = FavoritesController.instance.isFavorite(p.id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.error : null,
                  ),
                  onPressed: () => FavoritesController.instance.toggle(p, context: context),
                );
              }),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.brand, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(p.localizedName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.familySetHint,
                    style: TextStyle(color: AppColors.dustyRose, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.formatWithUnit(_displayPrice, p.unit),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  if (_members.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _members
                          .map(
                            (m) =>
                                '${FamilyMemberRoles.label(m.role)}: ${CurrencyFormatter.format(p.priceForRole(m.role))}',
                          )
                          .join(' · '),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.sizeGuide),
                    icon: const Icon(Icons.straighten_outlined, size: 18),
                    label: Text(AppStrings.sizeGuide),
                  ),
                  const SizedBox(height: 20),
                  Text(AppStrings.familyMembersInOrder, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ..._buildMembersUi(),
                  const SizedBox(height: 20),
                  Text(AppStrings.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.productQualityLine(subLabel, catLabel),
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GradientButton(
            label: _isLoggedInCustomer
                ? '${AppStrings.addToCart} · ${CurrencyFormatter.format(_displayPrice)}'
                : AppStrings.loginToBuy,
            onPressed: _buy,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMembersUi() {
    final roleItems = <String>{...FamilyMemberRoles.all};
    for (final piece in _product.pieces) {
      roleItems.add(piece.role);
    }

    return [
      ..._members.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final roles = roleItems.toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.memberNumber(i + 1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_members.length > 1)
                      IconButton(
                        onPressed: () => setState(() => _members.removeAt(i)),
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                      ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: roles.contains(m.role) ? m.role : FamilyMemberRoles.father,
                  decoration: InputDecoration(labelText: AppStrings.selectRole, border: const OutlineInputBorder()),
                  items: roles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(FamilyMemberRoles.label(r)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      m.role = v;
                      m.gender = FamilyMemberRoles.genderFor(v);
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: m.gender == 'female' ? 'female' : 'male',
                  decoration: InputDecoration(labelText: AppStrings.selectGender, border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'male', child: Text(AppStrings.male)),
                    DropdownMenuItem(value: 'female', child: Text(AppStrings.female)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => m.gender = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.selectAge, border: const OutlineInputBorder()),
                  onChanged: (v) => m.age = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: FamilyMemberRoles.defaultSizes.contains(m.size)
                      ? m.size
                      : FamilyMemberRoles.defaultSizes.first,
                  decoration: InputDecoration(labelText: AppStrings.selectSize, border: const OutlineInputBorder()),
                  items: FamilyMemberRoles.defaultSizes
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => m.size = v);
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'ختمة المقاسات',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل القياسات بالسنتيمتر — تُرسل مع المنتج للأدمن',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ...BodyMeasurements.keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: BodyMeasurements.label(key),
                        border: const OutlineInputBorder(),
                        hintText: 'سم',
                      ),
                      onChanged: (v) => m.measurements[key] = v,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
      OutlinedButton.icon(
        onPressed: () => setState(() => _members.add(_MemberDraft())),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppStrings.addFamilyMember),
      ),
    ];
  }
}
