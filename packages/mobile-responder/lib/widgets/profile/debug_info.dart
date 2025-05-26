import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DebugInfo extends StatelessWidget {
  final bool notificationEnabled;

  const DebugInfo({
    super.key,
    required this.notificationEnabled,
  });

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
    return ExpansionTile(
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.data ?? '토큰 없음',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '알림 상태: ${notificationEnabled ? "켜짐" : "꺼짐"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
