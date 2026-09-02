class VehicleFinancialCalculator {
  /// Calculates total expenses from a list of expense amounts
  static double calculateTotalExpenses(List<double> expenseAmounts) {
    return expenseAmounts.fold(0.0, (sum, amt) => sum + amt);
  }

  /// Calculates total cost: Purchase Amount + Commission Amount + Total Expenses
  static double calculateTotalCost(
    double purchaseAmount,
    double totalExpenses, [
    double commissionAmount = 0.0,
  ]) {
    return purchaseAmount + commissionAmount + totalExpenses;
  }

  /// Calculates total amount paid from a list of payment amounts
  static double calculateAmountPaid(List<double> paymentAmounts) {
    return paymentAmounts.fold(0.0, (sum, amt) => sum + amt);
  }

  /// Calculates balance amount: Sale Amount - Amount Paid
  static double calculateBalance(double saleAmount, double amountPaid) {
    final bal = saleAmount - amountPaid;
    return bal < 0 ? 0.0 : bal;
  }

  /// Calculates profit or loss: Sales Amount - Total Cost (where Total Cost = Purchase + Commission + Expenses)
  /// Positive value indicates profit, negative indicates loss.
  static double calculateProfitLoss({
    required double saleAmount,
    required double purchaseAmount,
    double commissionAmount = 0.0,
    required double totalExpenses,
  }) {
    final totalCost = calculateTotalCost(purchaseAmount, totalExpenses, commissionAmount);
    return saleAmount - totalCost;
  }
}
