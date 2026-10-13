import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/main/view/main_wrapper.dart';
import 'features/dashboard/cubit/device_cubit.dart';
import 'features/map/cubit/map_cubit.dart';
import 'services/device_repository.dart';
import 'package:get_it/get_it.dart';

class HealthcareMapApp extends StatelessWidget {
  const HealthcareMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DeviceCubit(GetIt.I<DeviceRepository>()),
        ),
        BlocProvider(
          create: (_) => MapCubit(GetIt.I<DeviceRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Fall Detection App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainWrapper(),
      ),
    );
  }
}
