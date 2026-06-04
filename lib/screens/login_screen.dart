import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum _Mode { signIn, signUp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  _Mode _mode = _Mode.signIn;
  bool _loading = false;
  bool _obscurePassword = true;

  String? _error;
  String? _actionLabel;
  VoidCallback? _onAction;
  String? _successMessage;

  // ── error parsing ────────────────────────────────────────────────────────

  void _setError(String msg, {String? actionLabel, VoidCallback? onAction}) {
    setState(() {
      _error = msg;
      _actionLabel = actionLabel;
      _onAction = onAction;
    });
  }

  void _clearFeedback() {
    _error = null;
    _actionLabel = null;
    _onAction = null;
    _successMessage = null;
  }

  String _parseSignInError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) return '__unconfirmed__';
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many sign-in attempts. Wait a moment and try again.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Sign-in failed. Please try again.';
  }

  String _parseSignUpError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return '__already_registered__';
    }
    if (msg.contains('password should be') || msg.contains('weak_password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid format')) {
      return 'Enter a valid email address.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Sign-up failed. Please try again.';
  }

  String _parseForgotError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid format')) {
      return 'Enter a valid email address.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many requests. Wait a moment and try again.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    return 'Failed to send reset email. Please try again.';
  }

  // ── actions ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _clearFeedback();
    });
    try {
      switch (_mode) {
        case _Mode.signIn:
          await _auth.signIn(_email.text.trim(), _password.text.trim());
          // AuthGate stream handles navigation on success — no setState needed.
          break;

        case _Mode.signUp:
          await _auth.signUp(_email.text.trim(), _password.text.trim());
          if (mounted) {
            setState(
              () => _successMessage =
                  'We sent a confirmation email to ${_email.text.trim()}.\n'
                  'Open the link inside to activate your account, then sign in.',
            );
          }
          break;

        case _Mode.forgotPassword:
          await _auth.resetPassword(_email.text.trim());
          if (mounted) {
            setState(
              () => _successMessage =
                  'Password reset link sent to ${_email.text.trim()}.\n'
                  'Check your inbox (and spam folder).',
            );
          }
          break;
      }
    } catch (e) {
      if (!mounted) return;
      switch (_mode) {
        case _Mode.signIn:
          final parsed = _parseSignInError(e);
          if (parsed == '__unconfirmed__') {
            _setError(
              "Your email hasn't been confirmed yet.",
              actionLabel: 'Resend confirmation email',
              onAction: _resendConfirmation,
            );
          } else {
            _setError(parsed);
          }
          break;
        case _Mode.signUp:
          final parsed = _parseSignUpError(e);
          if (parsed == '__already_registered__') {
            _setError(
              'An account with this email already exists.',
              actionLabel: 'Sign in instead',
              onAction: () => _switchMode(_Mode.signIn),
            );
          } else {
            _setError(parsed);
          }
          break;
        case _Mode.forgotPassword:
          _setError(_parseForgotError(e));
          break;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendConfirmation() async {
    setState(() {
      _loading = true;
      _clearFeedback();
    });
    try {
      await _auth.resendConfirmation(_email.text.trim());
      if (mounted) {
        setState(
          () => _successMessage =
              'Confirmation email resent to ${_email.text.trim()}.\n'
              'Check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        _setError('Could not resend the email. Try again in a moment.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _clearFeedback();
    });
  }

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── branding ──────────────────────────────────────────
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 64,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GymTracker',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _subtitle,
                        key: ValueKey(_mode),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── success state ─────────────────────────────────────
                    if (_successMessage != null) ...[
                      _FeedbackBanner(
                        color: Colors.green,
                        icon: _mode == _Mode.forgotPassword
                            ? Icons.lock_reset_outlined
                            : Icons.mark_email_read_outlined,
                        message: _successMessage!,
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to sign in'),
                        onPressed: () => _switchMode(_Mode.signIn),
                      ),
                    ],

                    // ── form ──────────────────────────────────────────────
                    if (_successMessage == null) ...[
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email
                            TextFormField(
                              controller: _email,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: _mode == _Mode.forgotPassword
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: _mode == _Mode.forgotPassword
                                  ? (_) {
                                      if (!_loading) _submit();
                                    }
                                  : null,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            // Password (hidden in forgot-password mode)
                            if (_mode != _Mode.forgotPassword) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) {
                                  if (!_loading) _submit();
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (_mode == _Mode.signUp && v.length < 6) {
                                    return 'Must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Error banner
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              alignment: Alignment.topCenter,
                              child: _error != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _FeedbackBanner(
                                        color: cs.error,
                                        icon: Icons.error_outline,
                                        message: _error!,
                                        onBackground: cs.errorContainer,
                                        textColor: cs.onErrorContainer,
                                        actionLabel: _actionLabel,
                                        onAction: _onAction,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Submit button
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: cs.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        _buttonLabel,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNavLinks(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _subtitle => switch (_mode) {
    _Mode.signIn => 'Welcome back',
    _Mode.signUp => 'Create your account',
    _Mode.forgotPassword => 'Reset your password',
  };

  String get _buttonLabel => switch (_mode) {
    _Mode.signIn => 'Sign in',
    _Mode.signUp => 'Create account',
    _Mode.forgotPassword => 'Send reset link',
  };

  Widget _buildNavLinks() => switch (_mode) {
    _Mode.signIn => Column(
      children: [
        TextButton(
          onPressed: () => _switchMode(_Mode.forgotPassword),
          child: const Text('Forgot password?'),
        ),
        TextButton(
          onPressed: () => _switchMode(_Mode.signUp),
          child: const Text("Don't have an account? Sign up"),
        ),
      ],
    ),
    _Mode.signUp => TextButton(
      onPressed: () => _switchMode(_Mode.signIn),
      child: const Text('Already have an account? Sign in'),
    ),
    _Mode.forgotPassword => TextButton(
      onPressed: () => _switchMode(_Mode.signIn),
      child: const Text('Back to sign in'),
    ),
  };
}

// ── shared feedback banner ────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.onBackground,
    this.textColor,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String message;
  final Color? onBackground;
  final Color? textColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final bg = onBackground ?? color.withValues(alpha: 0.1);
    final fg = textColor ?? color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
