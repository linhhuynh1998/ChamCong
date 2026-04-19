import 'package:flutter_test/flutter_test.dart';

import 'package:b2msr/controllers/home_controller.dart';

void main() {
  group('HomeController', () {
    test('starts with loading defaults for attendance screen', () {
      final controller = HomeController();

      expect(controller.employeeName, 'Nhân viên');
      expect(controller.employeeEmail, '');
      expect(controller.statusMessage, isNotEmpty);
    });
  });
}
