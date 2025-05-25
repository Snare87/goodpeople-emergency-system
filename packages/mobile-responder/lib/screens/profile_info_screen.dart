// lib/screens/profile_info_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // 사용자 정보
  String? _name;
  String? _email;
  String? _department;
  String? _officialId;
  String _selectedRank = '소방사';
  String _selectedPosition = '화재진압대원';
  List<String> _certifications = [];

  // 동의 상태
  bool _notificationEnabled = true;
  bool _locationEnabled = true;
  bool _backgroundNotificationEnabled = true;

  // 옵션 목록
  final List<String> _ranks = ['소방사', '소방교', '소방장', '소방위', '소방경', '소방령', '소방정'];

  final List<String> _positions = ['화재진압대원', '구조대원', '구급대원'];

  final List<String> _availableCertifications = [
    '응급구조사 1급',
    '응급구조사 2급',
    '간호사',
    '화재대응능력 1급',
    '화재대응능력 2급',
    '인명구조사 1급',
    '인명구조사 2급',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot =
          await FirebaseDatabase.instance.ref('users/$userId').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _name = data['name'];
          _email = data['email'];
          _department = data['department'];
          _officialId = data['officialId'];
          _phoneController.text = data['phone'] ?? '';
          _selectedRank = data['rank'] ?? '소방사';
          _selectedPosition = data['position'] ?? '화재진압대원';
          _certifications = List<String>.from(data['certifications'] ?? []);
          _notificationEnabled = data['notificationEnabled'] ?? true;
          _locationEnabled = data['locationEnabled'] ?? true;
          _backgroundNotificationEnabled =
              data['backgroundNotificationEnabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseDatabase.instance.ref('users/$userId').update({
        'phone': _phoneController.text.trim(),
        'rank': _selectedRank,
        'position': _selectedPosition,
        'certifications': _certifications,
        'notificationEnabled': _notificationEnabled,
        'locationEnabled': _locationEnabled,
        'backgroundNotificationEnabled': _backgroundNotificationEnabled,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정보가 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    if (_locationEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationEnabled = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다')));
          }
        }
      }
    }
  }

  // FCM 토큰 확인 함수 추가
  Future<String?> _getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      return await messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보'), backgroundColor: Colors.red),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 기본 정보 (수정 불가)
                      _buildSectionTitle('기본 정보'),
                      _buildInfoCard([
                        _buildInfoRow('이름', _name ?? '-'),
                        _buildInfoRow('이메일', _email ?? '-'),
                        _buildInfoRow('소속', _department ?? '-'),
                        _buildInfoRow('식별번호', _officialId ?? '-'),
                      ]),
                      const SizedBox(height: 24),

                      // 수정 가능한 정보
                      _buildSectionTitle('연락처 및 직무 정보'),

                      // 전화번호
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: '전화번호',
                          hintText: '010-0000-0000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 계급
                      DropdownButtonFormField<String>(
                        value: _selectedRank,
                        decoration: const InputDecoration(
                          labelText: '계급',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.military_tech),
                        ),
                        items:
                            _ranks.map((rank) {
                              return DropdownMenuItem(
                                value: rank,
                                child: Text(rank),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRank = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 직책
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

                      // 자격증
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
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 동의 설정
                      _buildSectionTitle('알림 및 권한 설정'),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              '알림 수신',
                              '재난 호출 알림을 받습니다',
                              Icons.notifications,
                              _notificationEnabled,
                              (value) {
                                setState(() {
                                  _notificationEnabled = value;
                                });
                              },
                            ),
                            const Divider(),
                            _buildSwitchTile(
                              '위치 정보 제공',
                              '현재 위치를 기반으로 가까운 재난 알림을 받습니다',
                              Icons.location_on,
                              _locationEnabled,
                              (value) async {
                                setState(() {
                                  _locationEnabled = value;
                                });
                                if (value) {
                                  await _checkLocationPermission();
                                }
                              },
                            ),
                            const Divider(),
                            _buildSwitchTile(
                              '백그라운드 알림',
                              '앱이 백그라운드에 있을 때도 알림을 받습니다',
                              Icons.notifications_active,
                              _backgroundNotificationEnabled,
                              (value) {
                                setState(() {
                                  _backgroundNotificationEnabled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    '저장하기',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 디버그 정보 (FCM 토큰 표시)
                      ExpansionTile(
                        title: const Text(
                          '디버그 정보',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        children: [
                          FutureBuilder<String?>(
                            future: _getFcmToken(),
                            builder: (context, snapshot) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.grey[100],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FCM 토큰:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      snapshot.data ?? '토큰 없음',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '알림 상태: ${_notificationEnabled ? "켜짐" : "꺼짐"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: value ? Colors.red : Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
