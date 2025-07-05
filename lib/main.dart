import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:garage_app/features/Home/data/repository/bluetooth_repo.dart';
import 'package:garage_app/features/Home/presentation/views/bluetooth_home_view.dart';
import 'package:garage_app/features/Home/presentation/manager/bluetooth/bluetooth_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BluetoothCubit(repository: BluetoothRepository())..initialize(),
      child: MaterialApp(
        title: 'Garage Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: const BluetoothHomeView(),
      ),
    );
  }
}
