## 1.2.0

* New Feature: Added method `all()` for `DocMan.dir` helper.
  It's a simple way to get all app directories in one call as map.

     ```dart
  /// Get all app directories as map with keys as directory names and values as paths.
  final Map<String, String> dirs = await DocMan.dir.all();
  
  ///Result example: 
  { 
      "cache": "/data/user/0/com.example.app/cache", 
      "files": "/data/user/0/com.example.app/files",
      "data": "/data/user/0/com.example.app/app_flutter",
      // External directories, can be empty strings if not available.
      "cacheExt": "/storage/emulated/0/Android/data/com.example.app/cache",
      "filesExt": "/storage/emulated/0/Android/data/com.example.app/files",
  }
     ```
* Feature: Added ability to instantiate `DocumentThumbnail` from `Content Uri` or `File.path`.
  Same as `DocumentFile.thumbnail()` method, but now you can get `DocumentThumbnail` directly.

    ```dart
  /// Create thumbnail from content uri or file path.
  final DocumentThumbnail thumbnail = await DocumentThumbnail.fromUri(
        contentUriOrFilePath, 
        width: 100, 
        height: 100, 
        png: true,
  );
    ```
* Feature: Added syntax sugar for `DocumentFile` instantiation from `Content Uri` or `File.path`.

    ```dart
  /// New syntax sugar for DocumentFile instantiation from content uri or file path.
  final DocumentFile? doc = await DocumentFile.fromUri(contentUriOrFilePath);
  
  /// Old way.
  final DocumentFile? doc = await DocumentFile(contentUriOrFilePath).get();
    ```
* Fix: problem with parallel calls to `DocumentFile` `action` methods, when working with different
  documents.
  Now it's fixed. `DocManQueueManager` was primarily used for all `activity` methods, and it caused the problem.
  For example, now it's possible to create list or grid of documents thumbnails without any problems.
  If you were getting errors in log like `Error loading thumbnail: AlreadyRunning Method: documentfileaction`, it should
  be fixed now.

* Fix: error in syntax in methods `DocumentFile.share()` & `DocumentFile.open()`.
  String `title` parameter was not optional, but it should be. Now it's fixed.

  Please check your code and change `title` parameter to optional if you are using these methods.

  **From:**
  ```dart
    final bool share = await doc.share('Share this document:');
    final bool open = await doc.open('Open with:');
  ```

  **To:**
    ```dart
        final bool share = await doc.share(title: 'Share this document:');
        final bool open = await doc.open(title: 'Open with:');
    ```

* Chore: Updated dependencies, updated example, updated README, some code cleanup & small fixes.

## 1.1.0

* New Feature: Implemented simple custom `DocumentsProvider`
* Small fixes
* Updated README
* Updated example
* Updated dependencies

## 1.0.2

* Fix: missed export of `PermissionsException` class
* Example: updated deprecated `withOpacity` to `withAlpha`
* Documentation fixes

## 1.0.1

* Readme fixes
* Screenshot
* Workflow fixes

## 1.0.0

* DocMan initial release
