import 'package:flutter/material.dart';

import '../../models/company_directory_item.dart';
import 'company_directory_form_page.dart';

class RegionDetailPage extends StatelessWidget {
  const RegionDetailPage({
    super.key,
    this.regionId,
    this.initialItem,
  });

  final String? regionId;
  final CompanyDirectoryItem? initialItem;

  @override
  Widget build(BuildContext context) {
    return CompanyDirectoryFormPage(
      title: 'vùng',
      endpoint: '/company/regions',
      initialItem: initialItem ??
          (regionId != null && regionId!.isNotEmpty
              ? CompanyDirectoryItem(
                  id: regionId!,
                  name: '',
                  description: '',
                )
              : null),
    );
  }
}
