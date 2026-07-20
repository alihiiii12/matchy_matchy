import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/data/family_member_roles.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

/// مطابق لصفحة الويب: ابحث عن طقم حسب الفرد والمقاس والقسم.
class DescribeOutfitScreen extends StatefulWidget {
  const DescribeOutfitScreen({super.key});

  @override
  State<DescribeOutfitScreen> createState() => _DescribeOutfitScreenState();
}

class _DescribeOutfitScreenState extends State<DescribeOutfitScreen> {
  String _role = FamilyMemberRoles.father;
  String _size = 'M';
  String? _categoryId;
  String _color = '';
  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<Product> _products = const [];

  List<ShopCategory> get _categories => CategoryCatalog.categories;

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      var list = await CatalogRepository.instance.fetchProducts(
        categoryId: _categoryId,
        role: _role,
        size: _size,
      );
      final color = _color.trim();
      if (color.isNotEmpty) {
        list = list.where((p) {
          return p.pieces.any(
            (piece) =>
                piece.role == _role &&
                piece.variants.any(
                  (v) =>
                      v.size == _size &&
                      v.color.toLowerCase().contains(color.toLowerCase()),
                ),
          );
        }).toList();
      }
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiFriendlyError(e);
        _products = const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر البحث';
        _products = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.describeYourOutfit)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.describeYourOutfitHint,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: FamilyMemberRoles.all.contains(_role) ? _role : FamilyMemberRoles.father,
            decoration: const InputDecoration(labelText: 'الفرد', border: OutlineInputBorder()),
            items: FamilyMemberRoles.all
                .map((r) => DropdownMenuItem(value: r, child: Text(FamilyMemberRoles.label(r))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: FamilyMemberRoles.defaultSizes.contains(_size) ? _size : 'M',
            decoration: const InputDecoration(labelText: 'المقاس', border: OutlineInputBorder()),
            items: FamilyMemberRoles.defaultSizes
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _size = v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('كل الأقسام')),
              ..._categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'اللون (اختياري)',
              border: OutlineInputBorder(),
              hintText: 'مثال: أبيض',
            ),
            onChanged: (v) => _color = v,
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: _loading ? 'جاري البحث...' : 'عرض المنتجات المطابقة',
            onPressed: _loading ? null : _search,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          if (_searched && !_loading) ...[
            const SizedBox(height: 20),
            Text(
              'النتائج لـ ${FamilyMemberRoles.label(_role)} · مقاس $_size — ${_products.length} منتج',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (_products.isEmpty)
              const Text('لا توجد منتجات مطابقة لهذا الاختيار.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final p = _products[i];
                  return ProductCard(
                    product: p,
                    onTap: () => Get.toNamed(
                      AppRoutes.productDetail,
                      arguments: {
                        'product': p,
                        'role': _role,
                        'size': _size,
                      },
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
