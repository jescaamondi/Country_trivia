import 'package:country_trivia/core/network/api_client.dart';
import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:country_trivia/data/datasources/country_local_data_source.dart';
import 'package:country_trivia/data/datasources/country_remote_data_source.dart';
import 'package:country_trivia/data/repositories/country_repository_impl.dart';
import 'package:country_trivia/domain/repositories/country_repository.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/pages/game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Composition root: builds the object graph and hands control to the app.
class CountryTriviaApp extends StatefulWidget {
  const CountryTriviaApp({super.key});

  @override
  State<CountryTriviaApp> createState() => _CountryTriviaAppState();
}

class _CountryTriviaAppState extends State<CountryTriviaApp> {
  late final ApiClient _apiClient;
  late final CountryRepository _repository;
  late final GameBloc _gameBloc;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _repository = CountryRepositoryImpl(
      remoteDataSource: HttpCountryRemoteDataSource(_apiClient),
      localDataSource: const BundledCountryLocalDataSource(),
    );
    _gameBloc = GameBloc(getCountries: GetCountries(_repository))
      ..add(const GameStarted());
  }

  @override
  void dispose() {
    _apiClient.close();
    _gameBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<CountryRepository>.value(
      value: _repository,
      child: BlocProvider<GameBloc>.value(
        value: _gameBloc,
        child: MaterialApp(
          title: 'Country Flag Trivia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const GamePage(),
        ),
      ),
    );
  }
}
