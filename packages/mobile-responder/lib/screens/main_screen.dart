import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:goodpeople_responder/screens/home_screen.dart';
import 'package:goodpeople_responder/screens/my_missions_screen.dart';
import 'package:goodpeople_responder/screens/profile_info_screen.dart';
import 'package:goodpeople_responder/screens/login_screen.dart';
import 'package:goodpeople_responder/services/call_data_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _activeMissionCount = 0;

  // 새로고침을 위한 키 (HomeScreen을 다시 빌드하기 위함)
  Key _homeScreenKey = UniqueKey();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
    _listenToActiveMissions();
  }

  void _buildPages() {
    _pages = [
      HomeScreen(key: _homeScreenKey, isTabView: true), // 탭뷰 모드로 설정
      const MyMissionsScreen(),
      const ProfileInfoScreen(),
    ];
  }

  // 진행중인 임무 개수 감지
  void _listenToActiveMissions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    CallDataService().getActiveMissionsStream(userId).listen((missions) {
      if (mounted) {
        setState(() {
          _activeMissionCount = missions.length;
        });
      }
    });
  }

  // 로그아웃 함수
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // 알림 상태 가져오기
  Future<bool> _getNotificationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return true;

    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref('users/$userId/notificationEnabled')
              .get();
      return snapshot.value as bool? ?? true;
    } catch (e) {
      return true;
    }
  }

  // 알림 토글
  Future<void> _toggleNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final currentStatus = await _getNotificationStatus();
      await FirebaseDatabase.instance.ref('users/$userId').update({
        'notificationEnabled': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '알림이 켜졌습니다' : '알림이 꺼졌습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MainScreen] 알림 토글 오류: $e');
    }
  }

  // 새로고침 함수
  void _refreshHomeScreen() {
    setState(() {
      // 키를 변경하여 HomeScreen을 다시 빌드
      _homeScreenKey = UniqueKey();
      _buildPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // 알림 토글 - Switch로 변경
          FutureBuilder<bool>(
            future: _getNotificationStatus(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return Switch(
                value: isEnabled,
                onChanged: (_) => _toggleNotifications(),
                activeColor: Colors.white,
                activeTrackColor: Colors.white24,
              );
            },
          ),
          // 새로고침 버튼 추가 (재난 목록 탭일 때만 표시)
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshHomeScreen,
              tooltip: '새로고침',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.list), label: '재난 목록'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.assignment),
                if (_activeMissionCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_activeMissionCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: '내 임무',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '재난 대응 시스템';
      case 1:
        return '내 임무';
      case 2:
        return '내 정보';
      default:
        return '재난 대응 시스템';
    }
  }
}
