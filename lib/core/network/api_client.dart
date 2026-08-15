import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorageService;

  ApiClient(this._secureStorageService)
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 90),
            sendTimeout: const Duration(seconds: 90),
            receiveTimeout: const Duration(seconds: 90),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          /*
           * Les endpoints publics ne doivent jamais recevoir
           * un ancien token client, chauffeur ou livreur.
           */
          if (_isPublicEndpoint(options.path)) {
            options.headers.remove('Authorization');
            options.headers.remove('authorization');

            return handler.next(options);
          }

          final token = await _secureStorageService.getToken();

          if (token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer ${token.trim()}';
          } else {
            options.headers.remove('Authorization');
            options.headers.remove('authorization');
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              'API ERROR => '
              '${error.requestOptions.method} '
              '${error.requestOptions.uri}',
            );

            debugPrint(
              'STATUS => ${error.response?.statusCode}',
            );

            debugPrint(
              'TYPE => ${error.type}',
            );

            debugPrint(
              'RESPONSE => ${error.response?.data}',
            );

            debugPrint(
              'DETAIL => ${error.error}',
            );
          }

          final statusCode = error.response?.statusCode;
          if (statusCode == 401 && !_isPublicEndpoint(error.requestOptions.path)) {
            debugPrint( 
              'ApiClient: 401 décelé (session expirée/invalide), déconnexion et redirection...',
            );
            final roles = await _secureStorageService.getRoles();
            await _secureStorageService.clearSession();

            if (roles.contains('CHAUFFEUR')) {
              appRouter.go(AppRoutes.chauffeurLogin);
            } else if (roles.contains('LIVREUR')) {
              appRouter.go(AppRoutes.livreurLogin);
            } else {
              appRouter.go(AppRoutes.login);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  bool _isPublicEndpoint(String path) {
    final normalizedPath = path
        .toLowerCase()
        .split('?')
        .first
        .trim();

    return normalizedPath.endsWith('/login') ||
        normalizedPath.endsWith('/register') ||
        normalizedPath.endsWith('/forgot-password') ||
        normalizedPath.endsWith('/reset-password');
  }

  Dio get dio => _dio;
}