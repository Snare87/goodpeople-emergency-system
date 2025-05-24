// lib/services/auth_service.dart - void 오류 수정됨
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 현재 사용자 확인
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 로그인 메서드
  Future<UserCredential> login(String email, String password) async {
    try {
      // Firebase Authentication으로 직접 로그인
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ 로그인 성공: ${credential.user?.uid}');

      return credential;
    } catch (e) {
      debugPrint('❌ 로그인 실패: $e');
      rethrow; // 오류를 그대로 전달
    }
  }

  // 로그아웃 - Future<void> 유지 (올바른 사용)
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ 로그아웃 성공');
    } catch (e) {
      debugPrint('❌ 로그아웃 실패: $e');
      rethrow;
    }
  }

  // 사용자 정보 확인
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _dbRef.child('users/$uid').get();

      if (snapshot.exists) {
        // 스냅샷 값이 Map인지 확인
        final value = snapshot.value;

        // Map 변환 과정에서 오류 발생 가능성 있음 - 안전하게 처리
        if (value is Map) {
          try {
            // 안전한 방식으로 Map<String, dynamic>으로 변환
            return Map<String, dynamic>.from(
              value.map((key, value) => MapEntry(key.toString(), value)),
            );
          } catch (e) {
            debugPrint('⚠️ 사용자 데이터 변환 오류: $e');
            return null;
          }
        } else {
          debugPrint('⚠️ 사용자 데이터가 Map 형식이 아닙니다: $value');
          return null;
        }
      } else {
        debugPrint('⚠️ 사용자 데이터가 없습니다: $uid');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 사용자 정보 확인 실패: $e');
      return null;
    }
  }

  // 회원가입 메서드
  Future<UserCredential> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ 회원가입 성공: ${credential.user?.uid}');

      return credential;
    } catch (e) {
      debugPrint('❌ 회원가입 실패: $e');
      rethrow;
    }
  }

  // 사용자 프로필 생성
  Future<void> createUserProfile(
    String uid,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _dbRef.child('users/$uid').set(userData);
      debugPrint('✅ 사용자 프로필 생성 성공');
    } catch (e) {
      debugPrint('❌ 사용자 프로필 생성 실패: $e');
      rethrow;
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ 비밀번호 재설정 이메일 전송 성공');
    } catch (e) {
      debugPrint('❌ 비밀번호 재설정 이메일 전송 실패: $e');
      rethrow;
    }
  }

  // 이메일 인증 전송
  void sendEmailVerification() {
    try {
      // void 반환 메서드는 await 없이 호출
      _auth.currentUser?.sendEmailVerification();
      debugPrint('✅ 이메일 인증 전송 성공');
    } catch (e) {
      debugPrint('❌ 이메일 인증 전송 실패: $e');
      // 이 메서드는 Future<void>가 아닌 void를 반환하므로 rethrow 대신 로깅만
    }
  }
}
