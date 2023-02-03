import 'package:path/path.dart' as p;

const _supportedExtensions = {'.jpg', '.jpeg', '.png'};

isSupportedFile(path) => _supportedExtensions.contains(p.extension(path));