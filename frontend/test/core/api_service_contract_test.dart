import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ContractInterceptor extends Interceptor {
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    final data = options.responseType == ResponseType.bytes
        ? <int>[37, 80, 68, 70, 45, 49]
        : options.path.endsWith('/history')
        ? <Object>[]
        : <String, Object>{'total': 0};
    handler.resolve(Response(requestOptions: options, data: data));
  }
}

class _ErrorInterceptor extends Interceptor {
  final Object data;
  final int statusCode;

  _ErrorInterceptor(this.data, this.statusCode);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException.badResponse(
        statusCode: statusCode,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: data,
        ),
      ),
    );
  }
}

void main() {
  test('history sends the active workspace contract header', () async {
    final interceptor = _ContractInterceptor();
    final api = ApiService(interceptors: [interceptor]);
    api.setActiveWorkspace('42');

    await api.getHistory();

    expect(interceptor.requests.single.headers['X-Workspace-ID'], '42');
    expect(interceptor.requests.single.extra['workspaceScoped'], isTrue);
  });

  test('today summary sends the active workspace contract header', () async {
    final interceptor = _ContractInterceptor();
    final api = ApiService(interceptors: [interceptor]);
    api.setActiveWorkspace('84');

    await api.getTodaySummary();

    expect(interceptor.requests.single.headers['X-Workspace-ID'], '84');
    expect(interceptor.requests.single.extra['workspaceScoped'], isTrue);
  });

  test('PDF bytes use authenticated workspace request semantics', () async {
    final interceptor = _ContractInterceptor();
    final api = ApiService(interceptors: [interceptor]);
    api.setActiveWorkspace('21');

    final bytes = await api.getBytes('/report.pdf', workspaceScoped: true);

    final request = interceptor.requests.single;
    expect(request.headers['X-Workspace-ID'], '21');
    expect(request.extra['workspaceScoped'], isTrue);
    expect(request.responseType, ResponseType.bytes);
    expect(bytes, [37, 80, 68, 70, 45, 49]);
  });

  test('suspended account detail is preserved before generic 403', () async {
    final api = ApiService(
      interceptors: [
        _ErrorInterceptor({'detail': 'Account suspended'}, 403),
      ],
    );

    expect(
      api.me(),
      throwsA(
        predicate(
          (error) => error.toString().contains('Tu cuenta está suspendida'),
        ),
      ),
    );
  });

  test(
    'FastAPI validation lists become a controlled Spanish message',
    () async {
      final api = ApiService(
        interceptors: [
          _ErrorInterceptor({
            'detail': [
              {'msg': 'Field required'},
            ],
          }, 422),
        ],
      );

      expect(
        api.getList('/validation'),
        throwsA(
          predicate(
            (error) =>
                error.toString().contains('información enviada es incompleta'),
          ),
        ),
      );
    },
  );

  test('raw technical response strings are not shown to users', () async {
    final api = ApiService(
      interceptors: [_ErrorInterceptor('Dio server stack trace', 500)],
    );

    expect(
      api.getList('/failure'),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('El servidor rechazó la solicitud') &&
              !error.toString().contains('Dio server stack trace'),
        ),
      ),
    );
  });

  test('image quality rejection becomes actionable Spanish guidance', () async {
    final api = ApiService(
      interceptors: [
        _ErrorInterceptor({
          'detail':
              'Image quality is insufficient: the image is too blurry. Please recapture the oral image with steady focus and even lighting.',
        }, 422),
      ],
    );

    expect(
      api.getList('/quality'),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('imagen está desenfocada') &&
              !error.toString().contains('Tome otra foto'),
        ),
      ),
    );
  });
}
