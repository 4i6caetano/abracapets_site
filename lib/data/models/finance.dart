import 'package:flutter/material.dart';

enum DonationMethod {
  pix('Pix', Icons.pix),
  cash('Dinheiro', Icons.payments_outlined),
  transfer('Transferência', Icons.account_balance_outlined),
  campaign('Campanha', Icons.campaign_outlined);

  const DonationMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum PaymentMethod {
  pix('Pix'),
  boleto('Boleto'),
  creditCard('Cartão de crédito'),
  cash('Dinheiro');

  const PaymentMethod(this.label);
  final String label;
}

enum ExpenseCategory {
  food('Ração', Icons.restaurant_outlined, Color(0xFFFF7A1A)),
  vet('Veterinário', Icons.local_hospital_outlined, Color(0xFF7A1FD1)),
  medicine('Remédios', Icons.medication_outlined, Color(0xFF2F7BE5)),
  cleaning('Limpeza', Icons.cleaning_services_outlined, Color(0xFF16A394)),
  rent('Aluguel', Icons.house_outlined, Color(0xFFE2478B)),
  transport('Transporte', Icons.local_shipping_outlined, Color(0xFF8D6E63)),
  other('Outros', Icons.more_horiz, Color(0xFF7D7A85));

  const ExpenseCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}


class Donation {
  const Donation({
    required this.id,
    required this.amount,
    required this.method,
    required this.date,
    this.donorName,
    this.hasReceipt = false,
    this.campaign,
  });

  final String id;
  final double amount;
  final DonationMethod method;
  final DateTime date;

  
  final String? donorName;
  final bool hasReceipt;
  final String? campaign;

  String get displayName => donorName ?? 'Doador anônimo';
}


class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.installments = 1,
    this.hasInvoice = false,
    this.animalId,
  });

  final String id;
  final String description;
  final ExpenseCategory category;
  final double amount;
  final PaymentMethod paymentMethod;
  final int installments;
  final DateTime date;
  final bool hasInvoice;

  
  final String? animalId;
}


class FinanceEntry {
  FinanceEntry.fromDonation(Donation d)
      : id = d.id,
        title = 'Doação ${d.method.label} – ${d.displayName}',
        amount = d.amount,
        date = d.date,
        isIncome = true,
        icon = d.method.icon,
        color = const Color(0xFF1E9E6A),
        donation = d,
        expense = null;

  FinanceEntry.fromExpense(Expense e)
      : id = e.id,
        title = e.description,
        amount = e.amount,
        date = e.date,
        isIncome = false,
        icon = e.category.icon,
        color = e.category.color,
        donation = null,
        expense = e;

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final IconData icon;
  final Color color;
  final Donation? donation;
  final Expense? expense;
}
