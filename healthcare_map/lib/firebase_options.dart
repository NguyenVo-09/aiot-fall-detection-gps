// File này được tạo thủ công từ google-services.json
// Thay thế cho FlutterFire CLI (không cần cài thêm tool)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Để chạy thử được trên Chrome (Web) và Windows bằng config của Android
    return android; 
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLcLjmODx8oOUe26YhATqyb4Jd1fg4ZZs',
    appId: '1:1063871622506:android:1a443eef5c563e47fdc913',
    messagingSenderId: '1063871622506',
    projectId: 'sis-fall',
    storageBucket: 'sis-fall.firebasestorage.app',
  );
}
