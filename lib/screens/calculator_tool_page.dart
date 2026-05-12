import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../theme/app_theme.dart';

/// Same keys / titles as `calculators.blade.php` sidebar.
const List<({String key, String title, String subtitle, IconData icon, Color color})> kCalculatorMenu = [
  (key: 'mortgage-calc', title: 'Mortgage Calculator', subtitle: 'Calculate home loan payments', icon: Icons.home_work_outlined, color: Color(0xFF1976D2)),
  (key: 'emi-calc', title: 'EMI Calculator', subtitle: 'Calculate your loan EMI instantly', icon: Icons.account_balance_outlined, color: Color(0xFFFF7043)),
  (key: 'sip-calc', title: 'SIP Calculator', subtitle: 'Plan your mutual fund investments', icon: Icons.trending_up_outlined, color: Color(0xFF4CAF50)),
  (key: 'tax-calc', title: 'Tax Calculator', subtitle: 'Calculate your income tax easily', icon: Icons.receipt_long_outlined, color: Color(0xFF9C27B0)),
  (key: 'bmi-calc', title: 'BMI Calculator', subtitle: 'Check your body mass index', icon: Icons.monitor_weight_outlined, color: Color(0xFFE91E63)),
  (key: 'calorie-calc', title: 'Calories Calculator', subtitle: 'Track your daily calorie needs', icon: Icons.local_fire_department_outlined, color: Color(0xFFFF9800)),
  (key: 'unit-calc', title: 'Unit Converter', subtitle: 'Convert between different units', icon: Icons.straighten_outlined, color: Color(0xFF00BCD4)),
  (key: 'temp-calc', title: 'Temperature Converter', subtitle: 'Convert Celsius and Fahrenheit', icon: Icons.thermostat_outlined, color: Color(0xFFFF5722)),
  (key: 'age-calc', title: 'Age Calculator', subtitle: 'Calculate your exact age', icon: Icons.cake_outlined, color: Color(0xFF8BC34A)),
  (key: 'time-calc', title: 'Time Difference', subtitle: 'Calculate time between dates', icon: Icons.schedule_outlined, color: Color(0xFF3F51B5)),
  (key: 'love-calc', title: 'Love Calculator', subtitle: 'Fun love compatibility tool', icon: Icons.favorite_outline, color: Color(0xFFE91E63)),
  (key: 'compat-calc', title: 'Compatibility', subtitle: 'Check partner compatibility', icon: Icons.group_outlined, color: Color(0xFF009688)),
  (key: 'horo-calc', title: 'Horoscope Calculator', subtitle: 'Check your daily horoscope', icon: Icons.stars_outlined, color: Color(0xFF673AB7)),
  (key: 'gst-calc', title: 'GST Calculator', subtitle: 'Calculate GST amounts & totals', icon: Icons.receipt_outlined, color: Color(0xFF7B1FA2)),
  (key: 'fdrd-calc', title: 'FD/RD Calculator', subtitle: 'Calculate fixed/recurring deposit returns', icon: Icons.account_balance_outlined, color: Color(0xFF1565C0)),
  (key: 'percent-calc', title: 'Percentage Calculator', subtitle: 'Calculate percentages easily', icon: Icons.percent_outlined, color: Color(0xFF00897B)),
  (key: 'fuel-calc', title: 'Fuel Cost Calculator', subtitle: 'Calculate trip fuel cost', icon: Icons.local_gas_station_outlined, color: Color(0xFFE65100)),
  (key: 'electricity-calc', title: 'Electricity Bill Calculator', subtitle: 'Calculate your electricity bill', icon: Icons.bolt_outlined, color: Color(0xFFF9A825)),
  (key: 'material-calc', title: 'Material Estimator', subtitle: 'Estimate construction materials', icon: Icons.construction_outlined, color: Color(0xFF37474F)),
  (key: 'currency-calc', title: 'Currency Converter', subtitle: 'Convert currencies with live rates', icon: Icons.monetization_on_outlined, color: Color(0xFF2E7D32)),
];

class CalculatorToolPage extends StatefulWidget {
  const CalculatorToolPage({
    super.key,
    required this.calcKey,
    required this.title,
  });

  final String calcKey;
  final String title;

  @override
  State<CalculatorToolPage> createState() => _CalculatorToolPageState();
}

class _CalculatorToolPageState extends State<CalculatorToolPage> {
  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: _buildBody(),
            ),
          ),
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.calcKey) {
      case 'mortgage-calc':
        return const _MortgageCalc();
      case 'emi-calc':
        return const _EmiCalc();
      case 'sip-calc':
        return const _SipCalc();
      case 'tax-calc':
        return const _TaxCalc();
      case 'bmi-calc':
        return const _BmiCalc();
      case 'calorie-calc':
        return const _CalorieCalc();
      case 'unit-calc':
        return const _UnitCalc();
      case 'temp-calc':
        return const _TempCalc();
      case 'age-calc':
        return const _AgeCalc();
      case 'time-calc':
        return const _TimeCalc();
      case 'love-calc':
        return const _LoveCalc();
      case 'compat-calc':
        return const _CompatCalc();
      case 'horo-calc':
        return const _HoroCalc();
      case 'gst-calc':
        return const _GstCalc();
      case 'fdrd-calc':
        return const _FdRdCalc();
      case 'percent-calc':
        return const _PercentCalc();
      case 'fuel-calc':
        return const _FuelCalc();
      case 'electricity-calc':
        return const _ElectricityCalc();
      case 'material-calc':
        return const _MaterialCalc();
      case 'currency-calc':
        return const _CurrencyCalc();
      default:
        return const Text('Unknown calculator');
    }
  }
}

