import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/game_logger.dart';
import '../services/leaderboard_service.dart';
import '../services/leave_attempt_logger.dart';
import '../services/sound_service.dart';
import '../widgets/animated_shape_background.dart';
import '../widgets/app_brightness_overlay.dart';
import '../widgets/correct_splash.dart';
import '../widgets/game_over_popup.dart';
import '../widgets/game_timer.dart';
import '../widgets/hearts_display.dart';
import '../widgets/incorrect_splash.dart';
import '../widgets/leave_warning_overlay.dart';
import '../widgets/level_up_popup.dart';

enum _FractionQuestionType {
  identifyPie,
  writePieFraction,
  setFraction,
  equivalentMissingNumerator,
  equivalentMissingDenominator,
  equivalentHarder,
  threeEquivalent,
  compareSameDenominatorPie,
  compareDifferentDenominatorPie,
  compareImproperPie,
  compareMixedPie,
  compareLikeDenominators,
  compareUnlikeDenominators,
  compareImproper,
  compareMixed,
  simplifyProper,
  simplifyImproper,
  addLike,
  addMixedLike,
  completeWholeImproper,
  completeWholeMixed,
  subtractLike,
  subtractImproperLike,
  subtractFromWhole,
  subtractFromMixed,
  subtractMixedFromWhole,
  subtractMixedLike,
  mixedToFraction,
  fractionToMixed,
  decimalToMixed,
  fractionToDecimal,
  mixedToDecimal,
}

class _FractionValue {
  final int numerator;
  final int denominator;

  const _FractionValue(this.numerator, this.denominator);

  _FractionValue simplified() {
    final divisor = _gcd(numerator.abs(), denominator.abs());
    var n = numerator ~/ divisor;
    var d = denominator ~/ divisor;
    if (d < 0) {
      n = -n;
      d = -d;
    }
    return _FractionValue(n, d);
  }

  double get value => numerator / denominator;

  String asFractionString() {
    final simple = simplified();
    return '${simple.numerator}/${simple.denominator}';
  }

  String asMixedString() {
    final simple = simplified();
    if (simple.denominator == 1) return simple.numerator.toString();
    if (simple.numerator.abs() < simple.denominator) {
      return '${simple.numerator}/${simple.denominator}';
    }
    final whole = simple.numerator ~/ simple.denominator;
    final remainder = simple.numerator.abs() % simple.denominator;
    if (remainder == 0) return whole.toString();
    return '$whole $remainder/${simple.denominator}';
  }

  String asDecimalString() {
    final decimal = value;
    final fixed = decimal.toStringAsFixed(3);
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  String toString() => asFractionString();
}

int _gcd(int a, int b) {
  while (b != 0) {
    final temp = b;
    b = a % b;
    a = temp;
  }
  return a == 0 ? 1 : a.abs();
}

class _FractionQuestion {
  final _FractionQuestionType type;
  final String instruction;
  final String expression;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final int? pieNumerator;
  final int? pieDenominator;
  final int? setTotal;
  final int? setColored;
  final _FractionValue? leftFraction;
  final _FractionValue? rightFraction;
  final String? leftLabel;
  final String? rightLabel;

  const _FractionQuestion({
    required this.type,
    required this.instruction,
    required this.expression,
    required this.correctAnswer,
    required this.acceptedAnswers,
    this.pieNumerator,
    this.pieDenominator,
    this.setTotal,
    this.setColored,
    this.leftFraction,
    this.rightFraction,
    this.leftLabel,
    this.rightLabel,
  });
}

class FractionsGame extends StatefulWidget {
  const FractionsGame({super.key});

