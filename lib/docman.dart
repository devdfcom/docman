/// Library exports all the classes and functions of the docman package.
library;

///Export data classes
export 'src/data/document_file.dart';
export 'src/data/document_thumbnail.dart';
export 'src/data/permission.dart';

/// Export main entry point
export 'src/docman.dart';
export 'src/exceptions/app_dir_path.dart';

/// Export exceptions
export 'src/exceptions/common_exceptions.dart';
export 'src/exceptions/docman_base_exception.dart';
export 'src/exceptions/document_file_exception.dart';
export 'src/exceptions/picker_exceptions.dart';

/// Export extensions
export 'src/extensions/document_file_ext.dart';
export 'src/extensions/platform_exception_ext.dart';

/// Export utils
export 'src/utils/doc_man_app_dirs.dart';
export 'src/utils/doc_man_permissions.dart';
export 'src/utils/doc_man_picker.dart';
