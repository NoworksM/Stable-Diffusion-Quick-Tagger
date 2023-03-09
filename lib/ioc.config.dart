// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:quick_tagger/app_module.dart' as _i7;
import 'package:quick_tagger/services/gallery_service.dart' as _i6;
import 'package:quick_tagger/services/image_service.dart' as _i3;
import 'package:quick_tagger/services/tag_service.dart' as _i4;
import 'package:shared_preferences/shared_preferences.dart'
    as _i5; // ignore_for_file: unnecessary_lambdas

// ignore_for_file: lines_longer_than_80_chars
extension GetItInjectableX on _i1.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    gh.singleton<_i3.IImageService>(_i3.ImageService());
    gh.singleton<_i4.ITagService>(_i4.TagService());
    gh.factoryAsync<_i5.SharedPreferences>(() => appModule.prefs);
    gh.singleton<_i6.IGalleryService>(
        _i6.GalleryService(gh<_i4.ITagService>()));
    return this;
  }
}

class _$AppModule extends _i7.AppModule {}