  @override
  State<FractionsGame> createState() => _FractionsGameState();
}

class _FractionsGameState extends State<FractionsGame> {
  static const String _gameName = 'Fractions';
  static const Color _inkColor = Color(0xFF2F5233);
  static const Color _bgTopColor = Color(0xFFE6F7E6);
  static const Color _bgBottomColor = Color(0xFFD4EDD1);
  static const Color _panelColor = Color(0xFFFAFFF9);
  static const Color _accentColor = Color(0xFF4CAF50);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 900);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 1500);

  final Random _random = Random();

  bool hasStarted = false;
  bool isGameOver = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  bool _showExitConfirmation = false;
  bool _isSavingScore = false;

  int score = 0;
  int level = 1;
  int hearts = 3;
  int timeLimit = 18;
  String input = '';
  _FractionQuestion currentQuestion = const _FractionQuestion(
    type: _FractionQuestionType.identifyPie,
    instruction: 'Identify the shaded fraction.',
    expression: 'What fraction is shaded?',
    correctAnswer: '1/2',
    acceptedAnswers: ['1/2'],
    pieNumerator: 1,
    pieDenominator: 2,
  );
  Key timerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.math);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    GameLogger.endSession();
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  void startGame() {
    GameLogger.startNewSession(_gameName);
    setState(() {
      hasStarted = true;
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      _isSavingScore = false;
      score = 0;
      level = 1;
      hearts = 3;
      input = '';
      timeLimit = 18;
      timerKey = UniqueKey();
    });
    generateQuestion();
  }

  List<_FractionQuestionType> _availableTypes() {
    final types = <_FractionQuestionType>[
      _FractionQuestionType.equivalentMissingNumerator,
      _FractionQuestionType.equivalentMissingDenominator,
      _FractionQuestionType.compareLikeDenominators,
      _FractionQuestionType.simplifyProper,
      _FractionQuestionType.addLike,
      _FractionQuestionType.subtractLike,
    ];

    if (level >= 2) {
      types.addAll([
        _FractionQuestionType.equivalentHarder,
        _FractionQuestionType.threeEquivalent,
        _FractionQuestionType.compareUnlikeDenominators,
        _FractionQuestionType.simplifyImproper,
      ]);
    }

    if (level >= 3) {
      types.addAll([
        _FractionQuestionType.addMixedLike,
        _FractionQuestionType.subtractImproperLike,
        _FractionQuestionType.mixedToFraction,
        _FractionQuestionType.fractionToMixed,
      ]);
    }

    if (level >= 4) {
      types.addAll([
        _FractionQuestionType.completeWholeImproper,
        _FractionQuestionType.completeWholeMixed,
        _FractionQuestionType.subtractFromWhole,
        _FractionQuestionType.subtractFromMixed,
        _FractionQuestionType.subtractMixedFromWhole,
        _FractionQuestionType.subtractMixedLike,
      ]);
    }

    if (level >= 5) {
      types.addAll([
        _FractionQuestionType.compareImproper,
        _FractionQuestionType.compareMixed,
        _FractionQuestionType.decimalToMixed,
        _FractionQuestionType.fractionToDecimal,
        _FractionQuestionType.mixedToDecimal,
      ]);
    }

    return types;
  }

  int _randDenominator({int min = 2, int max = 12}) {
    return _random.nextInt(max - min + 1) + min;
  }

  int _randNumerator(int denominator, {bool proper = true}) {
    if (proper) return _random.nextInt(denominator - 1) + 1;
    return _random.nextInt(denominator * 2 - 1) + 1;
  }

  _FractionValue _randomProper({int maxDen = 12}) {
    final d = _randDenominator(max: maxDen);
    final n = _randNumerator(d);
    return _FractionValue(n, d).simplified();
  }

  void generateQuestion() {
    final types = _availableTypes();
    final type = types[_random.nextInt(types.length)];
    final question = _buildQuestion(type);
    setState(() {
      currentQuestion = question;
      input = '';
      timeLimit = _timeLimitForLevel();
      timerKey = UniqueKey();
    });
  }

  _FractionQuestion _buildQuestion(_FractionQuestionType type) {
    switch (type) {
      case _FractionQuestionType.identifyPie:
      case _FractionQuestionType.writePieFraction:
        final d = _randDenominator(max: 10);
        final n = _randNumerator(d);
        final fraction = _FractionValue(n, d).simplified();
        return _FractionQuestion(
          type: type,
          instruction: type == _FractionQuestionType.identifyPie
              ? 'Identify fractions: color in the fraction.'
              : 'Identify fractions: write the fraction.',
          expression: 'What fraction of the pie is shaded?',
          correctAnswer: fraction.asFractionString(),
          acceptedAnswers: [fraction.asFractionString()],
          pieNumerator: n,
          pieDenominator: d,
        );
      case _FractionQuestionType.setFraction:
        final total = _random.nextInt(7) + 5;
        final colored = _random.nextInt(total - 1) + 1;
        final fraction = _FractionValue(colored, total).simplified();
        return _FractionQuestion(
          type: type,
          instruction: 'Fractional part of a set.',
          expression: 'What fraction of the set is green?',
          correctAnswer: fraction.asFractionString(),
          acceptedAnswers: [fraction.asFractionString()],
          setTotal: total,
          setColored: colored,
        );
      case _FractionQuestionType.equivalentMissingNumerator:
        final baseDen = _randDenominator(max: 10);
        final baseNum = _randNumerator(baseDen);
        final multiplier = _random.nextInt(7) + 2;
        final answer = baseNum * multiplier;
        return _FractionQuestion(
          type: type,
          instruction: 'Equivalent fractions: numerator missing.',
          expression: '__ / $baseDen = $answer/${baseDen * multiplier}',
          correctAnswer: '$answer',
          acceptedAnswers: ['$answer'],
        );
      case _FractionQuestionType.equivalentMissingDenominator:
        final baseDen = _randDenominator(max: 10);
        final baseNum = _randNumerator(baseDen);
        final multiplier = _random.nextInt(7) + 2;
        final answer = baseDen * multiplier;
        return _FractionQuestion(
          type: type,
          instruction: 'Equivalent fractions: denominator missing.',
          expression: '$baseNum/$baseDen = ${baseNum * multiplier}/__',
          correctAnswer: '$answer',
          acceptedAnswers: ['$answer'],
        );
      case _FractionQuestionType.equivalentHarder:
        final base = _randomProper(maxDen: 10);
        final leftMultiplier = _random.nextInt(5) + 2;
        final rightMultiplier = (_random.nextInt(5) + 7);
        final left = _FractionValue(base.numerator * leftMultiplier, base.denominator * leftMultiplier);
        final answer = base.numerator * rightMultiplier;
        final rightDen = base.denominator * rightMultiplier;
        return _FractionQuestion(
          type: type,
          instruction: 'Equivalent fractions: harder version.',
          expression: '${left.numerator}/${left.denominator} = __ /$rightDen',
          correctAnswer: '$answer',
          acceptedAnswers: ['$answer'],
        );
      case _FractionQuestionType.threeEquivalent:
        final base = _randomProper(maxDen: 9);
        final answer1 = base.denominator * 3;
        final answer2 = base.denominator * 6;
        return _FractionQuestion(
          type: type,
          instruction: 'Complete 3 equivalent fractions.',
          expression: '${base.numerator}/${base.denominator} = ${base.numerator * 3}/__ = ${base.numerator * 6}/__',
          correctAnswer: '$answer1/$answer2',
          acceptedAnswers: ['$answer1/$answer2', '$answer1 $answer2'],
        );
      case _FractionQuestionType.compareSameDenominatorPie:
        final d = _randDenominator(max: 10);
        final a = _random.nextInt(d - 1) + 1;
        var b = _random.nextInt(d - 1) + 1;
        if (b == a) b = b == d - 1 ? 1 : b + 1;
        return _compareQuestion(
          type,
          _FractionValue(a, d),
          _FractionValue(b, d),
          'Compare 2 fractions, same denominator.',
          withPie: true,
        );
      case _FractionQuestionType.compareDifferentDenominatorPie:
        final left = _randomProper(maxDen: 10);
        var right = _randomProper(maxDen: 10);
        if ((left.value - right.value).abs() < 0.001) {
          right = _FractionValue(right.numerator + 1, right.denominator).simplified();
        }
        return _compareQuestion(
          type,
          left,
          right,
          'Compare 2 fractions, different denominators.',
          withPie: true,
        );
      case _FractionQuestionType.compareImproperPie:
        final left = _FractionValue(_random.nextInt(10) + 3, _randDenominator(max: 8)).simplified();
        final right = _randomProper(maxDen: 8);
        return _compareQuestion(
          type,
          left,
          right,
          'Compare proper or improper fractions.',
          withPie: true,
        );
      case _FractionQuestionType.compareMixedPie:
        final left = _mixedFraction(_random.nextInt(3) + 1);
        final right = _mixedFraction(_random.nextInt(3) + 1);
        return _compareQuestion(
          type,
          left,
          right,
          'Compare mixed numbers and fractions.',
          withPie: true,
          leftLabel: left.asMixedString(),
          rightLabel: right.asMixedString(),
        );
      case _FractionQuestionType.compareLikeDenominators:
        final d = _randDenominator(max: 12);
        final a = _random.nextInt(d - 1) + 1;
        var b = _random.nextInt(d - 1) + 1;
        if (a == b) b = b == d - 1 ? 1 : b + 1;
        return _compareQuestion(type, _FractionValue(a, d), _FractionValue(b, d), 'Comparing fractions with like denominators.');
      case _FractionQuestionType.compareUnlikeDenominators:
        return _compareQuestion(type, _randomProper(maxDen: 12), _randomProper(maxDen: 12), 'Comparing fractions with unlike denominators.');
      case _FractionQuestionType.compareImproper:
        return _compareQuestion(
          type,
          _FractionValue(_random.nextInt(14) + 3, _randDenominator(max: 8)).simplified(),
          _randomProper(maxDen: 8),
          'Comparing improper fractions.',
        );
      case _FractionQuestionType.compareMixed:
        final left = _mixedFraction(_random.nextInt(4) + 1);
        final right = _mixedFraction(_random.nextInt(4) + 1);
        return _compareQuestion(
          type,
          left,
          right,
          'Comparing mixed numbers.',
          leftLabel: left.asMixedString(),
          rightLabel: right.asMixedString(),
        );
      case _FractionQuestionType.simplifyProper:
        final base = _randomProper(maxDen: 12);
        final multiplier = _random.nextInt(5) + 2;
        final unsimplified = _FractionValue(base.numerator * multiplier, base.denominator * multiplier);
        return _answerFractionQuestion(
          type,
          'Simplifying fractions: proper fractions.',
          '${unsimplified.numerator}/${unsimplified.denominator} = ___',
          base,
        );
      case _FractionQuestionType.simplifyImproper:
        final whole = _random.nextInt(4) + 1;
        final part = _randomProper(maxDen: 10);
        final improper = _FractionValue((whole * part.denominator) + part.numerator, part.denominator);
        final multiplier = _random.nextInt(4) + 2;
        final unsimplified = _FractionValue(improper.numerator * multiplier, improper.denominator * multiplier);
        return _answerFractionQuestion(
          type,
          'Simplifying fractions: proper and improper fractions.',
          '${unsimplified.numerator}/${unsimplified.denominator} = ___',
          improper.simplified(),
        );
      case _FractionQuestionType.addLike:
        final d = _randDenominator(max: 12);
        final a = _random.nextInt(d - 1) + 1;
        final b = _random.nextInt(d - a) + 1;
        return _answerFractionQuestion(
          type,
          'Adding like fractions.',
          '$a/$d + $b/$d = ___',
          _FractionValue(a + b, d),
        );
      case _FractionQuestionType.addMixedLike:
        final d = _randDenominator(max: 12);
        final w1 = _random.nextInt(4) + 1;
        final w2 = _random.nextInt(4) + 1;
        final a = _random.nextInt(d - 1) + 1;
        final b = _random.nextInt(d - 1) + 1;
        final result = _FractionValue((w1 + w2) * d + a + b, d).simplified();
        return _answerFractionQuestion(
          type,
          'Adding mixed numbers with like denominators.',
          '$w1 $a/$d + $w2 $b/$d = ___',
          result,
          preferMixed: true,
        );
      case _FractionQuestionType.completeWholeImproper:
        final d = _randDenominator(max: 12);
        final a = _random.nextInt(d - 1) + 1;
        final targetWhole = _random.nextInt(3) + 2;
        final missing = _FractionValue(targetWhole * d - a, d).simplified();
        return _answerFractionQuestion(
          type,
          'Completing whole numbers: improper fractions.',
          '$a/$d + ___ = $targetWhole',
          missing,
          preferMixed: true,
        );
      case _FractionQuestionType.completeWholeMixed:
        final d = _randDenominator(max: 12);
        final whole = _random.nextInt(3) + 1;
        final a = _random.nextInt(d - 1) + 1;
        final targetWhole = whole + 1;
        final missing = _FractionValue(targetWhole * d - (whole * d + a), d).simplified();
        return _answerFractionQuestion(
          type,
          'Completing whole numbers: mixed numbers.',
          '$whole $a/$d + ___ = $targetWhole',
          missing,
          preferMixed: true,
        );
      case _FractionQuestionType.subtractLike:
        final d = _randDenominator(max: 12);
        final a = _random.nextInt(d - 1) + 2;
        final b = _random.nextInt(a - 1) + 1;
        return _answerFractionQuestion(
          type,
          'Subtracting like fractions.',
          '$a/$d - $b/$d = ___',
          _FractionValue(a - b, d),
        );
      case _FractionQuestionType.subtractImproperLike:
        final d = _randDenominator(max: 12);
        final a = d + _random.nextInt(d) + 1;
        final b = _random.nextInt(d) + 1;
        return _answerFractionQuestion(
          type,
          'Subtracting improper fractions with like denominators.',
          '$a/$d - $b/$d = ___',
          _FractionValue(a - b, d),
          preferMixed: true,
        );
      case _FractionQuestionType.subtractFromWhole:
        final d = _randDenominator(max: 12);
        final whole = _random.nextInt(6) + 2;
        final a = _random.nextInt(d - 1) + 1;
        return _answerFractionQuestion(
          type,
          'Subtracting a fraction from a whole number.',
          '$whole - $a/$d = ___',
          _FractionValue(whole * d - a, d),
          preferMixed: true,
        );
      case _FractionQuestionType.subtractFromMixed:
        final d = _randDenominator(max: 12);
        final whole = _random.nextInt(5) + 2;
        final a = _random.nextInt(d - 1) + 1;
        final b = _random.nextInt(a) + 1;
        return _answerFractionQuestion(
          type,
          'Subtracting a fraction from a mixed number.',
          '$whole $a/$d - $b/$d = ___',
          _FractionValue(whole * d + a - b, d),
          preferMixed: true,
        );
      case _FractionQuestionType.subtractMixedFromWhole:
        final d = _randDenominator(max: 12);
        final whole = _random.nextInt(5) + 6;
        final answerWhole = _random.nextInt(whole - 2) + 1;
        final a = _random.nextInt(d - 1) + 1;
        final missing = _FractionValue((whole - answerWhole) * d - a, d).simplified();
        return _answerFractionQuestion(
          type,
          'Subtract a mixed number from a whole number.',
          '$whole - ___ = $answerWhole $a/$d',
          missing,
          preferMixed: true,
        );
      case _FractionQuestionType.subtractMixedLike:
        final d = _randDenominator(max: 12);
        final w1 = _random.nextInt(5) + 5;
        final w2 = _random.nextInt(3) + 1;
        final a = _random.nextInt(d - 1) + 1;
        final b = _random.nextInt(d - 1) + 1;
        final result = _FractionValue(w1 * d + a - (w2 * d + b), d).simplified();
        return _answerFractionQuestion(
          type,
          'Subtract mixed numbers with like denominators.',
          '$w1 $a/$d - $w2 $b/$d = ___',
          result,
          preferMixed: true,
        );
      case _FractionQuestionType.mixedToFraction:
        final d = _randDenominator(max: 10);
        final whole = _random.nextInt(8) + 2;
        final a = _random.nextInt(d - 1) + 1;
        final answer = _FractionValue(whole * d + a, d).simplified();
        return _answerFractionQuestion(
          type,
          'Mixed numbers to fractions.',
          '$whole $a/$d = ___',
          answer,
        );
      case _FractionQuestionType.fractionToMixed:
        final d = _randDenominator(max: 10);
        final whole = _random.nextInt(8) + 2;
        final a = _random.nextInt(d - 1) + 1;
        final improper = _FractionValue(whole * d + a, d);
        final answer = improper.simplified();
        return _answerFractionQuestion(
          type,
          'Fractions to mixed numbers.',
          '${improper.numerator}/$d = ___',
          answer,
          preferMixed: true,
        );
      case _FractionQuestionType.decimalToMixed:
        final whole = _random.nextInt(8) + 1;
        final tenths = _random.nextInt(9) + 1;
        final fraction = _FractionValue(whole * 10 + tenths, 10).simplified();
        return _answerFractionQuestion(
          type,
          'Decimals to mixed numbers.',
          '$whole.$tenths = ___',
          fraction,
          preferMixed: true,
        );
      case _FractionQuestionType.fractionToDecimal:
        final denominators = [2, 4, 5, 10];
        final d = denominators[_random.nextInt(denominators.length)];
        final n = _random.nextInt(d - 1) + 1;
        final f = _FractionValue(n, d).simplified();
        final answer = f.asDecimalString();
        return _FractionQuestion(
          type: type,
          instruction: 'Fractions to decimals.',
          expression: '${f.asFractionString()} = ___',
          correctAnswer: answer,
          acceptedAnswers: [answer],
        );
      case _FractionQuestionType.mixedToDecimal:
        final whole = _random.nextInt(5) + 1;
        final tenths = _random.nextInt(9) + 1;
        final f = _FractionValue(whole * 10 + tenths, 10).simplified();
        final answer = '$whole.$tenths';
        return _FractionQuestion(
          type: type,
          instruction: 'Mixed numbers to decimals.',
          expression: '${f.asMixedString()} = ___',
          correctAnswer: answer,
          acceptedAnswers: [answer],
        );
    }
  }

  _FractionValue _mixedFraction(int whole) {
    final d = _randDenominator(max: 10);
    final n = _random.nextInt(d - 1) + 1;
    return _FractionValue(whole * d + n, d).simplified();
  }

  _FractionQuestion _answerFractionQuestion(
    _FractionQuestionType type,
    String instruction,
    String expression,
    _FractionValue answer, {
    bool preferMixed = false,
  }) {
    final simple = answer.simplified();
    final accepted = <String>{
      simple.asFractionString(),
      simple.asMixedString(),
    };
    if (simple.denominator == 1) accepted.add(simple.numerator.toString());
    return _FractionQuestion(
      type: type,
      instruction: instruction,
      expression: expression,
      correctAnswer: preferMixed ? simple.asMixedString() : simple.asFractionString(),
      acceptedAnswers: accepted.toList(),
    );
  }

  _FractionQuestion _compareQuestion(
    _FractionQuestionType type,
    _FractionValue left,
    _FractionValue right,
    String instruction, {
    bool withPie = false,
    String? leftLabel,
    String? rightLabel,
  }) {
    final symbol = left.value > right.value
        ? '>'
        : left.value < right.value
            ? '<'
            : '=';
    final leftText = leftLabel ?? left.asFractionString();
    final rightText = rightLabel ?? right.asFractionString();
    return _FractionQuestion(
      type: type,
      instruction: instruction,
      expression: '$leftText  ___  $rightText',
      correctAnswer: symbol,
      acceptedAnswers: [symbol],
      leftFraction: withPie ? left : null,
      rightFraction: withPie ? right : null,
      leftLabel: leftText,
      rightLabel: rightText,
    );
  }

  int _timeLimitForLevel() {
    if (level <= 2) return 20;
    if (level <= 4) return 18;
    if (level <= 6) return 16;
    return 14;
  }

  String _questionTypeLabel() {
    final text = currentQuestion.type.name;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (char.toUpperCase() == char && RegExp(r'[A-Z]').hasMatch(char)) {
        buffer.write(' $char');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  void appendInput(String value) {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    if (input.length >= 16 && value != 'BACK') return;

    setState(() {
      if (value == 'BACK') {
        if (input.isNotEmpty) input = input.substring(0, input.length - 1);
      } else if (value == 'SPACE') {
        if (input.isNotEmpty && !input.endsWith(' ')) input += ' ';
      } else if (value == '.') {
        final lastToken = input.split(RegExp(r'[ /]')).last;
        if (!lastToken.contains('.')) input += value;
      } else if (value == '/') {
        if (input.isNotEmpty && !input.endsWith('/') && !input.split(' ').last.contains('/')) {
          input += value;
        }
      } else if (value == '<' || value == '>' || value == '=') {
        input = value;
      } else {
        input += value;
      }
    });
  }

  void clearInput() {
    if (isGameOver) return;
    SoundService().playButtonSoundNow();
    setState(() => input = '');
  }

  void submitInput() {
    if (isGameOver || input.trim().isEmpty) return;
    SoundService().playButtonSoundNow();

    if (_isCorrectAnswer(input)) {
      SoundService().playCorrectSound();
      final nextScore = score + 10 + ((level - 1) * 2);
      final nextLevel = (nextScore ~/ 50) + 1;
      final didLevelUp = nextLevel > level;

      setState(() {
        score = nextScore;
        if (didLevelUp) level = nextLevel;
        showCorrectSplash = true;
        isGameOver = true;
      });

      Future.delayed(_correctFeedbackDuration, () {
        if (!mounted) return;
        setState(() => showCorrectSplash = false);

        if (didLevelUp) {
          showLevelUpPage();
        } else {
          setState(() => isGameOver = false);
          generateQuestion();
        }
      });
      return;
    }

    _handleIncorrect(input.trim());
  }

  bool _isCorrectAnswer(String value) {
    final normalizedInput = _normalizeAnswer(value);
    return currentQuestion.acceptedAnswers
        .map(_normalizeAnswer)
        .contains(normalizedInput);
  }

  String _normalizeAnswer(String value) {
    return value
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  void _handleTimeout() {
    if (isGameOver) return;
    _handleIncorrect('Time out');
  }

  void _handleIncorrect(String incorrectAnswer) {
    SoundService().playIncorrectSplashSound();
    setState(() {
      hearts--;
      isGameOver = true;
      showIncorrectSplash = true;
    });

    unawaited(saveScore().catchError((Object error) {
      debugPrint('Error saving Fractions score: $error');
    }));

    Future.delayed(_incorrectFeedbackDuration, () {
      if (!mounted) return;
      setState(() => showIncorrectSplash = false);
      showGameOverScreen(incorrectAnswer);
    });
  }

  void showLevelUpPage() {
    isGameOver = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpPopup(
        newLevel: level,
        message:
            'Great fraction skills!\nMore equivalent, comparing, and mixed-number challenges are coming.',
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            isGameOver = false;
            timerKey = UniqueKey();
          });
          generateQuestion();
        },
      ),
    );
  }

  void showGameOverScreen(String incorrectAnswer) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverPopup(
        incorrectAnswer: incorrectAnswer,
        correctAnswer: currentQuestion.correctAnswer,
        heartsRemaining: hearts,
        score: hearts <= 0 ? score : null,
        level: hearts <= 0 ? level : null,
        onRetry: () {
          Navigator.pop(context);
          if (hearts <= 0) {
            startGame();
          } else {
            setState(() {
              input = '';
              timerKey = UniqueKey();
              isGameOver = false;
            });
            generateQuestion();
          }
        },
        onBack: () {
          Navigator.pop(context);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  bool _shouldConfirmExit() {
    return hasStarted &&
        !_showExitConfirmation &&
        !showCorrectSplash &&
        !showIncorrectSplash &&
        !isGameOver;
  }

  void _showExitConfirmationOverlay() {
    if (!_shouldConfirmExit()) return;
    SoundService().playButtonSoundNow();
    setState(() {
      isGameOver = true;
      _showExitConfirmation = true;
    });
  }

  void _cancelExitConfirmation() {
    SoundService().playButtonSoundNow();
    if (!mounted) return;
    setState(() {
      _showExitConfirmation = false;
      isGameOver = false;
      timerKey = UniqueKey();
    });
  }

  Future<void> _confirmExitFromBack() async {
    SoundService().playButtonSoundNow();
    try {
      await LeaveAttemptLogger.logAttempt(
        gameName: _gameName,
        reason: 'player_pressed_back_while_playing',
        source: 'back_button',
        details: {
          'score': score,
          'level': level,
        },
      );
    } catch (error) {
      debugPrint('Leave attempt log failed: $error');
    }
    await saveScore();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> saveScore() async {
    if (_isSavingScore) return;
    _isSavingScore = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);

      await GameLogger.logGame(gameName: _gameName, score: score);

      final snapshot = await userRef.get();
      final previousHighscore = snapshot.data()?['fractions_highscore'];
      final currentHighscore = previousHighscore is num
          ? previousHighscore.toInt()
          : 0;

      await userRef.set({
        'fractions_last_score': score,
        'fractions_last_level': level,
        'fractions_last_played': FieldValue.serverTimestamp(),
        if (score > currentHighscore) 'fractions_highscore': score,
      }, SetOptions(merge: true));

      if (score > 0) {
        await updateLeaderboardEntry(gameName: _gameName, newScore: score);
      }
    } catch (error) {
      debugPrint('Error in saveScore (Fractions): $error');
    } finally {
      _isSavingScore = false;
    }
  }

  Future<void> _onBackPressed() async {
    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    SoundService().playButtonSoundNow();
    if (hasStarted && score > 0) {
      await saveScore();
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _onBackPressed,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            title: const Text('Fractions'),
          ),
          body: Stack(
            children: [
              _buildBackground(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: hasStarted ? _buildGameUI() : _buildStartPanel(),
                  ),
                ),
              ),
              if (_showExitConfirmation)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Leave game?',
                    message: 'Your current progress in this game will be lost.',
                    onOk: _confirmExitFromBack,
                    onBack: _cancelExitConfirmation,
                    okText: 'Leave',
                    backText: 'Stay',
                  ),
                ),
              if (showCorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CorrectSplash(duration: _correctFeedbackDuration),
                  ),
                ),
              if (showIncorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: IncorrectSplash(duration: _incorrectFeedbackDuration),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: _inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _inkColor,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      duration: const Duration(seconds: 20),
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-34, -22),
          drift: Offset(16, 11),
          size: 124,
          color: Color(0x304CAF50),
          borderColor: Color(0x4A2F5233),
          initialRotation: -0.12,
          symbol: '1/2',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 28,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topRight,
          baseOffset: Offset(30, 80),
          drift: Offset(12, 15),
          size: 112,
          color: Color(0x30FF9800),
          borderColor: Color(0x4A2F5233),
          initialRotation: 0.22,
          symbol: '3/4',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 30,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(32, 34),
          drift: Offset(13, 14),
          size: 122,
          color: Color(0x2A4CAF50),
          borderColor: Color(0x402F5233),
          symbol: '0.5',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 26,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(20, 26),
          drift: Offset(11, 12),
          size: 100,
          color: Color(0x28FF9800),
          borderColor: Color(0x402F5233),
          symbol: '>',
          contentColor: Color(0xFF2F5233),
          cornerRadius: 24,
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStartPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: _card(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 128,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _inkColor, width: 2.2),
                ),
                child: const Text(
                  '3/4 + 1/4',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _inkColor,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Fractions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Solve fraction equations, compare values, simplify answers, and convert fractions using pure math.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: _inkColor,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    SoundService().playButtonSoundNow();
                    startGame();
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Fractions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen.height;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;
        final isVeryShort = availableHeight < 680;
        final padHeight = (availableHeight * (isVeryShort ? 0.34 : 0.40))
            .clamp(220.0, 340.0)
            .toDouble();

        return ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(child: _statPill('Score', '$score', Icons.stars_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _statPill('Level', '$level', Icons.trending_up_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _statPill('Mode', _questionTypeLabel(), Icons.pie_chart_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            _card(
              padding: const EdgeInsets.all(10),
              child: GameTimer(
                key: timerKey,
                seconds: timeLimit,
                isPaused: () => isGameOver,
                onTimeUp: _handleTimeout,
                showBar: true,
              ),
            ),
            const SizedBox(height: 8),
            HeartsDisplay(hearts: hearts),
            const SizedBox(height: 8),
            _card(
              padding: EdgeInsets.fromLTRB(
                availableWidth < 380 ? 12 : 18,
                availableHeight < 680 ? 12 : 16,
                availableWidth < 380 ? 12 : 18,
                availableHeight < 680 ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentQuestion.instruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: availableWidth < 380 ? 15 : 17,
                      fontWeight: FontWeight.w800,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currentQuestion.expression,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: availableWidth < 380 ? 27 : 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: _inkColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _answerBox(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: padHeight,
              child: _buildFractionPad(),
            ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  bool get _hasVisual {
    return currentQuestion.pieNumerator != null ||
        currentQuestion.setTotal != null ||
        currentQuestion.leftFraction != null;
  }

  // ignore: unused_element
  Widget _buildVisualIfNeeded() {
    if (currentQuestion.pieNumerator != null && currentQuestion.pieDenominator != null) {
      return SizedBox(
        height: 126,
        child: Center(
          child: CustomPaint(
            size: const Size(116, 116),
            painter: _PieFractionPainter(
              numerator: currentQuestion.pieNumerator!,
              denominator: currentQuestion.pieDenominator!,
              fillColor: _accentColor,
              lineColor: _inkColor,
            ),
          ),
        ),
      );
    }

    if (currentQuestion.setTotal != null && currentQuestion.setColored != null) {
      return _SetFractionView(
        total: currentQuestion.setTotal!,
        colored: currentQuestion.setColored!,
        accentColor: _accentColor,
        inkColor: _inkColor,
      );
    }

    if (currentQuestion.leftFraction != null && currentQuestion.rightFraction != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PieWithLabel(
            fraction: currentQuestion.leftFraction!,
            label: currentQuestion.leftLabel ?? currentQuestion.leftFraction!.asFractionString(),
            accentColor: _accentColor,
            inkColor: _inkColor,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: _inkColor,
              ),
            ),
          ),
          _PieWithLabel(
            fraction: currentQuestion.rightFraction!,
            label: currentQuestion.rightLabel ?? currentQuestion.rightFraction!.asFractionString(),
            accentColor: _accentColor,
            inkColor: _inkColor,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEFFAFFF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _inkColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242C3550),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _inkColor,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _inkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6DFEB), width: 2),
      ),
      child: Text(
        input.isEmpty ? 'Your Answer' : input,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: input.isEmpty ? 21 : 32,
          fontWeight: FontWeight.w900,
          color: input.isEmpty ? const Color(0xFF6F7A6D) : _inkColor,
        ),
      ),
    );
  }

  Widget _buildFractionPad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height * 0.38;

        final panelWidth = min(availableWidth * 0.98, 720.0)
            .clamp(300.0, 720.0)
            .toDouble();
        final targetHeight = min(availableHeight * 0.98, 340.0);
        final panelHeight = min(max(220.0, targetHeight), availableHeight)
            .toDouble();

        return Align(
          alignment: Alignment.topCenter,
          child: _FractionAnswerPad(
            input: input,
            isDisabled: isGameOver,
            onTap: appendInput,
            onClear: clearInput,
            onSubmit: submitInput,
            panelWidth: panelWidth,
            panelHeight: panelHeight,
          ),
        );
      },
    );
  }
}

