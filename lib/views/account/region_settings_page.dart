import 'package:flutter/material.dart';

import 'company_directory_list_page.dart';

class RegionSettingsPage extends StatelessWidget {
  const RegionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompanyDirectoryListPage(
      title: 'Vùng',
      endpoint: '/company/regions',
    );
  }
}