final _usd = NumberFormat('#,##0.00', 'en_US');
final _inr = NumberFormat('#,##0', 'en_IN');

String _fmtUsd(double v) => '\$${_usd.format(v)}';
String _fmtInr(num v) => 'Rs ${_inr.format(v)}';

Widget _card({required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDBE6F8)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

Widget _labelField(
  String label,
  TextEditingController c, {
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.cardMutedBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
        ),
      ],
    ),
  );
}

class _MortgageCalc extends StatefulWidget {
  const _MortgageCalc();

  @override
  State<_MortgageCalc> createState() => _MortgageCalcState();
}

class _MortgageCalcState extends State<_MortgageCalc> {
  final _price = TextEditingController(text: '400000');
  final _downPct = TextEditingController(text: '20');
  final _years = TextEditingController(text: '30');
  final _rate = TextEditingController(text: '6.306');
  final _taxPct = TextEditingController(text: '1.2');
  final _insurance = TextEditingController(text: '1500');
  final _pmi = TextEditingController(text: '0');
  final _hoa = TextEditingController(text: '0');
  final _other = TextEditingController(text: '4000');
  final _extraM = TextEditingController(text: '0');
  final _extraY = TextEditingController(text: '0');
  final _extraOnce = TextEditingController(text: '0');

  String _summary = 'Total Monthly Payment: -';
  bool _showDetail = false;
  double _emi = 0, _totalMonthly = 0;
  double _piTotal = 0, _taxTotal = 0, _insTotal = 0, _otherTotal = 0, _allTotal = 0;
  double _monthlyTax = 0, _monthlyIns = 0, _monthlyOther = 0;
  String _metaHouse = '', _metaLoan = '', _metaDown = '', _metaPayments = '', _metaInterest = '', _metaPayoffDate = '';

