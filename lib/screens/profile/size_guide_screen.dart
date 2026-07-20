import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/size_guide_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class SizeGuideScreen extends StatefulWidget {
  const SizeGuideScreen({super.key});

  @override
  State<SizeGuideScreen> createState() => _SizeGuideScreenState();
}

class _SizeGuideScreenState extends State<SizeGuideScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final _heightCtrl = TextEditingController();
  String? _hint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SizeGuideRepository.instance.fetchPublic(force: true);
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

  void _suggestFromHeight() {
    final height = int.tryParse(_heightCtrl.text.trim());
    if (height == null) {
      setState(() => _hint = 'أدخل طولاً صحيحاً بالسنتيمتر');
      return;
    }
    for (final row in _rows) {
      final minH = row['height_cm_min'] as int?;
      final maxH = row['height_cm_max'] as int?;
      if (minH != null && maxH != null && height >= minH && height <= maxH) {
        setState(() => _hint = 'المقاس المقترح: ${row['suggested_size']} (${row['age_label']})');
        return;
      }
    }
    setState(() => _hint = 'لم نجد مقاساً مطابقاً لهذا الطول');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.sizeGuide)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('اقتراح المقاس من الطول', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _heightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'الطول (سم)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(onPressed: _suggestFromHeight, child: const Text('اقتراح')),
                                ],
                              ),
                              if (_hint != null) ...[
                                const SizedBox(height: 8),
                                Text(_hint!, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('العمر')),
                            DataColumn(label: Text('من')),
                            DataColumn(label: Text('إلى')),
                            DataColumn(label: Text('المقاس')),
                          ],
                          rows: _rows
                              .map(
                                (r) => DataRow(
                                  cells: [
                                    DataCell(Text('${r['age_label'] ?? ''}')),
                                    DataCell(Text('${r['height_cm_min'] ?? '-'}')),
                                    DataCell(Text('${r['height_cm_max'] ?? '-'}')),
                                    DataCell(Text('${r['suggested_size'] ?? ''}')),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
