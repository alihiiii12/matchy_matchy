import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/data/family_member_roles.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/admin_products_repository.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class _PieceDraft {
  String role = 'father';
  final name = TextEditingController();
  final variants = <_VariantDraft>[_VariantDraft()];
}

class _VariantDraft {
  final color = TextEditingController();
  final size = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController(text: '10');
}

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameEn = TextEditingController();
  final _price = TextEditingController();
  final _rolePriceControllers = <String, TextEditingController>{
    for (final role in FamilyMemberRoles.all) role: TextEditingController(),
  };
  String? _categoryId;
  String? _subCategoryId;
  String _governorateId = 'damascus';
  File? _image;
  bool _saving = false;
  final _pieces = <_PieceDraft>[];

  Product? get _editing => Get.arguments is Product ? Get.arguments as Product : null;
  bool get _isEditing => _editing != null;

  @override
  void initState() {
    super.initState();
    final p = _editing;
    if (p != null) {
      _name.text = p.name;
      _nameEn.text = p.nameEn ?? '';
      _price.text = p.price.toString();
      for (final role in FamilyMemberRoles.all) {
        final v = p.rolePrices[role];
        _rolePriceControllers[role]!.text = v != null ? v.toString() : '';
      }
      _categoryId = p.categoryId;
      _subCategoryId = p.subCategoryId;
      _governorateId = p.sellerGovernorateId.isNotEmpty ? p.sellerGovernorateId : 'damascus';
      for (final piece in p.pieces) {
        final draft = _PieceDraft()..role = piece.role;
        draft.name.text = piece.name ?? '';
        draft.variants.clear();
        for (final v in piece.variants) {
          final vd = _VariantDraft();
          vd.color.text = v.color;
          vd.size.text = v.size;
          vd.price.text = v.price.toString();
          vd.stock.text = v.stock.toString();
          draft.variants.add(vd);
        }
        if (draft.variants.isEmpty) draft.variants.add(_VariantDraft());
        _pieces.add(draft);
      }
    }
    _categoryId ??= CategoryCatalog.categories.isNotEmpty ? CategoryCatalog.categories.first.id : null;
    if (_categoryId != null) {
      final cat = CategoryCatalog.categoryById(_categoryId!);
      _subCategoryId ??= cat?.subCategories.isNotEmpty == true ? cat!.subCategories.first.id : null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameEn.dispose();
    _price.dispose();
    for (final c in _rolePriceControllers.values) {
      c.dispose();
    }
    for (final p in _pieces) {
      p.name.dispose();
      for (final v in p.variants) {
        v.color.dispose();
        v.size.dispose();
        v.price.dispose();
        v.stock.dispose();
      }
    }
    super.dispose();
  }

  Map<String, double> _buildRolePricesPayload() {
    final out = <String, double>{};
    _rolePriceControllers.forEach((role, controller) {
      final raw = controller.text.trim();
      if (raw.isEmpty) return;
      final n = double.tryParse(raw);
      if (n != null && n >= 0) out[role] = n;
    });
    return out;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    final path = result?.files.single.path;
    if (path != null) setState(() => _image = File(path));
  }

  List<Map<String, dynamic>>? _buildPiecesPayload() {
    if (_pieces.isEmpty) return [];
    return _pieces.map((p) {
      return {
        'role': p.role,
        if (p.name.text.trim().isNotEmpty) 'name': p.name.text.trim(),
        'variants': p.variants
            .where((v) => v.color.text.trim().isNotEmpty && v.size.text.trim().isNotEmpty)
            .map((v) => {
                  'color': v.color.text.trim(),
                  'size': v.size.text.trim(),
                  'price': double.tryParse(v.price.text.trim()) ?? 0,
                  'stock': int.tryParse(v.stock.text.trim()) ?? 0,
                })
            .toList(),
      };
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_categoryId == null || _subCategoryId == null) {
      showAppSnackBar(context, message: 'اختر القسم والتصنيف', type: AppSnackBarType.error);
      return;
    }
    if (!_isEditing && _image == null) {
      showAppSnackBar(context, message: 'صورة المنتج مطلوبة', type: AppSnackBarType.error);
      return;
    }

    setState(() => _saving = true);
    try {
      final price = double.parse(_price.text.trim());
      final pieces = _buildPiecesPayload();
      final rolePrices = _buildRolePricesPayload();
      if (_isEditing) {
        await AdminProductsRepository.instance.update(
          id: _editing!.id,
          name: _name.text.trim(),
          nameEn: _nameEn.text.trim(),
          categoryId: _categoryId!,
          subCategoryId: _subCategoryId!,
          sellerGovernorateId: _governorateId,
          price: price,
          image: _image,
          pieces: pieces,
          rolePrices: rolePrices,
        );
      } else {
        await AdminProductsRepository.instance.create(
          name: _name.text.trim(),
          nameEn: _nameEn.text.trim(),
          categoryId: _categoryId!,
          subCategoryId: _subCategoryId!,
          sellerGovernorateId: _governorateId,
          price: price,
          image: _image!,
          pieces: pieces,
          rolePrices: rolePrices,
        );
      }
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم الحفظ', type: AppSnackBarType.success);
      Get.back(result: true);
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryCatalog.categories;
    final subCategories = _categoryId == null
        ? <SubCategory>[]
        : (CategoryCatalog.categoryById(_categoryId!)?.subCategories ?? <SubCategory>[]);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: AppStrings.productName, border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameEn,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: AppStrings.productNameEn,
                border: const OutlineInputBorder(),
                hintText: 'English product name',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _categoryId = v;
                  final cat = v != null ? CategoryCatalog.categoryById(v) : null;
                  _subCategoryId = cat?.subCategories.isNotEmpty == true ? cat!.subCategories.first.id : null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _subCategoryId,
              decoration: const InputDecoration(labelText: 'التصنيف الفرعي', border: OutlineInputBorder()),
              items: subCategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _subCategoryId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _governorateId,
              decoration: const InputDecoration(labelText: 'المحافظة', border: OutlineInputBorder()),
              items: DeliveryService.governorates
                  .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _governorateId = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر الأساسي',
                border: OutlineInputBorder(),
                helperText: 'يُستخدم لكل دور بدون سعر خاص',
              ),
              validator: (v) => double.tryParse(v?.trim() ?? '') == null ? 'سعر غير صالح' : null,
            ),
            const SizedBox(height: 16),
            const Text('أسعار حسب الدور (اختياري)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'اترك فارغاً لاستخدام السعر الأساسي',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...FamilyMemberRoles.all.map((role) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _rolePriceControllers[role],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: FamilyMemberRoles.label(role),
                    border: const OutlineInputBorder(),
                    hintText: _price.text.isEmpty ? 'أساسي' : _price.text,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_image != null ? 'تم اختيار صورة' : (_isEditing ? 'تغيير الصورة (اختياري)' : 'اختيار صورة')),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text(AppStrings.familyMembers, style: TextStyle(fontWeight: FontWeight.w700))),
                TextButton.icon(
                  onPressed: () => setState(() => _pieces.add(_PieceDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text('قطعة'),
                ),
              ],
            ),
            ..._pieces.asMap().entries.map((entry) {
              final i = entry.key;
              final piece = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: piece.role,
                              decoration: const InputDecoration(labelText: 'الدور'),
                              items: const [
                                DropdownMenuItem(value: 'father', child: Text('الأب')),
                                DropdownMenuItem(value: 'mother_hijab', child: Text('الأم المحجبة')),
                                DropdownMenuItem(value: 'mother_sport', child: Text('الأم سبور')),
                                DropdownMenuItem(value: 'mother', child: Text('الأم')),
                                DropdownMenuItem(value: 'girl_big', child: Text('البنت الكبيرة')),
                                DropdownMenuItem(value: 'girl_mid', child: Text('البنت المتوسطة')),
                                DropdownMenuItem(value: 'girl_small', child: Text('البنت الصغيرة')),
                                DropdownMenuItem(value: 'girl_baby', child: Text('البيبي بنت')),
                                DropdownMenuItem(value: 'boy_big', child: Text('الولد الكبير')),
                                DropdownMenuItem(value: 'boy_mid', child: Text('الولد المتوسط')),
                                DropdownMenuItem(value: 'boy_small', child: Text('الولد الصغير')),
                                DropdownMenuItem(value: 'boy_baby', child: Text('البيبي صبي')),
                                DropdownMenuItem(value: 'child', child: Text('طفل')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => piece.role = v);
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _pieces.removeAt(i)),
                            icon: Icon(Icons.delete_outline, color: AppColors.error),
                          ),
                        ],
                      ),
                      TextField(controller: piece.name, decoration: const InputDecoration(labelText: 'اسم القطعة (اختياري)')),
                      ...piece.variants.asMap().entries.map((ve) {
                        final v = ve.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(child: TextField(controller: v.color, decoration: InputDecoration(labelText: AppStrings.selectColor))),
                              const SizedBox(width: 6),
                              Expanded(child: TextField(controller: v.size, decoration: InputDecoration(labelText: AppStrings.selectSize))),
                              const SizedBox(width: 6),
                              Expanded(child: TextField(controller: v.price, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number)),
                              IconButton(
                                onPressed: () => setState(() => piece.variants.removeAt(ve.key)),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton(
                        onPressed: () => setState(() => piece.variants.add(_VariantDraft())),
                        child: const Text('+ متغير'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            GradientButton(
              label: _saving ? 'جاري الحفظ...' : AppStrings.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
