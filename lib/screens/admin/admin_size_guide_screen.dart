import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/size_guide_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

class AdminSizeGuideScreen extends StatefulWidget {
  const AdminSizeGuideScreen({super.key});

  @override
  State<AdminSizeGuideScreen> createState() => _AdminSizeGuideScreenState();
}

class _AdminSizeGuideScreenState extends State<AdminSizeGuideScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SizeGuideRepository.instance.fetchAdmin(force: true);
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiFriendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final age = TextEditingController(text: row?['age_label'] as String? ?? '');
    final size = TextEditingController(text: row?['suggested_size'] as String? ?? '');
    final minH = TextEditingController(text: row?['height_cm_min']?.toString() ?? '');
    final maxH = TextEditingController(text: row?['height_cm_max']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row == null ? 'إضافة صف' : 'تعديل صف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: age, decoration: const InputDecoration(labelText: 'العمر')),
              TextField(controller: size, decoration: const InputDecoration(labelText: 'المقاس المقترح')),
              TextField(controller: minH, decoration: const InputDecoration(labelText: 'الطول من (سم)'), keyboardType: TextInputType.number),
              TextField(controller: maxH, decoration: const InputDecoration(labelText: 'الطول إلى (سم)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.save)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (row == null) {
        await SizeGuideRepository.instance.create(
          ageLabel: age.text.trim(),
          suggestedSize: size.text.trim(),
          heightCmMin: int.tryParse(minH.text.trim()),
          heightCmMax: int.tryParse(maxH.text.trim()),
        );
      } else {
        await SizeGuideRepository.instance.update(
          id: row['id'] as int,
          ageLabel: age.text.trim(),
          suggestedSize: size.text.trim(),
          heightCmMin: int.tryParse(minH.text.trim()),
          heightCmMax: int.tryParse(maxH.text.trim()),
        );
      }
      if (!mounted) return;
      showAppSnackBar(context, message: 'تم الحفظ', type: AppSnackBarType.success);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    try {
      await SizeGuideRepository.instance.delete(row['id'] as int);
      if (!mounted) return;
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: apiFriendlyError(e), type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminSizeGuide),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final row = _rows[i];
                      final minH = row['height_cm_min'];
                      final maxH = row['height_cm_max'];
                      return Card(
                        child: ListTile(
                          title: Text('${row['age_label']} → ${row['suggested_size']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(minH != null || maxH != null ? 'الطول: ${minH ?? '?'} - ${maxH ?? '?'} سم' : ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(onPressed: () => _edit(row), icon: const Icon(Icons.edit_outlined)),
                              IconButton(
                                onPressed: () => _delete(row),
                                icon: Icon(Icons.delete_outline, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
