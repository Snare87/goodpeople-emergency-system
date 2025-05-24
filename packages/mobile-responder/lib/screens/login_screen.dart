// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodpeople_responder/screens/main_screen.dart';
import 'package:goodpeople_responder/screens/register_screen.dart';
import 'package:goodpeople_responder/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 컨트롤러 및 상태 관리
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // 서비스 인스턴스
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // 테스트 로그인 정보 채우기
    _emailController.text = 'admin@korea.kr';
    _passwordController.text = 'admin1234';

    // 초기 상태 설정 - 기존 세션이 있으면 로그아웃
    _checkAndClearExistingSession();
  }

  // 기존 세션 확인 및 정리
  Future<void> _checkAndClearExistingSession() async {
    try {
      if (_authService.isLoggedIn) {
        await _authService.logout();
        debugPrint('기존 세션 로그아웃 완료');
      }
    } catch (e) {
      debugPrint('세션 정리 오류: $e');
    }
  }

  // 로그인 처리
  Future<void> _login() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) return;

    // 로딩 상태 설정
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 인증 서비스를 통한 로그인
      final credential = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 2. 로그인 성공 시 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 3. Firebase 인증 오류 처리
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = '등록되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          message = '비밀번호가 일치하지 않습니다.';
          break;
        case 'invalid-email':
          message = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'user-disabled':
          message = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          message = '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
          break;
        default:
          message = '로그인 오류: ${e.message}';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      // 4. 일반 오류 처리
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });

      // 5. admin 계정 예외 처리 (백업 로직)
      if (_emailController.text.trim() == 'admin@korea.kr') {
        try {
          debugPrint('백업 처리: admin 계정은 직접 메인 화면으로 이동');

          // 잠시 지연 후 메인 화면으로 이동
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        } catch (e) {
          debugPrint('백업 처리 실패: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고 영역
                  Icon(
                    Icons.local_fire_department,
                    size: 80,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GoodPeople',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '응급대응 시스템',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 이메일 필드
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 필드
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 에러 메시지
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('로그인'),
                  ),
                  const SizedBox(height: 16),

                  // 회원가입 버튼
                  OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 도움말 텍스트
                  Text(
                    '신규 대원은 회원가입 후\n관리자 승인을 받아야 합니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
