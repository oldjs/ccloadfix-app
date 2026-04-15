import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/storage/local_storage.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverController.text = LocalStorage.serverUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final serverUrl = _serverController.text.trim();
    final password = _passwordController.text;
    await ref.read(authProvider.notifier).login(serverUrl, password);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 错误弹窗
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: cs.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
        ref.read(authProvider.notifier).clearError();
      }
    });

    // 统一的输入框边框 — 细线条、小圆角
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: cs.onSurface, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: cs.error),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),

                    // 标题 — 纯文字，不要 logo
                    Text(
                      'ccLoadFix',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '登录到管理面板',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 服务器地址
                    Text('服务器地址', style: _labelStyle(cs)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _serverController,
                      decoration: InputDecoration(
                        hintText: 'https://your-server.com',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: focusedBorder,
                        errorBorder: errorBorder,
                        focusedErrorBorder: errorBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        isDense: true,
                      ),
                      style: theme.textTheme.bodyMedium,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return '请输入服务器地址';
                        final trimmed = value.trim();
                        if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                          return '地址需以 http:// 或 https:// 开头';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 密码
                    Text('管理员密码', style: _labelStyle(cs)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: '输入密码',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: focusedBorder,
                        errorBorder: errorBorder,
                        focusedErrorBorder: errorBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      style: theme.textTheme.bodyMedium,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '请输入管理员密码';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // 登录按钮 — 纯色、简洁
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.onSurface,
                          foregroundColor: cs.surface,
                          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        child: authState.isLoading
                            ? SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: cs.surface),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 提示 — 尽量低调
                    Text(
                      '密码来自服务端环境变量 CCLOAD_ADMIN_PASSWORD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 字段标签样式
  TextStyle _labelStyle(ColorScheme cs) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    );
  }
}
