import 'package:mockito/annotations.dart';

import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:bucalscan_ai/features/admin/domain/repositories/admin_repository.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/get_admin_users_usecase.dart';
import 'package:bucalscan_ai/features/admin/domain/usecases/update_admin_user_status_usecase.dart';
import 'package:bucalscan_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/has_session_token_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/register_usecase.dart';
import 'package:bucalscan_ai/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bucalscan_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';
import 'package:bucalscan_ai/features/history/data/datasources/history_remote_datasource.dart';
import 'package:bucalscan_ai/features/history/domain/repositories/history_repository.dart';
import 'package:bucalscan_ai/features/history/domain/usecases/get_history_usecase.dart';
import 'package:bucalscan_ai/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:bucalscan_ai/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';
import 'package:bucalscan_ai/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:bucalscan_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:bucalscan_ai/features/profile/domain/usecases/update_profile_usecase.dart';

@GenerateMocks([
  // Datasources
  AuthRemoteDataSource,
  AuthStorageService,
  AdminRemoteDataSource,
  DashboardRemoteDataSource,
  HistoryRemoteDataSource,
  PredictionRemoteDataSource,
  ProfileRemoteDataSource,
  // Repositories
  AuthRepository,
  AdminRepository,
  DashboardRepository,
  HistoryRepository,
  PredictionRepository,
  ProfileRepository,
  // Use cases
  LoginUseCase,
  RegisterUseCase,
  GetCurrentUserUseCase,
  GetCachedUserUseCase,
  HasSessionTokenUseCase,
  LogoutUseCase,
  UpdateProfileUseCase,
  GetTodaySummaryUseCase,
  GetHistoryUseCase,
  PredictImageUseCase,
  GetAdminUsersUseCase,
  UpdateAdminUserStatusUseCase,
])
void main() {}
