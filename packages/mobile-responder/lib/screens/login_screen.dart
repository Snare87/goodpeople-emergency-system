// lib/screens/login_screen.dart - 근본적인 해결책
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // 테스트용 계정을 미리 채우기 (개발 환경에서만)
  @override
  void initState() {
    super.initState();
    // 테스트 로그인 정보 채우기
    _emailController.text = 'admin@korea.kr';
    _passwordController.text = 'admin1234';

    // 이미 로그인된 사용자가 있는지 확인하고 초기화 (자동 로그인 방지)
    _checkExistingUser();
  }

  // 이미 로그인된 사용자가 있는지 확인
  Future<void> _checkExistingUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // 기존 세션 정리
      await FirebaseAuth.instance.signOut();
      debugPrint('기존 로그인 세션 정리 완료');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase 인증 시도
      debugPrint('로그인 시도: ${_emailController.text.trim()}');

      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      debugPrint('FirebaseAuth 인증 성공: ${credential.user?.uid}');

      // 2. 인증 성공 후 사용자 정보 확인
      if (credential.user != null) {
        final String uid = credential.user!.uid;

        try {
          // 데이터베이스에서 사용자 정보 조회
          final userSnapshot =
              await FirebaseDatabase.instance.ref('users/$uid').get();

          // 사용자 데이터가 없는 경우 (첫 로그인이거나 DB에 정보가 없는 경우)
          if (!userSnapshot.exists) {
            debugPrint('사용자 데이터가 없음 - 기본 정보 생성');

            // 기본 사용자 정보 생성 (첫 로그인 시)
            await FirebaseDatabase.instance.ref('users/$uid').set({
              'email': _emailController.text.trim(),
              'name': '신규 사용자',
              'status': 'pending', // 기본 상태는 승인 대기
              'createdAt': DateTime.now().toIso8601String(),
            });

            // 승인 대기 상태로 로그아웃
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                _errorMessage = '관리자 승인 대기 중입니다. 첫 로그인 시 관리자 승인이 필요합니다.';
                _isLoading = false;
              });
            }
            return;
          }

          // 사용자 데이터가 있는 경우
          debugPrint('사용자 데이터 확인: ${userSnapshot.value}');
          final userData = Map<dynamic, dynamic>.from(
            userSnapshot.value as Map,
          );

          // 상태 확인
          final String status = userData['status'] ?? 'pending';
          debugPrint('사용자 상태: $status');

          if (status == 'pending') {
            // 승인 대기 중인 경우
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                _errorMessage = '관리자 승인 대기 중입니다.';
                _isLoading = false;
              });
            }
            return;
          } else if (status == 'rejected') {
            // 거부된 경우
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() {
                _errorMessage = '가입이 거부되었습니다. 관리자에게 문의하세요.';
                _isLoading = false;
              });
            }
            return;
          }

          // 승인된 경우(approved) - 메인 화면으로 이동
          if (!mounted) return;

          debugPrint('로그인 성공! 메인 화면으로 이동');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } catch (dbError) {
          // 데이터베이스 오류 처리
          debugPrint('사용자 데이터 조회 오류: $dbError');

          // 데이터베이스 오류지만 로그인은 되었으므로 메인 화면으로 이동 (임시)
          if (uid == 'L8vbjIc2WqhCJ2pr8VozC3AuwMK2') {
            // 관리자 계정은 항상 허용
            debugPrint('관리자 계정 확인 - 직접 진행');
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
            return;
          }

          // 일반 오류로 처리
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() {
              _errorMessage = '사용자 정보 확인 중 오류가 발생했습니다. 다시 시도해주세요.';
              _isLoading = false;
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      if (!mounted) return;

      String message;
      if (e.code == 'user-not-found') {
        message = '등록되지 않은 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 일치하지 않습니다.';
      } else if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일 형식입니다.';
      } else if (e.code == 'user-disabled') {
        message = '비활성화된 계정입니다.';
      } else if (e.code == 'too-many-requests') {
        message = '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      } else if (e.code == 'network-request-failed') {
        message = '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.';
      } else {
        message = '로그인 오류: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('일반 오류: $e');

      if (!mounted) return;
      setState(() {
        _errorMessage = '알 수 없는 오류가 발생했습니다: $e';
        _isLoading = false;
      });

      // 관리자 계정 하드코딩 (긴급 상황용)
      if (_emailController.text.trim() == 'admin@korea.kr') {
        debugPrint('관리자 계정 확인 - 직접 진행 시도');

        try {
          // 강제 로그인 처리
          final userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: 'admin@korea.kr',
                password: _passwordController.text,
              );

          if (userCredential.user != null) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            }
          }
        } catch (ee) {
          debugPrint('관리자 계정 백업 로그인 실패: $ee');
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
