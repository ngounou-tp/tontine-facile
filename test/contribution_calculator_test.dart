import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/rules/contribution_calculator.dart';

void main() {
  test('calcule le montant total du pot', () {
    const calculator = ContributionCalculator();

    expect(calculator.totalPot(contribution: 25000, memberCount: 12), 300000);
  });
}