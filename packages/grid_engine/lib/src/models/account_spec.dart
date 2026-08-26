/// Account configuration specification.
///
/// Represents the trader's account parameters needed for margin and survival calculations.
/// MVP only supports USD accounts — UI should block non-USD with a warning.
class AccountSpec {
  final double balance;
  final double equity;
  final String accountCurrency;
  final double leverage;
  final double stopOutLevelPercent;
  final double? marginCallLevelPercent;

  const AccountSpec({
    required this.balance,
    double? equity,
    this.accountCurrency = 'USD',
    required this.leverage,
    this.stopOutLevelPercent = 20.0,
    this.marginCallLevelPercent,
  }) : equity = equity ?? balance;

  AccountSpec copyWith({
    double? balance,
    double? equity,
    String? accountCurrency,
    double? leverage,
    double? stopOutLevelPercent,
    double? marginCallLevelPercent,
  }) {
    return AccountSpec(
      balance: balance ?? this.balance,
      equity: equity ?? this.equity,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      leverage: leverage ?? this.leverage,
      stopOutLevelPercent: stopOutLevelPercent ?? this.stopOutLevelPercent,
      marginCallLevelPercent:
          marginCallLevelPercent ?? this.marginCallLevelPercent,
    );
  }
}
