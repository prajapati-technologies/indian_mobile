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

class _UnitCalc extends StatefulWidget {
  const _UnitCalc();

  @override
  State<_UnitCalc> createState() => _UnitCalcState();
}

class _UnitCalcState extends State<_UnitCalc> {
  final _km = TextEditingController(text: '10');
  String _out = 'Miles: -';

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  void _go() {
    final km = double.tryParse(_km.text) ?? 0;
    final miles = km * 0.621371;
    setState(() {
      _out = 'Miles: ${miles.toStringAsFixed(2)}\n'
          'Meters: ${(km * 1000).toStringAsFixed(0)}\n'
          'Feet: ${(km * 3280.84).toStringAsFixed(0)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _card(children: [
      _labelField('Kilometers', _km),
      FilledButton(onPressed: _go, child: const Text('Convert')),
      const SizedBox(height: 12),
      Text(_out),
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