class _FractionAnswerPad extends StatelessWidget {
  final String input;
  final bool isDisabled;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final double panelWidth;
  final double panelHeight;

  const _FractionAnswerPad({
    required this.input,
    required this.isDisabled,
    required this.onTap,
    required this.onClear,
    required this.onSubmit,
    required this.panelWidth,
    required this.panelHeight,
  });

  @override
  Widget build(BuildContext context) {
    final width = panelWidth.clamp(280.0, 760.0).toDouble();
    final height = panelHeight.clamp(220.0, 360.0).toDouble();
    final padding = (width * 0.022).clamp(6.0, 12.0).toDouble();
    final spacing = (width * 0.012).clamp(3.0, 7.0).toDouble();
    final contentWidth = width - padding * 2;

    final rows = const [
      ['1', '2', '3', '/'],
      ['4', '5', '6', 'SPACE'],
      ['7', '8', '9', '.'],
      ['<', '0', '>', '='],
      ['BACK', 'C', '→'],
    ];

    final keyWidth = ((contentWidth - spacing * 3) / 4).clamp(44.0, 152.0).toDouble();
    final keyHeight = ((height - padding * 2 - spacing * (rows.length - 1)) / rows.length)
        .clamp(28.0, 62.0)
        .toDouble();
    final fontSize = (min(keyWidth, keyHeight) * 0.44).clamp(15.0, 30.0).toDouble();

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular((width * 0.04).clamp(16.0, 28.0).toDouble()),
          border: Border.all(color: const Color(0x1F000000), width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows.length; r++) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < rows[r].length; i++) ...[
                        _button(rows[r][i], keyWidth, keyHeight, fontSize),
                        if (i != rows[r].length - 1) SizedBox(width: spacing),
                      ],
                    ],
                  ),
                  if (r != rows.length - 1) SizedBox(height: spacing),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label, double width, double height, double fontSize) {
    final display = switch (label) {
      'SPACE' => 'space',
      'BACK' => '⌫',
      _ => label,
    };
    final action = switch (label) {
      'C' => onClear,
      '→' => onSubmit,
      'SPACE' => () => onTap('SPACE'),
      'BACK' => () => onTap('BACK'),
      _ => () => onTap(label),
    };

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : action,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((height * 0.26).clamp(8.0, 16.0).toDouble()),
          ),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(display),
          ),
        ),
      ),
    );
  }
}

