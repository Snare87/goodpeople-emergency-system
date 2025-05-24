// packages/mobile-responder/lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:goodpeople_responder/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _officialIdController = TextEditingController();

  String _selectedDepartment = '전북소방본부';
  String _selectedRank = '소방사';
  String _selectedPosition = '화재진압대원';
  List<String> _certifications = <String>[]; // 명시적 타입 지정

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _departments = <String>['전북소방본부']; // 명시적 타입 지정

  final List<String> _ranks = <String>[
    // 명시적 타입 지정
    '소방사', '소방교', '소방장', '소방위', '소방경', '소방령', '소방정',
  ];

  final List<String> _positions = <String>[
    // 명시적 타입 지정
    '화재진압대원', '구조대원', '구급대원',
  ];

  final List<String> _availableCertifications = <String>[
    // 명시적 타입 지정
    '응급구조사 1급',
    '응급구조사 2급',
    '간호사',
    '화재대응능력 1급',
    '화재대응능력 2급',
    '인명구조사 1급',
    '인명구조사 2급',
  ];

  String _formatPhoneNumber(String value) {
    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length <= 3) {
      return numbers;
    } else if (numbers.length <= 7) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3)}';
    } else if (numbers.length <= 11) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    } else {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7, 11)}';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('오류'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 회원가입 시작...');

      // 1. Firebase Authentication 계정 생성
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      debugPrint('✅ Authentication 성공: ${credential.user?.uid}');

      // 2. 사용자 데이터 준비 (타입 안전성 100% 확보)
      final String userId = credential.user!.uid;
      final Map<String, dynamic> userData = {
        // 모든 값을 명시적으로 변환하여 타입 안전성 확보
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'officialId': _officialIdController.text.trim(),
        'department': _selectedDepartment,
        'rank': _selectedRank,
        'position': _selectedPosition,
        'certifications':
            _certifications.isEmpty
                ? <String>[]
                : List<String>.from(_certifications),
        'status': 'pending',
        'isOnDuty': false,
        'locationEnabled': false,
        'notificationEnabled': true,
        'createdAt': DateTime.now().toIso8601String(),
        'statistics': {
          'totalMissions': 0,
          'completedMissions': 0,
          'averageResponseTime': 0,
          'specialties': {'화재': 0, '구조': 0, '구급': 0},
        },
      };

      debugPrint('🔍 Database 저장 시작...');
      debugPrint('👤 사용자: ${userData['name']}');
      debugPrint('📧 이메일: ${userData['email']}');

      // 3. Realtime Database에 저장
      await FirebaseDatabase.instance.ref('users/$userId').set(userData);
      debugPrint('✅ Database 저장 완료!');

      // 4. 저장 확인 (선택사항)
      final snapshot =
          await FirebaseDatabase.instance.ref('users/$userId').get();
      if (snapshot.exists) {
        debugPrint('✅ 저장 검증 완료: ${snapshot.value}');
      }

      // 5. 로그아웃 처리 (회원가입 후 관리자 승인 대기)
      await FirebaseAuth.instance.signOut();

      // 6. 성공 다이얼로그
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('회원가입 완료'),
                content: const Text(
                  '회원가입이 완료되었습니다.\n'
                  '관리자 승인 후 서비스를 이용하실 수 있습니다.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Navigator.of(context).pop(); 먼저 다이얼로그 닫기
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth 오류: ${e.code} - ${e.message}');

      setState(() {
        _isLoading = false;
      });

      String message;
      switch (e.code) {
        case 'weak-password':
          message = '비밀번호가 너무 약합니다. 8자 이상 입력해주세요.';
          break;
        case 'email-already-in-use':
          message = '이미 사용중인 이메일입니다.';
          break;
        case 'invalid-email':
          message = '유효하지 않은 이메일 형식입니다.';
          break;
        default:
          message = '회원가입 중 오류가 발생했습니다: ${e.message}';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      debugPrint('❌ 일반 오류: $e');

      setState(() {
        _isLoading = false;
        _errorMessage = '회원가입 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입'), backgroundColor: Colors.red),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'GoodPeople 대원 등록',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

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

                _buildSectionTitle('기본 정보'),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@korea.kr',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    hintText: '8자 이상',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('개인 정보'),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '한글 이름을 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  // inputFormatters 제거 - 한글 입력 문제 해결
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    final trimmedValue = value.trim();
                    if (trimmedValue.replaceAll(' ', '').length < 2) {
                      return '이름은 2자 이상이어야 합니다';
                    }
                    if (trimmedValue.length > 10) {
                      return '이름은 10자 이하로 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    hintText: '010-0000-0000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (value) {
                    final formatted = _formatPhoneNumber(value);
                    if (formatted != value) {
                      _phoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '전화번호를 입력해주세요';
                    }
                    final numbers = value.replaceAll('-', '');
                    if (numbers.length < 10 || numbers.length > 11) {
                      return '올바른 전화번호를 입력해주세요';
                    }
                    if (!numbers.startsWith('01')) {
                      return '01로 시작하는 번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _officialIdController,
                  decoration: const InputDecoration(
                    labelText: '공무원 식별번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '공무원 식별번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('소속 정보'),

                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: '소속 부서',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items:
                      _departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRank,
                  decoration: const InputDecoration(
                    labelText: '계급',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.military_tech),
                  ),
                  items:
                      _ranks.map((rank) {
                        return DropdownMenuItem(value: rank, child: Text(rank));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRank = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedPosition,
                  decoration: const InputDecoration(
                    labelText: '직책',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  items:
                      _positions.map((position) {
                        return DropdownMenuItem(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('보유 자격증'),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children:
                        _availableCertifications.map((cert) {
                          return CheckboxListTile(
                            title: Text(cert),
                            value: _certifications.contains(cert),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!_certifications.contains(cert)) {
                                    _certifications.add(cert);
                                  }
                                } else {
                                  _certifications.remove(cert);
                                }
                              });

                              // 디버깅용 출력
                              debugPrint('🏆 선택된 자격증: $_certifications');
                            },
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('회원가입', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('이미 계정이 있으신가요? 로그인하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _officialIdController.dispose();
    super.dispose();
  }
}
