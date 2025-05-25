import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(isTabView: true), // 탭뷰 모드로 설정
      const MyMissionsScreen(),
      const ProfileInfoScreen(), // 프로필 페이지 추가
    ];
    _listenToActiveMissions();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
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
