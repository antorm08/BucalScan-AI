import 'package:bucalscan_ai/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_image_input.dart';
import 'package:bucalscan_ai/features/prediction/domain/entities/prediction_result.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  final PredictionRemoteDataSource _remoteDataSource;

  const PredictionRepositoryImpl(this._remoteDataSource);

  @override
  Future<PredictionResult> predictImage(PredictionImageInput input) async {
    final model = await _remoteDataSource.predictImage(input);
    return model.toEntity();
  }
}
