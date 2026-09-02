import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/core/utils/financial_calculator.dart';

void main() {
  group('VehicleFinancialCalculator Tests', () {
    test('calculateTotalExpenses calculates sum of expenses correctly', () {
      final expenses = [5000.0, 8000.0, 3000.0, 500.0, 1000.0];
      final total = VehicleFinancialCalculator.calculateTotalExpenses(expenses);
      expect(total, 17500.0);
    });

    test('calculateTotalCost adds purchase amount, commission, and total expenses', () {
      final purchase = 500000.0;
      final commission = 5000.0;
      final expenses = 20000.0;
      final cost = VehicleFinancialCalculator.calculateTotalCost(purchase, expenses, commission);
      expect(cost, 525000.0);
    });

    test('calculateProfitLoss calculates Profit correctly (Sale - (Purchase + Commission + Expenses))', () {
      final profit = VehicleFinancialCalculator.calculateProfitLoss(
        saleAmount: 600000.0,
        purchaseAmount: 500000.0,
        commissionAmount: 5000.0,
        totalExpenses: 20000.0,
      );
      expect(profit, 75000.0);
    });

    test('calculateProfitLoss calculates Loss correctly when Sale < Cost', () {
      final loss = VehicleFinancialCalculator.calculateProfitLoss(
        saleAmount: 500000.0,
        purchaseAmount: 500000.0,
        commissionAmount: 5000.0,
        totalExpenses: 20000.0,
      );
      expect(loss, -25000.0);
    });

    test('calculateBalance returns correct balance due', () {
      final bal = VehicleFinancialCalculator.calculateBalance(500000.0, 200000.0);
      expect(bal, 300000.0);
    });
  });
}
