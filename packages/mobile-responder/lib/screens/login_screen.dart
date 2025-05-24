// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:goodpeople_responder/screens/main_screen.dart';
import 'package:goodpeople_responder/screens/register_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // 테스트 로그인 정보 채우기
    _emailController.text = 'admin@korea.kr';
    _passwordController.text = 'admin1234';
  }

  // 로그인 처리
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase Auth로 로그인
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      debugPrint('✅ 로그인 성공: ${credential.user?.uid}');

      if (credential.user != null) {
        // 2. 사용자 승인 상태 확인
        final userSnapshot =
            await FirebaseDatabase.instance
                .ref('users/${credential.user!.uid}')
                .get();

        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          final status = userData['status'] ?? 'pending';

          debugPrint('👤 사용자 상태: $status');

          if (status == 'approved') {
            // 승인된 사용자만 메인 화면으로 이동
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            }
          } else if (status == 'pending') {
            // 승인 대기중인 사용자
            await FirebaseAuth.instance.signOut(); // 로그아웃 처리

            setState(() {
              _isLoading = false;
              _errorMessage = '승인 대기중입니다. 관리자 승인 후 이용 가능합니다.';
            });
          } else if (status == 'rejected') {
            // 거부된 사용자
            await FirebaseAuth.instance.signOut(); // 로그아웃 처리

            setState(() {
              _isLoading = false;
              _errorMessage = '계정이 차단되었습니다. 관리자에게 문의하세요.';
            });
          }
        } else {
          // 사용자 정보가 없는 경우
          await FirebaseAuth.instance.signOut();

          setState(() {
            _isLoading = false;
            _errorMessage = '사용자 정보를 찾을 수 없습니다.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth 오류: ${e.code} - ${e.message}');

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
        case 'network-request-failed':
          message = '네트워크 연결을 확인해주세요.';
          break;
        default:
          message = '로그인 실패: ${e.message}';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 일반 오류: $e');
      setState(() {
        _errorMessage = '로그인 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  // 에러 색상 관련 도우미 메서드들
  Color _getErrorColor() {
    if (_errorMessage?.contains('승인 대기') ?? false) {
      return Colors.yellow[50]!;
    } else if (_errorMessage?.contains('차단') ?? false) {
      return Colors.red[50]!;
    }
    return Colors.red[50]!;
  }

  Color _getErrorBorderColor() {
    if (_errorMessage?.contains('승인 대기') ?? false) {
      return Colors.yellow[200]!;
    } else if (_errorMessage?.contains('차단') ?? false) {
      return Colors.red[300]!;
    }
    return Colors.red[200]!;
  }

  Color _getErrorTextColor() {
    if (_errorMessage?.contains('승인 대기') ?? false) {
      return Colors.yellow[800]!;
    } else if (_errorMessage?.contains('차단') ?? false) {
      return Colors.red[800]!;
    }
    return Colors.red[700]!;
  }

  IconData _getErrorIcon() {
    if (_errorMessage?.contains('승인 대기') ?? false) {
      return Icons.schedule;
    } else if (_errorMessage?.contains('차단') ?? false) {
      return Icons.block;
    }
    return Icons.error_outline;
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
                    enabled: !_isLoading,
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
                    enabled: !_isLoading,
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
                        color: _getErrorColor(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getErrorBorderColor()),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getErrorIcon(),
                            color: _getErrorTextColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: _getErrorTextColor()),
                            ),
                          ),
                        ],
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
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
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
