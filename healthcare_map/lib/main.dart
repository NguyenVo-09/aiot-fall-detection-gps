import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/firebase_device_repository.dart';
import 'services/device_repository.dart';

void setupDependencies() {
  GetIt.I.registerLazySingleton<DeviceRepository>(() => FirebaseDeviceRepository());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Thiết lập Dependency Injection (GetIt)
  setupDependencies();

  runApp(const HealthcareMapApp());
}