class _PieWithLabel extends StatelessWidget {
  final _FractionValue fraction;
  final String label;
  final Color accentColor;
  final Color inkColor;

  const _PieWithLabel({
    required this.fraction,
    required this.label,
    required this.accentColor,
    required this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    final properNumerator = fraction.numerator % fraction.denominator;
    final displayNumerator = properNumerator == 0 ? fraction.denominator : properNumerator;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(78, 78),
          painter: _PieFractionPainter(
            numerator: displayNumerator,
            denominator: fraction.denominator,
            fillColor: accentColor,
            lineColor: inkColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: inkColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SetFractionView extends StatelessWidget {
  final int total;
  final int colored;
  final Color accentColor;
  final Color inkColor;

  const _SetFractionView({
    required this.total,
    required this.colored,
    required this.accentColor,
    required this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: i < colored ? accentColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: inkColor, width: 2),
            ),
          ),
      ],
    );
  }
}

class _PieFractionPainter extends CustomPainter {
  final int numerator;
  final int denominator;
  final Color fillColor;
  final Color lineColor;

  const _PieFractionPainter({
    required this.numerator,
    required this.denominator,
    required this.fillColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shadedPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, basePaint);

    final sliceAngle = (2 * pi) / denominator;
    final shadedSlices = numerator.clamp(0, denominator).toInt();
    for (var i = 0; i < shadedSlices; i++) {
      canvas.drawArc(rect, -pi / 2 + i * sliceAngle, sliceAngle, true, shadedPaint);
    }

    canvas.drawCircle(center, radius, linePaint);
    for (var i = 0; i < denominator; i++) {
      final angle = -pi / 2 + i * sliceAngle;
      final end = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawLine(center, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PieFractionPainter oldDelegate) {
    return oldDelegate.numerator != numerator ||
        oldDelegate.denominator != denominator ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.lineColor != lineColor;
  }
}