  @override
  void dispose() {
    for (final c in [
      _price,
      _downPct,
      _years,
      _rate,
      _taxPct,
      _insurance,
      _pmi,
      _hoa,
      _other,
      _extraM,
      _extraY,
      _extraOnce,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calc() {
    final price = double.tryParse(_price.text) ?? 0;
    final downPercent = double.tryParse(_downPct.text) ?? 0;
    final down = price * (downPercent / 100);
    final principal = math.max(0.0, price - down);
    final monthlyRate = (double.tryParse(_rate.text) ?? 0) / 12 / 100;
    final months = (double.tryParse(_years.text) ?? 0) * 12;

    double emi = 0;
    if (months > 0) {
      if (monthlyRate == 0) {
        emi = principal / months;
      } else {
        final powRn = math.pow(1 + monthlyRate, months).toDouble();
        emi = (principal * monthlyRate * powRn) / (powRn - 1);
      }
    }

    final taxPercent = double.tryParse(_taxPct.text) ?? 0;
    final insurance = double.tryParse(_insurance.text) ?? 0;
    final pmi = double.tryParse(_pmi.text) ?? 0;
    final hoa = double.tryParse(_hoa.text) ?? 0;
    final other = double.tryParse(_other.text) ?? 0;
    final extraMonthly = double.tryParse(_extraM.text) ?? 0;
    final extraYearly = double.tryParse(_extraY.text) ?? 0;
    final extraOneTime = double.tryParse(_extraOnce.text) ?? 0;

    final monthlyTaxes = (price * (taxPercent / 100)) / 12;
    final monthlyInsurance = insurance / 12;
    final monthlyPmi = pmi / 12;
    final monthlyHoa = hoa / 12;
    final monthlyOther = other / 12;
    final monthlyExtraYearly = extraYearly / 12;

    final totalMonthly =
        emi + monthlyTaxes + monthlyInsurance + monthlyPmi + monthlyHoa + monthlyOther + extraMonthly + monthlyExtraYearly;
    final firstMonthTotal = totalMonthly + extraOneTime;
    final piTotal = emi * months;
    final taxTot = monthlyTaxes * months;
    final insTot = monthlyInsurance * months;
    final otherTot = (monthlyOther + monthlyPmi + monthlyHoa) * months;
    final totalOutOfPocket = piTotal + taxTot + insTot + otherTot;
    final totalInterest = math.max(0.0, piTotal - principal);

    final payoff = DateTime.now().add(Duration(days: (months * (365.25 / 12)).round()));

    setState(() {
      _emi = emi;
      _totalMonthly = totalMonthly;
      _piTotal = piTotal;
      _taxTotal = taxTot;
      _insTotal = insTot;
      _otherTotal = otherTot;
      _allTotal = totalOutOfPocket;
      _monthlyTax = monthlyTaxes;
      _monthlyIns = monthlyInsurance;
      _monthlyOther = monthlyOther + monthlyPmi + monthlyHoa;
      _summary =
          'Total Monthly Payment: ${_fmtUsd(totalMonthly)}\nFirst Month (with one-time extra): ${_fmtUsd(firstMonthTotal)}';
      _metaHouse = 'House Price: ${_fmtUsd(price)}';
      _metaLoan = 'Loan Amount: ${_fmtUsd(principal)}';
      _metaDown = 'Down Payment: ${_fmtUsd(down)}';
      _metaPayments = 'Total of ${months.toInt()} Mortgage Payments: ${_fmtUsd(piTotal)}';
      _metaInterest = 'Total Interest: ${_fmtUsd(totalInterest)}';
      _metaPayoffDate = 'Mortgage Payoff Date: ${DateFormat('MMM yyyy').format(payoff)}';
      _showDetail = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(children: [
          _labelField('Home Price (\$)', _price),
          Row(
            children: [
              Expanded(child: _labelField('Down Payment (%)', _downPct)),
              const SizedBox(width: 10),
              Expanded(child: _labelField('Loan Term (Years)', _years)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _labelField('Interest Rate (%)', _rate)),
              const SizedBox(width: 10),
              Expanded(child: _labelField('Property Taxes (%)', _taxPct)),
            ],
          ),
          _labelField('Home Insurance (\$/yr)', _insurance),
          Row(
            children: [
              Expanded(child: _labelField('PMI (\$/yr)', _pmi)),
              const SizedBox(width: 10),
              Expanded(child: _labelField('HOA (\$/yr)', _hoa)),
            ],
          ),
          _labelField('Other Costs (\$/yr)', _other),
          Row(
            children: [
              Expanded(child: _labelField('Extra Monthly (\$)', _extraM)),
              const SizedBox(width: 10),
              Expanded(child: _labelField('Extra Yearly (\$)', _extraY)),
            ],
          ),
          _labelField('One-time Extra (\$)', _extraOnce),
          FilledButton(onPressed: _calc, child: const Text('Calculate')),
        ]),
        const SizedBox(height: 12),
        _card(children: [
          Text(_summary, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
        ]),
        if (_showDetail) ...[
          const SizedBox(height: 12),
          _card(children: [
            Text('Monthly Pay: ${_fmtUsd(_totalMonthly)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Divider(height: 20),
            _row2('Mortgage Payment', _fmtUsd(_emi), _fmtUsd(_piTotal)),
            _row2('Property Tax', _fmtUsd(_monthlyTax), _fmtUsd(_taxTotal)),
            _row2('Home Insurance', _fmtUsd(_monthlyIns), _fmtUsd(_insTotal)),
            _row2('Other Costs', _fmtUsd(_monthlyOther), _fmtUsd(_otherTotal)),
            const Divider(),
            _row2('Total Out-of-Pocket', _fmtUsd(_totalMonthly), _fmtUsd(_allTotal)),
            const SizedBox(height: 12),
            Text(_metaHouse, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(_metaLoan, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(_metaDown, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(_metaPayments, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(_metaInterest, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(_metaPayoffDate, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ]),
        ],
      ],
    );
  }

  Widget _row2(String a, String m, String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(a)),
          Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmiCalc extends StatefulWidget {
  const _EmiCalc();

  @override
  State<_EmiCalc> createState() => _EmiCalcState();
}

class _EmiCalcState extends State<_EmiCalc> {
  final _p = TextEditingController(text: '500000');
  final _rate = TextEditingController(text: '9');
  final _years = TextEditingController(text: '5');
  String _main = 'Monthly EMI: -';

  @override
  void dispose() {
    _p.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  void _go() {
    final p = double.tryParse(_p.text) ?? 0;
    final r = (double.tryParse(_rate.text) ?? 0) / 12 / 100;
    final n = (double.tryParse(_years.text) ?? 0) * 12;
    double emi = 0;
    if (n > 0) {
      emi = r == 0 ? p / n : (p * r * math.pow(1 + r, n).toDouble()) / (math.pow(1 + r, n).toDouble() - 1);
    }
    final total = emi * n;
    final interest = total - p;
    setState(() {
      _main = 'Monthly EMI: ${_fmtInr(emi.round())}\n'
          'Principal: ${_fmtInr(p)}\n'
          'Total Interest: ${_fmtInr(interest)}\n'
          'Total Payment: ${_fmtInr(total)}\n'
          'Monthly rate: ${(r * 100).toStringAsFixed(3)}%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Loan Amount', _p),
      Row(
        children: [
          Expanded(child: _labelField('Rate %', _rate)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Years', _years)),
        ],
      ),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_main),
    ]);
  }
}

class _SipCalc extends StatefulWidget {
  const _SipCalc();

  @override
  State<_SipCalc> createState() => _SipCalcState();
}

class _SipCalcState extends State<_SipCalc> {
  final _m = TextEditingController(text: '5000');
  final _rate = TextEditingController(text: '12');
  final _years = TextEditingController(text: '10');
  String _out = 'Future Value: -';

  @override
  void dispose() {
    _m.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  void _go() {
    final monthly = double.tryParse(_m.text) ?? 0;
    final r = (double.tryParse(_rate.text) ?? 0) / 12 / 100;
    final n = (double.tryParse(_years.text) ?? 0) * 12;
    double value = 0;
    if (n > 0) {
      if (r == 0) {
        value = monthly * n;
      } else {
        value = monthly * (((math.pow(1 + r, n).toDouble() - 1) / r) * (1 + r));
      }
    }
    final invested = monthly * n;
    setState(() {
      _out = 'Future Value: ${_fmtInr(value.round())}\n'
          'Total Invested: ${_fmtInr(invested)}\n'
          'Estimated Returns: ${_fmtInr(math.max(0, value - invested))}\n'
          'Monthly growth rate: ${(r * 100).toStringAsFixed(3)}%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Monthly Investment', _m),
      Row(
        children: [
          Expanded(child: _labelField('Return %', _rate)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Years', _years)),
        ],
      ),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _TaxCalc extends StatefulWidget {
  const _TaxCalc();

  @override
  State<_TaxCalc> createState() => _TaxCalcState();
}

class _TaxCalcState extends State<_TaxCalc> {
  final _income = TextEditingController(text: '900000');
  final _ded = TextEditingController(text: '150000');
  String _out = 'Estimated Tax: -';

  @override
  void dispose() {
    _income.dispose();
    _ded.dispose();
    super.dispose();
  }

  void _go() {
    final income = double.tryParse(_income.text) ?? 0;
    final deduction = double.tryParse(_ded.text) ?? 0;
    final taxable = math.max(0.0, income - deduction);
    final tax = taxable <= 700000 ? 0.0 : taxable * 0.1;
    final eff = income > 0 ? (tax / income) * 100 : 0.0;
    setState(() {
      _out = 'Estimated Tax: ${_fmtInr(tax.round())}\n'
          'Gross Income: ${_fmtInr(income)}\n'
          'Taxable Income: ${_fmtInr(taxable)}\n'
          'Effective Tax %: ${eff.toStringAsFixed(2)}%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Annual Income', _income),
      _labelField('Deductions', _ded),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _BmiCalc extends StatefulWidget {
  const _BmiCalc();

  @override
  State<_BmiCalc> createState() => _BmiCalcState();
}

class _BmiCalcState extends State<_BmiCalc> {
  final _w = TextEditingController(text: '70');
  final _h = TextEditingController(text: '170');
  String _out = 'BMI: -';

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  void _go() {
    final w = double.tryParse(_w.text) ?? 0;
    final hm = (double.tryParse(_h.text) ?? 0) / 100;
    final bmi = hm > 0 ? w / (hm * hm) : 0.0;
    String cat = 'Underweight';
    if (bmi >= 25) {
      cat = 'Overweight';
    } else if (bmi >= 18.5) {
      cat = 'Normal';
    }
    setState(() {
      _out = 'BMI: ${bmi.toStringAsFixed(1)}\nCategory: $cat';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      Row(
        children: [
          Expanded(child: _labelField('Weight (kg)', _w)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Height (cm)', _h)),
        ],
      ),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _CalorieCalc extends StatefulWidget {
  const _CalorieCalc();

  @override
  State<_CalorieCalc> createState() => _CalorieCalcState();
}

class _CalorieCalcState extends State<_CalorieCalc> {
  final _age = TextEditingController(text: '28');
  final _weight = TextEditingController(text: '70');
  final _height = TextEditingController(text: '170');
  String _out = 'Daily Calories: -';

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _go() {
    final age = double.tryParse(_age.text) ?? 0;
    final weight = double.tryParse(_weight.text) ?? 0;
    final height = double.tryParse(_height.text) ?? 0;
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    final maintenance = (bmr * 1.4).round();
    final loss = math.max(1200, maintenance - 500);
    setState(() {
      _out = 'Daily Calories (maintenance): $maintenance kcal\n'
          'Weight loss target: $loss kcal\n'
          'Weight gain target: ${maintenance + 300} kcal';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      Row(
        children: [
          Expanded(child: _labelField('Age', _age)),
          Expanded(child: _labelField('Weight', _weight)),
          Expanded(child: _labelField('Height', _height)),
        ],
      ),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

Widget _dropdownField({
  required String label,
  required String? value,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.cardMutedBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _UnitCalc extends StatefulWidget {
  const _UnitCalc();

  @override
  State<_UnitCalc> createState() => _UnitCalcState();
}

class _UnitCalcState extends State<_UnitCalc> {
  static const _categories = ['Length', 'Weight', 'Area', 'Volume', 'Speed', 'Temperature'];

  static const Map<String, List<String>> _categoryUnits = {
    'Length': ['mm', 'cm', 'm', 'km', 'inches', 'feet', 'yards', 'miles'],
    'Weight': ['mg', 'g', 'kg', 'tons', 'lbs', 'ounces'],
    'Area': ['sq mm', 'sq cm', 'sq m', 'sq ft', 'sq yd', 'acres', 'hectares'],
    'Volume': ['mL', 'L', 'gallons', 'cubic ft', 'cubic m'],
    'Speed': ['m/s', 'km/h', 'ft/s', 'mph', 'knots'],
    'Temperature': ['\u00b0C', '\u00b0F', 'K'],
  };

  static const Map<String, double> _toBase = {
    'mm': 0.001, 'cm': 0.01, 'm': 1.0, 'km': 1000.0,
    'inches': 0.0254, 'feet': 0.3048, 'yards': 0.9144, 'miles': 1609.344,
    'mg': 0.001, 'g': 1.0, 'kg': 1000.0, 'tons': 1000000.0, 'lbs': 453.592, 'ounces': 28.3495,
    'sq mm': 0.000001, 'sq cm': 0.0001, 'sq m': 1.0, 'sq ft': 0.092903, 'sq yd': 0.836127,
    'acres': 4046.86, 'hectares': 10000.0,
    'mL': 0.001, 'L': 1.0, 'gallons': 3.78541, 'cubic ft': 28.3168, 'cubic m': 1000.0,
    'm/s': 1.0, 'km/h': 0.277778, 'ft/s': 0.3048, 'mph': 0.44704, 'knots': 0.514444,
  };

  String _category = 'Length';
  String _fromUnit = 'm';
  String _toUnit = 'km';
  final _input = TextEditingController(text: '100');
  String _result = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _convert() {
    final value = double.tryParse(_input.text) ?? 0;

    String formattedResult;
    if (_category == 'Temperature') {
      double celsius;
      switch (_fromUnit) {
        case '\u00b0C':
          celsius = value;
          break;
        case '\u00b0F':
          celsius = (value - 32) * 5 / 9;
          break;
        case 'K':
          celsius = value - 273.15;
          break;
        default:
          celsius = 0;
      }
      double result;
      switch (_toUnit) {
        case '\u00b0C':
          result = celsius;
          break;
        case '\u00b0F':
          result = celsius * 9 / 5 + 32;
          break;
        case 'K':
          result = celsius + 273.15;
          break;
        default:
          result = 0;
      }
      formattedResult = '$value $_fromUnit = ${result.toStringAsFixed(2)} $_toUnit';
    } else {
      final baseValue = value * _toBase[_fromUnit]!;
      final result = baseValue / _toBase[_toUnit]!;
      formattedResult = '$value $_fromUnit = ${result.toStringAsFixed(4)} $_toUnit';
    }

    setState(() => _result = formattedResult);
  }

  void _onCategoryChanged(String? category) {
    if (category == null || category == _category) return;
    final units = _categoryUnits[category]!;
    setState(() {
      _category = category;
      _fromUnit = units[0];
      _toUnit = units.length > 1 ? units[1] : units[0];
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = _categoryUnits[_category]!;
    return _card(children: [
      _dropdownField(
        label: 'Category',
        value: _category,
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: _onCategoryChanged,
      ),
      Row(
        children: [
          Expanded(
            child: _dropdownField(
              label: 'From',
              value: _fromUnit,
              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _fromUnit = v!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dropdownField(
              label: 'To',
              value: _toUnit,
              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) => setState(() => _toUnit = v!),
            ),
          ),
        ],
      ),
      _labelField('Value', _input),
      FilledButton(onPressed: _convert, child: const Text('Convert')),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(_result, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
      ],
    ]);
  }
}

class _TempCalc extends StatefulWidget {
  const _TempCalc();

  @override
  State<_TempCalc> createState() => _TempCalcState();
}

class _TempCalcState extends State<_TempCalc> {
  final _c = TextEditingController(text: '25');
  String _out = 'Fahrenheit: -';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go() {
    final c = double.tryParse(_c.text) ?? 0;
    final f = (c * 9 / 5) + 32;
    final k = c + 273.15;
    setState(() {
      _out = 'Fahrenheit: ${f.toStringAsFixed(2)} F\nKelvin: ${k.toStringAsFixed(2)} K';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Celsius', _c),
      FilledButton(onPressed: _go, child: const Text('Convert')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _AgeCalc extends StatefulWidget {
  const _AgeCalc();

  @override
  State<_AgeCalc> createState() => _AgeCalcState();
}

class _AgeCalcState extends State<_AgeCalc> {
  DateTime? _dob;
  String _out = 'Age: -';

  void _pick() async {
    final t = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 5, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (t != null) setState(() => _dob = t);
  }

  void _go() {
    final dob = _dob;
    if (dob == null) return;
    final today = DateTime.now();
    var age = today.year - dob.year;
    final m = today.month - dob.month;
    if (m < 0 || (m == 0 && today.day < dob.day)) age--;
    final diffMs = today.difference(dob).inMilliseconds;
    final totalDays = (diffMs / (1000 * 60 * 60 * 24)).floor();
    final totalMonths = (totalDays / 30.44).floor();
    setState(() {
      _out = 'Age: $age years\nMonths (approx): $totalMonths\nDays: $totalDays';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(_dob == null ? 'Pick date of birth' : DateFormat.yMMMd().format(_dob!)),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _TimeCalc extends StatefulWidget {
  const _TimeCalc();

  @override
  State<_TimeCalc> createState() => _TimeCalcState();
}

class _TimeCalcState extends State<_TimeCalc> {
  DateTime? _start;
  DateTime? _end;
  String _out = 'Duration: -';

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null || !mounted) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null || !mounted) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _go() {
    final a = _start;
    final b = _end;
    if (a == null || b == null) return;
    final diff = (b.difference(a)).abs();
    final hours = diff.inHours;
    final mins = diff.inMinutes;
    final days = diff.inMilliseconds / (1000 * 60 * 60 * 24);
    setState(() {
      _out = 'Duration: ${hours}h ${mins % 60}m\n'
          'Total minutes: $mins\n'
          'Total days: ${days.toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      OutlinedButton(
        onPressed: _pickStart,
        child: Text(_start == null ? 'Start date & time' : _start!.toString()),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _pickEnd,
        child: Text(_end == null ? 'End date & time' : _end!.toString()),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _go, child: const Text('Calculate')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

int _stringScore(String a, String b) {
  final text = '$a$b'.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  var sum = 0;
  for (final u in text.codeUnits) {
    sum += u;
  }
  return (sum % 51) + 50;
}

class _LoveCalc extends StatefulWidget {
  const _LoveCalc();

  @override
  State<_LoveCalc> createState() => _LoveCalcState();
}

class _LoveCalcState extends State<_LoveCalc> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String _out = 'Score: -';

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _go() {
    final score = _stringScore(_a.text, _b.text);
    final status = score >= 80 ? 'Excellent' : score >= 65 ? 'Good' : 'Needs effort';
    setState(() {
      _out = 'Score: $score%\nStatus: $status';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Name 1', _a, keyboardType: TextInputType.text),
      _labelField('Name 2', _b, keyboardType: TextInputType.text),
      FilledButton(onPressed: _go, child: const Text('Check')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _CompatCalc extends StatefulWidget {
  const _CompatCalc();

  @override
  State<_CompatCalc> createState() => _CompatCalcState();
}

class _CompatCalcState extends State<_CompatCalc> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String _out = 'Compatibility: -';

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _go() {
    final score = _stringScore(_a.text, _b.text);
    final level = score >= 80 ? 'Very High' : score >= 65 ? 'Moderate' : 'Low';
    setState(() {
      _out = 'Compatibility: $score%\nLevel: $level';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Profile 1', _a, keyboardType: TextInputType.text),
      _labelField('Profile 2', _b, keyboardType: TextInputType.text),
      FilledButton(onPressed: _go, child: const Text('Check')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _HoroCalc extends StatefulWidget {
  const _HoroCalc();

  @override
  State<_HoroCalc> createState() => _HoroCalcState();
}

class _HoroCalcState extends State<_HoroCalc> {
  DateTime? _dob;
  String _out = 'Zodiac: -';

  Future<void> _pick() async {
    final t = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 5, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (t != null) setState(() => _dob = t);
  }

  void _go() {
    final dob = _dob;
    if (dob == null) return;
    const signs = <(String, int, int)>[
      ('Capricorn', 1, 19),
      ('Aquarius', 2, 18),
      ('Pisces', 3, 20),
      ('Aries', 4, 19),
      ('Taurus', 5, 20),
      ('Gemini', 6, 20),
      ('Cancer', 7, 22),
      ('Leo', 8, 22),
      ('Virgo', 9, 22),
      ('Libra', 10, 22),
      ('Scorpio', 11, 21),
      ('Sagittarius', 12, 21),
      ('Capricorn', 12, 31),
    ];
    final month = dob.month;
    final day = dob.day;
    var sign = 'Capricorn';
    for (final row in signs) {
      final name = row.$1;
      final m = row.$2;
      final d = row.$3;
      if (month < m || (month == m && day <= d)) {
        sign = name;
        break;
      }
    }
    const fire = {'Aries', 'Leo', 'Sagittarius'};
    const earth = {'Taurus', 'Virgo', 'Capricorn'};
    const air = {'Gemini', 'Libra', 'Aquarius'};
    final element = fire.contains(sign)
        ? 'Fire'
        : earth.contains(sign)
            ? 'Earth'
            : air.contains(sign)
                ? 'Air'
                : 'Water';
    setState(() {
      _out = 'Zodiac: $sign\nElement: $element';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(_dob == null ? 'Date of birth' : DateFormat.yMMMd().format(_dob!)),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _go, child: const Text('Check')),
      const SizedBox(height: 12),
      Text(_out),
    ]);
  }
}

class _GstCalc extends StatefulWidget {
  const _GstCalc();

  @override
  State<_GstCalc> createState() => _GstCalcState();
}

class _GstCalcState extends State<_GstCalc> {
  final _amount = TextEditingController(text: '10000');
  int _rate = 18;
  bool _exclusive = true;
  double _baseAmount = 0, _cgst = 0, _sgst = 0, _total = 0;
  bool _calculated = false;

  static const _rates = [5, 12, 18, 28];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _calc() {
    final amount = double.tryParse(_amount.text) ?? 0;
    double gst, base;
    if (_exclusive) {
      gst = amount * _rate / 100;
      base = amount;
    } else {
      gst = amount * _rate / (100 + _rate);
      base = amount - gst;
    }
    setState(() {
      _baseAmount = base;
      _cgst = gst / 2;
      _sgst = gst / 2;
      _total = _exclusive ? amount + gst : amount;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Amount (Rs)', _amount),
      _dropdownField(
        label: 'GST Rate',
        value: _rate.toString(),
        items: _rates.map((r) => DropdownMenuItem(value: r.toString(), child: Text('$r%'))).toList(),
        onChanged: (v) => setState(() => _rate = int.parse(v!)),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          ChoiceChip(
            label: const Text('Exclusive'),
            selected: _exclusive,
            onSelected: (_) => setState(() => _exclusive = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Inclusive'),
            selected: !_exclusive,
            onSelected: (_) => setState(() => _exclusive = false),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FilledButton(onPressed: _calc, child: const Text('Calculate')),
      if (_calculated) ...[
        const SizedBox(height: 12),
        const Divider(height: 16),
        Text('Taxable Value: ${_fmtInr(_baseAmount.round())}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('CGST @ ${_rate ~/ 2}%: ${_fmtInr(_cgst.round())}'),
        Text('SGST @ ${_rate ~/ 2}%: ${_fmtInr(_sgst.round())}'),
        const Divider(height: 16),
        Text('Total: ${_fmtInr(_total.round())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.brandNavy)),
      ],
    ]);
  }
}

class _FdRdCalc extends StatefulWidget {
  const _FdRdCalc();

  @override
  State<_FdRdCalc> createState() => _FdRdCalcState();
}

class _FdRdCalcState extends State<_FdRdCalc> {
  bool _isFd = true;
  final _principal = TextEditingController(text: '100000');
  final _monthly = TextEditingController(text: '5000');
  final _rate = TextEditingController(text: '7');
  final _tenure = TextEditingController(text: '5');
  double _maturity = 0, _totalInvestment = 0, _interest = 0;
  bool _calculated = false;

  @override
  void dispose() {
    _principal.dispose();
    _monthly.dispose();
    _rate.dispose();
    _tenure.dispose();
    super.dispose();
  }

  void _calc() {
    final r = (double.tryParse(_rate.text) ?? 0) / 100;
    final t = double.tryParse(_tenure.text) ?? 0;
    const n = 4;

    if (_isFd) {
      final p = double.tryParse(_principal.text) ?? 0;
      if (p <= 0 || t <= 0) return;
      _maturity = r == 0 ? p : p * math.pow(1 + r / n, n * t).toDouble();
      _totalInvestment = p;
    } else {
      final m = double.tryParse(_monthly.text) ?? 0;
      if (m <= 0 || t <= 0) return;
      if (r == 0) {
        _maturity = m * 12 * t;
      } else {
        final nt = n * t;
        _maturity = m * ((math.pow(1 + r / n, nt).toDouble() - 1) / (r / n)) * (1 + r / n);
      }
      _totalInvestment = m * 12 * t;
    }
    _interest = _maturity - _totalInvestment;
    setState(() => _calculated = true);
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('FD'),
            selected: _isFd,
            onSelected: (_) => setState(() => _isFd = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('RD'),
            selected: !_isFd,
            onSelected: (_) => setState(() => _isFd = false),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (_isFd) _labelField('Principal Amount (Rs)', _principal),
      if (!_isFd) _labelField('Monthly Installment (Rs)', _monthly),
      Row(
        children: [
          Expanded(child: _labelField('Rate (% p.a.)', _rate)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Tenure (Years)', _tenure)),
        ],
      ),
      FilledButton(onPressed: _calc, child: const Text('Calculate')),
      if (_calculated) ...[
        const SizedBox(height: 12),
        const Divider(height: 16),
        Text('Maturity Amount: ${_fmtInr(_maturity.round())}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 4),
        Text('Total Investment: ${_fmtInr(_totalInvestment.round())}'),
        Text('Interest Earned: ${_fmtInr(_interest.round())}', style: const TextStyle(color: Color(0xFF2E7D32))),
      ],
    ]);
  }
}

class _PercentCalc extends StatefulWidget {
  const _PercentCalc();

  @override
  State<_PercentCalc> createState() => _PercentCalcState();
}

class _PercentCalcState extends State<_PercentCalc> {
  static const _modes = [
    'X is what % of Y',
    'X% of Y',
    '% change from X to Y',
  ];

  String _mode = _modes[0];
  final _valA = TextEditingController(text: '25');
  final _valB = TextEditingController(text: '200');
  String _result = '';

  @override
  void dispose() {
    _valA.dispose();
    _valB.dispose();
    super.dispose();
  }

  void _calc() {
    final a = double.tryParse(_valA.text) ?? 0;
    final b = double.tryParse(_valB.text) ?? 0;
    if (b == 0) {
      setState(() => _result = 'Please enter valid numbers (Y cannot be zero)');
      return;
    }

    double result;
    String formula;
    switch (_mode) {
      case 'X is what % of Y':
        result = (a / b) * 100;
        formula = '$a \u00f7 $b \u00d7 100 = ${result.toStringAsFixed(2)}%';
        break;
      case 'X% of Y':
        result = (a / 100) * b;
        formula = '$a% of $b = $a \u00f7 100 \u00d7 $b = ${result.toStringAsFixed(2)}';
        break;
      case '% change from X to Y':
        result = ((b - a) / a) * 100;
        final dir = result >= 0 ? 'increase' : 'decrease';
        formula = '($b - $a) \u00f7 $a \u00d7 100 = ${result.toStringAsFixed(2)}% $dir';
        break;
      default:
        result = 0;
        formula = '';
    }

    setState(() => _result = formula);
  }

  @override
  Widget build(BuildContext context) {
    String labelA, labelB;
    switch (_mode) {
      case 'X is what % of Y':
        labelA = 'Value (X)';
        labelB = 'Total (Y)';
        break;
      case 'X% of Y':
        labelA = 'Percentage (X)';
        labelB = 'Value (Y)';
        break;
      case '% change from X to Y':
        labelA = 'Original (X)';
        labelB = 'New (Y)';
        break;
      default:
        labelA = 'Value A';
        labelB = 'Value B';
    }

    return _card(children: [
      _dropdownField(
        label: 'Mode',
        value: _mode,
        items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) {
          setState(() {
            _mode = v!;
            _result = '';
          });
        },
      ),
      const SizedBox(height: 4),
      _labelField(labelA, _valA),
      _labelField(labelB, _valB),
      FilledButton(onPressed: _calc, child: const Text('Calculate')),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(_result, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
      ],
    ]);
  }
}

class _FuelCalc extends StatefulWidget {
  const _FuelCalc();

  @override
  State<_FuelCalc> createState() => _FuelCalcState();
}

class _FuelCalcState extends State<_FuelCalc> {
  final _distance = TextEditingController(text: '100');
  final _mileage = TextEditingController(text: '18');
  final _price = TextEditingController(text: '105');
  bool _calculated = false;
  double _fuelNeeded = 0, _totalCost = 0;

  @override
  void dispose() {
    _distance.dispose();
    _mileage.dispose();
    _price.dispose();
    super.dispose();
  }

  void _calc() {
    final dist = double.tryParse(_distance.text) ?? 0;
    final mil = double.tryParse(_mileage.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;

    if (dist <= 0 || mil <= 0) return;

    setState(() {
      _fuelNeeded = dist / mil;
      _totalCost = _fuelNeeded * price;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Distance (km)', _distance),
      Row(
        children: [
          Expanded(child: _labelField('Mileage (km/L)', _mileage)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Fuel Price (Rs/L)', _price)),
        ],
      ),
      FilledButton(onPressed: _calc, child: const Text('Calculate')),
      if (_calculated) ...[
        const SizedBox(height: 12),
        const Divider(height: 16),
        Text('Fuel Needed: ${_fuelNeeded.toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Total Cost: ${_fmtInr(_totalCost.round())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.brandNavy)),
      ],
    ]);
  }
}

class _ElectricityCalc extends StatefulWidget {
  const _ElectricityCalc();

  @override
  State<_ElectricityCalc> createState() => _ElectricityCalcState();
}

class _ElectricityCalcState extends State<_ElectricityCalc> {
  final _units = TextEditingController(text: '300');
  final _rate = TextEditingController(text: '7');
  final _fixed = TextEditingController(text: '100');
  bool _calculated = false;
  double _energyCharge = 0, _subtotal = 0, _gst = 0, _total = 0;

  @override
  void dispose() {
    _units.dispose();
    _rate.dispose();
    _fixed.dispose();
    super.dispose();
  }

  void _calc() {
    final u = double.tryParse(_units.text) ?? 0;
    final r = double.tryParse(_rate.text) ?? 0;
    final f = double.tryParse(_fixed.text) ?? 0;

    setState(() {
      _energyCharge = u * r;
      _subtotal = _energyCharge + f;
      _gst = _subtotal * 0.18;
      _total = _subtotal + _gst;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Units Consumed', _units),
      Row(
        children: [
          Expanded(child: _labelField('Rate per Unit (Rs)', _rate)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Fixed Charge (Rs)', _fixed)),
        ],
      ),
      FilledButton(onPressed: _calc, child: const Text('Calculate')),
      if (_calculated) ...[
        const SizedBox(height: 12),
        const Divider(height: 16),
        Text('Energy Charge: ${_fmtInr(_energyCharge.round())}'),
        Text('Fixed Charge: ${_fmtInr((double.tryParse(_fixed.text) ?? 0).round())}'),
        const Divider(height: 12),
        Text('Subtotal: ${_fmtInr(_subtotal.round())}', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('GST @ 18%: ${_fmtInr(_gst.round())}'),
        const Divider(height: 12),
        Text('Total Bill: ${_fmtInr(_total.round())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.brandNavy)),
      ],
    ]);
  }
}

class _MaterialCalc extends StatefulWidget {
  const _MaterialCalc();

  @override
  State<_MaterialCalc> createState() => _MaterialCalcState();
}

class _MaterialCalcState extends State<_MaterialCalc> {
  final _length = TextEditingController(text: '40');
  final _width = TextEditingController(text: '30');
  String _buildingType = 'Residential 1-floor';
  bool _calculated = false;

  static const _buildingTypes = ['Residential 1-floor', 'Residential 2-floor', 'Commercial'];
  static const _multipliers = <String, double>{
    'Residential 1-floor': 1.0,
    'Residential 2-floor': 1.8,
    'Commercial': 2.5,
  };

  final List<_MaterialRow> _materials = [];

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  void _calc() {
    final l = double.tryParse(_length.text) ?? 0;
    final w = double.tryParse(_width.text) ?? 0;
    if (l <= 0 || w <= 0) return;

    final mult = _multipliers[_buildingType] ?? 1.0;
    final area = l * w;

    setState(() {
      _materials.clear();
      _materials.add(_MaterialRow(Icons.grid_on, 'Bricks (approx)', (area * 3.5 * mult).round().toString()));
      _materials.add(_MaterialRow(Icons.inventory_2, 'Cement (bags)', '${(area * 0.5 * mult).toStringAsFixed(0)} bags'));
      _materials.add(_MaterialRow(Icons.landscape, 'Sand (cu.ft)', (area * 2.5 * mult).toStringAsFixed(0)));
      _materials.add(_MaterialRow(Icons.circle_outlined, 'Aggregate (cu.ft)', (area * 1.8 * mult).toStringAsFixed(0)));
      _materials.add(_MaterialRow(Icons.construction_outlined, 'Steel (kg)', (area * 1.2 * mult).toStringAsFixed(0)));
      _materials.add(_MaterialRow(Icons.brush, 'Paint (liters)', ((l + w) * 2 * 0.15 * mult).toStringAsFixed(1)));
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      Row(
        children: [
          Expanded(child: _labelField('Length (ft)', _length)),
          const SizedBox(width: 10),
          Expanded(child: _labelField('Width (ft)', _width)),
        ],
      ),
      _dropdownField(
        label: 'Building Type',
        value: _buildingType,
        items: _buildingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _buildingType = v!),
      ),
      FilledButton(onPressed: _calc, child: const Text('Estimate Materials')),
      if (_calculated) ...[
        const SizedBox(height: 12),
        const Divider(height: 16),
        Text('Estimated Materials ($_buildingType)', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._materials.map((m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(m.icon, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(m.label, style: const TextStyle(fontSize: 13))),
              Text(m.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        )),
      ],
    ]);
  }
}

class _MaterialRow {
  final IconData icon;
  final String label;
  final String value;
  const _MaterialRow(this.icon, this.label, this.value);
}

class _CurrencyCalc extends StatefulWidget {
  const _CurrencyCalc();
  @override
  State<_CurrencyCalc> createState() => _CurrencyCalcState();
}

class _CurrencyCalcState extends State<_CurrencyCalc> {
  final _amountCtrl = TextEditingController(text: '1');
  String _from = 'USD';
  String _to = 'INR';
  String _result = '';
  String _rateInfo = '';

  static const _currencies = [
    'USD', 'INR', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF',
    'CNY', 'SGD', 'HKD', 'KRW', 'NZD', 'MXN', 'BRL', 'ZAR',
    'RUB', 'TRY', 'AED', 'SAR',
  ];

  // Offline rates (relative to USD as base)
  static const _usdRates = {
    'USD': 1.0, 'INR': 83.5, 'EUR': 0.92, 'GBP': 0.79,
    'JPY': 151.5, 'CAD': 1.37, 'AUD': 1.53, 'CHF': 0.90,
    'CNY': 7.24, 'SGD': 1.34, 'HKD': 7.82, 'KRW': 1340.0,
    'NZD': 1.65, 'MXN': 17.15, 'BRL': 5.05, 'ZAR': 18.60,
    'RUB': 92.0, 'TRY': 32.20, 'AED': 3.67, 'SAR': 3.75,
  };

  void _convert() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _result = 'Enter a valid amount');
      return;
    }
    final fromRate = _usdRates[_from]!;
    final toRate = _usdRates[_to]!;
    final usdValue = amount / fromRate;
    final converted = usdValue * toRate;
    final f = NumberFormat('#,##0.00', 'en_US');
    setState(() {
      _result = '$amount $_from = ${f.format(converted)} $_to';
      _rateInfo = '1 $_from = ${f.format(toRate / fromRate)} $_to';
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Amount', _amountCtrl, keyboardType: TextInputType.number),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _dropdownField(
              label: 'From',
              value: _from,
              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _from = v!),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, color: AppColors.textMuted),
          ),
          Expanded(
            child: _dropdownField(
              label: 'To',
              value: _to,
              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _to = v!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _convert, child: const Text('Convert')),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(_result, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),
        Text(_rateInfo, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    ]);
  }
}
