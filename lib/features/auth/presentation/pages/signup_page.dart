import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renma/core/routes/app_routes.dart';
import '../widgets/auth_black_button.dart';
import '../widgets/auth_white_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_otp_timer.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  List<List<String>> get _animatedLines => const [
    ['Real News.', 'Real Impact.'],
    ['Quick Briefs.', 'Deep Insights.'],
    ['Swipe News.', 'Get Informed.'],
  ];
  int _currentIndex = 0;
  Timer? _timer;
  Timer? _resendTimer;
  int _resendSeconds = 20;

  bool _otpRequested = false;
  bool _showPhoneInput = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _animatedLines.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _sendOtp() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showMessage('Enter a phone number first.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _otpRequested = true;
      _resendSeconds = 20;
    });
    _startResendTimer();
    _showMessage('OTP sent to $phoneNumber.');
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  void _continue() {
    if (!_otpRequested) {
      _sendOtp();
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      _showMessage('Enter the OTP to continue.');
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  void _continueWithGoogle() {
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/auth_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 42),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 1.5,
                          color: const Color(0xFFB398EB), // purple line
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/logo_favicon.png',
                              height: 56,
                              width: 56,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'RENMA',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 5.0,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // The Main Headline
                  RichText(
                    text: TextSpan(
                      text: 'Scroll Less',
                      style: GoogleFonts.sora(
                        fontSize: 50,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: '.',
                          style: GoogleFonts.sora(
                            color: const Color(0xFFB398EB),
                          ),
                        ),
                        const TextSpan(text: '\nKnow More'),
                        TextSpan(
                          text: '.',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF88E0A0), // Green dot
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 2,
                      color: const Color(0xFFB398EB),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Your swipes may not get you matches,\nbut they can get you knowledge.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 48),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final isIncoming =
                              child.key == ValueKey<int>(_currentIndex);

                          return ClipRect(
                            child: SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: isIncoming
                                        ? const Offset(0, 1)
                                        : const Offset(0, -1),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.linear,
                                    ),
                                  ),
                              child: child,
                            ),
                          );
                        },
                    child: Column(
                      key: ValueKey<int>(_currentIndex),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _animatedLines[_currentIndex][0],
                          style: GoogleFonts.goldman(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB398EB),
                          ),
                        ),
                        Text(
                          _animatedLines[_currentIndex][1],
                          style: GoogleFonts.goldman(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF88E0A0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(_animatedLines.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? const Color(0xFFB398EB)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showPhoneInput
                        ? _buildPhoneInputSection()
                        : _buildInitialButtons(),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialButtons() {
    return Column(
      key: const ValueKey('buttons'),
      children: [
        AuthBlackButton(
          title: 'Continue with Phone Number',
          iconWidget: const Icon(
            Icons.phone_outlined,
            size: 22,
            color: Colors.white,
          ),
          onTap: () {
            setState(() {
              _showPhoneInput = true;
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        AuthWhiteButton(
          title: 'Continue with Google',
          iconWidget: Image.asset('assets/google.webp', height: 22, width: 22),
          onTap: _continueWithGoogle,
        ),
      ],
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      key: const ValueKey('phone_input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _phoneController,
          hint: 'Enter your phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          enabled: !_otpRequested,
        ),
        const SizedBox(height: 16),
        if (_otpRequested) ...[
          AuthTextField(
            controller: _otpController,
            hint: 'Enter OTP',
            icon: Icons.lock_outline,
            keyboardType: TextInputType.number,
          ),
          AuthOtpTimer(resendSeconds: _resendSeconds, onResend: _sendOtp),
          const SizedBox(height: 16),
        ],
        AuthBlackButton(
          title: _otpRequested ? 'Continue' : 'Get OTP',
          iconWidget: const Icon(
            Icons.arrow_forward,
            size: 22,
            color: Colors.white,
          ),
          onTap: _continue,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showPhoneInput = false;
              _otpRequested = false;
              _resendTimer?.cancel();
            });
          },
          child: Text(
            'Back to options',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
