import 'package:flutter/material.dart';

import '../../controllers/company_directory_list_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_section_app_bar.dart';
import '../../models/company_directory_item.dart';
import 'company_directory_form_page.dart';

class CompanyDirectoryListPage extends StatefulWidget {
  const CompanyDirectoryListPage({
    super.key,
    required this.title,
    required this.endpoint,
    this.requiresRegionId = false,
  });

  final String title;
  final String endpoint;
  final bool requiresRegionId;

  @override
  State<CompanyDirectoryListPage> createState() =>
      _CompanyDirectoryListPageState();
}

class _CompanyDirectoryListPageState extends State<CompanyDirectoryListPage> {
  late final CompanyDirectoryListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CompanyDirectoryListController(endpoint: widget.endpoint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm({CompanyDirectoryItem? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CompanyDirectoryFormPage(
          title: widget.title.toLowerCase(),
          endpoint: widget.endpoint,
          requiresRegionId: widget.requiresRegionId,
          initialItem: item,
        ),
      ),
    );

    if (changed == true) {
      await _controller.loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PrimarySectionAppBar(
        title: widget.title,
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!_controller.lastActionSucceeded) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _controller.statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              );
            }

            if (_controller.items.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có ${widget.title.toLowerCase()} nào.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.muted,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.loadItems,
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final item = _controller.items[index];
                  return _CompanyDirectoryTile(
                    item: item,
                    onTap: () => _openForm(item: item),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompanyDirectoryTile extends StatelessWidget {
  const _CompanyDirectoryTile({
    required this.item,
    required this.onTap,
  });

  final CompanyDirectoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (item.regionName != null && item.regionName!.trim().isNotEmpty)
        'Vùng: ${item.regionName}',
      if (item.regionId != null &&
          item.regionId!.trim().isNotEmpty &&
          (item.regionName == null || item.regionName!.trim().isEmpty))
        'Mã vùng: ${item.regionId}',
      if (item.description.trim().isNotEmpty) item.description.trim(),
    ];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.name.isEmpty ? 'Không có tên' : item.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: subtitleParts.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      subtitleParts.join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
