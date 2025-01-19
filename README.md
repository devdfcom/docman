# Document Manager (DocMan)

<a href="https://github.com/devdfcom/docman#readme">
    <img src="https://github.com/user-attachments/assets/1f19d8af-3547-4825-836d-a596d5b16cf9" alt="DocMan logo" title="DocMan" align="right" height="150" />
</a>

[![pub package](https://img.shields.io/pub/v/docman.svg?logo=flutter&color=dodgerblue&style=flat)](https://pub.dev/packages/docman)
[![License: MIT](https://img.shields.io/github/license/devdfcom/docman?style=flat&color=mediumseagreen)](https://opensource.org/licenses/MIT)
[![Request a feature](https://img.shields.io/badge/Request-Feature-teal?style=flat)](https://github.com/devdfcom/docman/discussions/new?category=ideas)
[![Ask a question](https://img.shields.io/badge/Ask-Question-royalblue?style=flat)](https://github.com/devdfcom/docman/discussions/new/choose)
[![Report a bug](https://img.shields.io/badge/Report-Bug-indianred?style=flat)](https://github.com/devdfcom/docman/issues/new?labels=bug&projects=&template=bug_report.yml&title=%3Ctitle%3E)

A Flutter plugin that simplifies file & directory operations on Android devices.
Leveraging the Storage Access Framework (SAF) API,
it provides seamless integration for files & directories operations, persisted permissions management, and more.
Allows to set up own
simple [DocumentsProvider](https://developer.android.com/reference/kotlin/android/provider/DocumentsProvider)
for specific directory within your app's storage.

## 🚀 Features

- Picker for files & directories.
- App directories path retriever (cache, files, external storage cache & files).
- Manage files & directories (create, delete, list, copy, move, open, save, share, etc.).
- Thumbnail generation for images, videos, pdfs.
- Stream-based file reading, directory listing.
- Separated actions that can be performed in the background, like with isolates or WorkManager.
- Persisted permissions management.
- No manifest permissions are required.
- `DocumentsProvider` implementation.

## 🤖 Supported Android versions

- Android 5.0 (API level 21) and above.

## Example usage

```dart
import 'package:docman/docman.dart';

///Get the app's internal cache directory
/// Path Example: `/data/user/0/devdf.plugins.docman_example/cache`
Future<Directory?> getCachedDir() => DocMan.dir.cache();

///Pick a directory
Future<DocumentFile?> pickDir() => DocMan.pick.directory();

///Pick files & copy them to cache directory
Future<List<File>> pickFiles() => DocMan.pick.files(extensions: ['pdf', '.doc', 'docx']);

///Pick visual media (images & videos) - uses Android Photo Picker if available
Future<List<File>> pickMedia() => DocMan.pick.visualMedia(limit: 5, limitResultRestart: true);

///Get list of persisted permissions (directories only)
Future<List<Permission>> getPermissions() async => await DocMan.perms.list(files: false);

///DocumentFile used for file & directory operations
Future<void> dirOperationsExample() async {
  //Instantiate a DocumentFile from saved URI
  final dir = await DocumentFile(uri: 'content://com.android.externalstorage.documents/document/primary%3ADocMan')
      .get();
  //List directory files with mimeTypes filter
  final List<DocumentFile> documents = await dir.listDocuments(mimeTypes: ['application/pdf']);
}

///And more... Check the documentation for more details.
```

## 📖 Documentation

**API documentation** is available at [pub.dev](https://pub.dev/documentation/docman/latest/).
All public classes and methods are well-documented.

**Note:** To try the demos shown in the images run the [***example***](/example) included in this plugin.

### <ins>Table of Contents</ins>

1. 🛠️ [**Installation**](#installation)
2. 👆 [**Picker**](#-picker)  (🖼️ [*see examples*](#picker-examples))
    - [Pick directory](#pick-directory)
    - [Pick documents](#pick-documents)
    - [Pick files](#pick-files)
    - [Pick visualMedia](#pick-visualmedia)
3. 📂 [**App Directories**](#-app-directories) (🖼️ [*see examples*](#app-directories-examples))
    - [Supported app directories](#supported-app-directories)
    - ♻️ [Plugin Cache cleaner](#plugin-cache-cleaner)
4. 🛡️ [**Persisted permissions**](#persisted-permissions) (🖼️ [*see examples*](#persisted-permissions-examples))
    - [PersistedPermission data class](#persistedpermission-class)
    - [List/Stream permissions](#list--stream-permissions)
    - [List/Stream Documents with permissions](#list--stream-documents-with-permissions)
    - [Release & Release all actions](#release--release-all-actions)
    - [Get Uri permission status](#get-uri-permission-status)
    - ♻️ [Validate permissions](#validate-permissions)
5. 📄 [**DocumentFile**](#-documentfile) (🖼️ [*see examples*](#documentfile-examples))
    - [Instantiate DocumentFile](#instantiate-documentfile)
    - [Activity methods](#documentfile-activity-methods)
    - [Events / Stream methods](#documentfile-events--stream-methods)
    - [Action methods](#documentfile-action-methods)
    - 🧩 [DocumentThumbnail](#-documentthumbnail-class)
    - [Unsupported methods](#unsupported-methods)
6. 🗂️ [**DocumentsProvider**](#documents-provider) (🖼️ [*see examples*](#documents-provider-examples))
    - [Setup DocumentsProvider](#setup-documentsprovider)
    - [DocumentsProvider example](#provider-json-example)
7. 🗃️ [**DocMan Exceptions**](#docman-exceptions)
8. 📦 [**Changelog**](#-changelog)
9. ⁉️ [**Help & Questions**](#help--questions)
10. 🌱 [**Contributing**](#-contributing)

<a name="installation"></a>

## 🛠️ Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  docman: ^1.0.0
```

Then run ➡️ `flutter pub get`.

## 👆 Picker

The picker provides a simple way to select files and directories from the device storage.
The Class [DocManPicker](/lib/src/utils/doc_man_picker.dart) or helper: `DocMan.pick` provides the
following methods:

#### **Pick directory**

Allows picking a directory from the device storage. You can specify the initial directory to start from.

> [!WARNING]
> When picking directory, it also grants access to it.
> On **Android 11 (API level 30)** and higher it's <ins>***impossible***</ins> to grant access to **root directories of
sdCard, download folder**, also it's <ins>***impossible***</ins> to select any file from:
> **Android/data/** directory and all subdirectories, **Android/obb/** directory and all subdirectories.
>
> [All restrictions are described here at developer.android.com](https://developer.android.com/training/data-storage/shared/documents-files#document-tree-access-restrictions)

> [!NOTE]
> `initDir`: Option to set initial directory uri for picker is available since Android 8.0 (Api 26).
> If the option is not available, the picker will start from the default directory.

```dart
Future<DocumentFile?> pickBackupDir() => DocMan.pick.directory(initDir: 'content uri to start from');
```

#### **Pick documents**

Allows picking single or multiple documents. You can specify the initial directory to start from.
Filter by MIME types & extensions, by location - only local files (no cloud providers etc.) or both.
You can choose a limit strategy when picking multiple documents.
Grant persisted permissions to the picked documents. The point of this is to get only the metadata of the documents,
without copying them to the cache/files directory.

```dart
Future<List<DocumentFile>> pickDocuments() =>
    DocMan.pick.documents(
      initDir: ' content uri to start from',
      mimeTypes: ['application/pdf'],
      extensions: ['pdf', '.docx'],
      localOnly: true,
      grantPermissions: true,
      limit: 5,
      limitResultRestart: true,
      limitRestartToastText: 'Pick maximum 5 items',
    );
```

#### **Pick files**

Allows picking single or multiple files. The difference from [Pick documents](#pick-documents)
is that it returns a list of `File`(s) saved in the cache directory.
First, it will try to copy to the external cache directory; if not available, then to the internal cache directory.

You can specify the initial directory to start from, filter by MIME types & extensions, by location -
show only local files (no cloud providers etc.).
You can choose a limit strategy when picking multiple documents.

```dart
Future<List<File>> pickFiles() =>
    DocMan.pick.files(
      initDir: 'content uri to start from',
      mimeTypes: ['application/pdf', 'application/msword'],
      extensions: ['pdf', '.doc', 'txt'],
      localOnly: false,
      //Set limit to 1 for single file picking
      limit: 5,
      limitResultCancel: true, //cancel with exception picking if limit is exceeded
    );
```

#### **Pick visualMedia**

This is almost the same as [Pick files](#pick-files). Allows picking visual media like images or videos.
It uses the Android Photo Picker (VisualMediaPicker) if available. You can disable the visual media picker if needed.
You can specify the initial directory to start from, filter by MIME types & extensions, by location -
show only local files (no cloud providers etc.).
You can choose a limit strategy when picking multiple documents. Allows setting image quality for compression.
All picked files will be copied to the cache directory (external or internal).

```dart
Future<List<File>> pickVisualMedia() =>
    DocMan.pick.visualMedia(
      initDir: 'content uri to start from',
      mimeTypes: ['image/*'],
      extensions: ['jpg', '.png', 'webp'],
      // used only for images, default is 100
      imageQuality: 70,
      //fallback to default file picker if visual media picker is not available
      useVisualMediaPicker: true,
      localOnly: true,
      limit: 3,
      //Android PhotoPicker has limit functionality, system file picker has limit 100
      limitResultEmpty: true, //return empty list if limit is exceeded
    );
```

---
<a name="picker-examples"></a>
<details>

<summary style="font-weight: bold">🖼️ Picker examples (click for expand/collapse)</summary>

|                                       Picking directory                                       |                                       Picking documents                                       |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/25594ef3-2fbc-4ae6-aabf-7d440e4a77ce" /> | <img src="https://github.com/user-attachments/assets/5d787744-a3df-4697-a0ed-59f00d050e17" /> |

|                                         Picking files                                         |                                      Picking visualMedia                                      |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/b9556dde-280d-4429-a486-7d4e70308ad4" /> | <img src="https://github.com/user-attachments/assets/6241bbfc-1f00-47d5-b1c9-8dc1cf250ce7" /> |

</details>
<hr />

## 📂 App Directories

The plugin provides a way to get the app's internal & external directories,
like cache, files, data, external cache, external files, etc.
You can instantiate a [DocManAppDirs](/lib/src/utils/doc_man_app_dirs.dart) class
or use the helper: `DocMan.dir` to get the directories.

#### **Supported app directories**

```dart
/// Get Application internal Cache Directory.
/// Path Example: `/data/user/0/devdf.plugins.docman_example/cache`
Future<Directory?> cache() => DocMan.dir.cache();

/// Get Application Files Directory.
/// The directory for storing files, rarely used.
/// Path Example: `/data/user/0/devdf.plugins.docman_example/files`
Future<Directory?> files() => DocMan.dir.files();

/// Get Application Data Directory.
/// Default Directory for storing data files of the app.
/// Path Example: `/data/user/0/devdf.plugins.docman_example/app_flutter`
Future<Directory?> data() => DocMan.dir.data();

/// Get Application External Cache Directory.
/// Path Example: `/storage/emulated/0/Android/data/devdf.plugins.docman_example/cache`
Future<Directory?> externalCache() => DocMan.dir.externalCache();

/// Get Application External Files Directory.
/// Path Example: `/storage/emulated/0/Android/data/devdf.plugins.docman_example/files`
Future<Directory?> filesExt() => DocMan.dir.filesExt();
```

<a name="plugin-cache-cleaner"></a>

#### ♻️ **Plugin Cache cleaner**

During the app lifecycle, the cache (external or internal) directory can be filled with temporary files,
created by the plugin. When you pick files, visual media, or copy to cache, for example,
the plugin will create temporary files in the cache (external or internal) directory
in subdirectories like **`docManMedia`** and **`docMan`**.
To clean those directories, you can use the following method:

```dart
/// Clear Temporary Cache Directories.
///
/// Clears only the temp directories created by the plugin like `docManMedia` and `docMan`
/// in external & internal cache directories if exists.
///
/// Returns `true` if the directories were cleared successfully; otherwise, `false`.
Future<bool> clearPluginCache() => DocMan.dir.clearCache();
```

---
<a name="app-directories-examples"></a>
<details>

<summary style="font-weight: bold">🖼️ App Directories examples (click for expand/collapse)</summary>

|                                        Get directories                                        |
|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/4675fddc-45f5-4008-9d5a-a61dafba1dc1" /> |

</details>
<hr />

<a name="persisted-permissions"></a>

## 🛡️ Persisted permissions

`DocMan` provides a way to manage persisted permissions for directories & documents.
When you pick a directory or document with the parameter `grantPermissions` set to `true`,
its content URI gets a persistable permission grant.
Once taken, the permission grant will be remembered across device reboots.
If the grant has already been persisted, taking it again will just update the grant time.

You can instantiate a [DocManPermissionManager](/lib/src/utils/doc_man_permissions.dart) class
or use the helper: `DocMan.perms` to manage permissions.

> [!CAUTION]
> Persistable permissions have limitations:
>  - Limited to **128** permissions per app for **Android 10** and below
>  - Limited to **512** permissions per app for **Android 11** and above

#### **PersistedPermission class**

`PersistedPermission` is a data class that holds information about the permission grant.
It is a representation of
the [UriPermission](https://developer.android.com/reference/kotlin/android/content/UriPermission) Android class on Dart
side. It stores the `uri` and `time` of the permission grant, and whether it has `read` or `write`
access.

```dart

final perm = PersistedPermission(
    uri: 'content://com.android.externalstorage.documents/tree/primary%3ADocMan',
    read: true,
    write: true,
    time: 1733260689869);
```

#### **List / Stream permissions**

You can list or stream all persisted permissions.
Also, you can filter permissions by files or directories or both.

```dart
/// Get list of all persisted permissions.
/// Optionally filter by files or directories.
Future<List<PersistedPermission>> listPerms({bool files = true, bool dirs = true}) =>
    DocMan.perms.list(files: files, directories: dirs);
```

```dart
/// Stream all persisted permissions.
/// Optionally filter by files or directories.
Future<void> streamPerms() async {
  final Stream<PersistedPermission> stream = DocMan.perms.listStream(files: false);

  int countPerms = 0;

  stream.listen((perm) {
    countPerms++;
    print(perm.toString());
  }, onDone: () {
    print('Stream Done, $countPerms permissions');
  }, onError: (e) {
    print('Error: $e');
  });
}
```

#### **List / Stream Documents with permissions**

You can list or stream all documents (`DocumentFile`) with persisted permissions.
Also, you can filter documents by files or directories or both.
This method also removes the persisted permissions for the files/directories that no longer exist
(for example, the user deleted the file, through another app).

```dart
/// List all DocumentFiles with persisted permissions.
/// Optionally filter by files or directories.
Future<List<DocumentFile>> listDocumentsWithPerms({bool files = true, bool dirs = true}) =>
    DocMan.perms.listDocuments(files: files, directories: dirs);
```

```dart
/// Stream all DocumentFiles with persisted permissions.
/// Optionally filter by files or directories.
Future<void> streamDocs() async {
  final Stream<DocumentFile> stream = DocMan.perms.listDocumentsStream(directories: true, files: false);

  int countDocs = 0;

  stream.listen((doc) {
    countDocs++;
    print(doc.toString());
  }, onDone: () {
    print('Stream Done, $countDocs documents');
  }, onError: (e) {
    print('Error: $e');
  });
}
```

#### **Release & Release all actions**

You can release a single permission for a specific URI or all permissions.

```dart
/// Release persisted permission for specific URI.
Future<bool> releasePermission(String uri) => DocMan.perms.release(uri);

/// PersistedPermission class has helper method to release permission.
Future<void> permAction() async {
  final PersistedPermission perm = await DocMan.perms
      .list()
      .first;
  await perm.release();
}
```

```dart
/// Release all persisted permissions.
Future<bool> releaseAllPermissions() => DocMan.perms.releaseAll();
```

#### **Get Uri permission status**

You can check if the URI has a persisted permission grant.

```dart
/// Check if URI has persisted permission grant.
Future<PersistedPermission?> hasPermission() =>
    DocMan.perms.status('content://com.android.externalstorage.documents/tree/primary%3ADocMan');
```

<a name="validate-permissions"></a>

#### ♻️ **Validate permissions**

You can validate persisted permissions for files or directories.
It will check each uri in persisted permissions list
and remove invalid permissions (for example, the user deleted the file/directory through system file manager).

```dart
/// Validate the persisted permissions list.
/// Returns `true` if the list was validated successfully, otherwise throws an error.
Future<bool> validatePermissions() => DocMan.perms.validateList();
```

---
<a name="persisted-permissions-examples"></a>
<details>

<summary style="font-weight: bold">🖼️ Persisted permissions examples (click for expand/collapse)</summary>

|                                    List/Stream Permissions                                    |                                     List/Stream Documents                                     |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/4109417d-df33-42f5-9df8-fb3516169aae" /> | <img src="https://github.com/user-attachments/assets/0efe0c21-56cf-4437-b9b6-e848cc0e269f" /> |

</details>
<hr />

## 📄 DocumentFile

`DocumentFile` is a class that represents a file or directory in the device storage.
It's a dart representation of
the android [DocumentFile](https://developer.android.com/reference/kotlin/androidx/documentfile/provider/DocumentFile).
It provides methods to perform file & directory operations like create, delete, list, copy, open, save, share, etc.
The purpose of it is to get the file's metadata like name, size, mime type, last modified, etc. and perform actions on
it without the need to copy each file in cache/files directory.
All supported methods are divided in extensions grouped by channels (Action, Activity, Events).

> [!NOTE]
> Methods for directories are marked with `📁`, for files `📄`.

#### **Instantiate DocumentFile**

There are two ways to instantiate a `DocumentFile`:

- From the uri (content://), saved previously, with persisted permission.

  ```dart
  Future<DocumentFile?> backupDir() =>
      DocumentFile(uri: 'content://com.android.externalstorage.documents/tree/primary%3ADocMan').get();
  ```

> [!CAUTION]
> In rarely cases `DocumentFile` can be instantiated even if the uri doesn't have persisted permission.
> For example uris like `content://media/external/file/106` cannot be instantiated directly,
> but if the file was picked through (`DocMan.pick.visualMedia()` for example), it will be instantiated,
> but most of the methods will throw an exception, you will be able only to read the file content.

- From the app local `File.path` or `Directory.path`.

  ```dart
  Future<DocumentFile?> file() => DocumentFile(uri: 'path/to/file.jpg').get();
  
  /// If directory doesn't exist, it will create all directories in the path.
  Future<DocumentFile?> dir() => DocumentFile(uri: 'path/to/some/directory/notCreatedYet').get();
  ```

#### **DocumentFile Activity methods**

Activity Methods are interactive methods which require user interaction.
Like `open`, `share`, `saveTo` methods. All methods are called through Activity channel.

- `open` `📄` Open the file with supported app.

  If there are more than one app that can open files of this file type,
  the system will show a dialog to choose the app to open with.
  Action can be performed only on file & file must exist.

    ```dart
    Future<bool> openFile(DocumentFile file) => file.open('Open with:');
    ```

- `share` `📄` Share the file with other apps.

    ```dart
    Future<bool> shareFile(DocumentFile file) => file.share('Share with:');
    ```

- `saveTo` `📄` Save the file to the selected directory.

  You can specify the initial directory to start from, whether to show only local directories or not,
  and delete the original file after saving. After saving, the method returns the saved `DocumentFile`.

    ```dart
    Future<DocumentFile?> saveFile(DocumentFile file) =>
        file.saveTo(
          initDir: 'content uri to start from', //optional
          localOnly: true,
          deleteSource: true,
        );
    ```

#### **DocumentFile Events / Stream methods**

Methods collection used for stream-based operations like reading files, listing directories, etc.
All methods are called through Events channel.
If `DocumentFile` is a directory, you can list its files & subdirectories via stream,
if it's a file, you can read it via stream as bytes or string.

- `readAsString` `📄` Read the file content as string stream.

  Can be used only on file & file must exist.
  You can specify the encoding of the file content, buffer size or set the start position to read from.

    ```dart
    Stream<String> readAsString(DocumentFile file) =>
        file.readAsString(charset: 'UTF-8', bufferSize: 1024, start: 0);
    ```

<a name="documentfile-read-as-bytes"></a>

- `readAsBytes` `📄` Read the file content as bytes stream.

  Can be used only on file & file must exist.
  You can specify the buffer size or set the start position to read from.

    ```dart
    Stream<Uint8List> readAsBytes(DocumentFile file) =>
        file.readAsBytes(bufferSize: (1024 * 8), start: 0);
    ```

<a name="list-documents-stream"></a>

- `listDocumentsStream` `📁` List the documents in the directory as stream.

  Can be used only on directory & directory must exist.
  You can specify the mimeTypes & extensions filter, to filter the documents by type, or filter documents by string in
  name.

    ```dart
    Stream<DocumentFile> listDocumentsStream(DocumentFile dir) =>
        dir.listDocumentsStream(mimeTypes: ['application/pdf'], extensions: ['pdf', '.docx'], nameContains: 'doc_');
    ```

#### **DocumentFile Action methods**

Action methods are used for file & directory operations. All methods are called through Action channel,
and can be performed in the background (with isolates or WorkManager).

- `permissions` `📁` `📄` Get the persisted permissions for the file or directory.

  Returns [PersistedPermission](#persistedpermission-class) instance or `null` if there are no persisted permissions.

    ```dart
    Future<PersistedPermission?> getPermissions(DocumentFile file) => file.permissions();
    ```

- `read` `📄` Read the entire file content as bytes.

  Can be used only on file & file must exist.

    ```dart
    Future<Uint8List> readBytes(DocumentFile file) => file.read();
    ```

  ℹ️ If file is big, it's better to use stream-based method [readAsBytes](#documentfile-read-as-bytes).


- `createDirectory` `📁` Create a new subdirectory with the specified name.

  Can be used only on directory & directory must exist & has write permission & flag `canCreate` is `true`.
  Returns the created `DocumentFile` directory.

    ```dart
    Future<DocumentFile?> createDir(DocumentFile dir) => dir.createDirectory('new_directory');
    ```

- `createFile` `📁` Create a new file with the specified name & content in the directory.

  Can be used only on directory & directory must exist & has write permission & flag `canCreate` is `true`.
  You can specify the content of the file as bytes or string, name must contain extension.
  It will try to determine the mime type from the extension, otherwise it will throw an exception.
  If the name contains extension only, like in example `.txt`, name will be generated automatically.
  Example: `.txt` -> `docman_file_18028.txt`.
  Returns the created `DocumentFile` file.

    ```dart
    /// Create a new file with the specified name & String content in the directory.
    Future<DocumentFile?> createFile(DocumentFile dir) =>
        dir.createFile(name: '.txt', content: 'Hello World!');
    
    /// Create a new file with the specified name & bytes content in the directory.
    Future<DocumentFile?> createFileFromBytes(DocumentFile dir) =>
        dir.createFile(name: 'test Document.pdf', bytes: Uint8List.fromList([1, 2, 3, 4, 5]));
    ```

- `listDocuments` `📁` List the documents in the directory.

  Can be used only on directory & directory must exist.
  You can specify the mimeTypes & extensions filter, to filter the documents by type, or filter documents by string in
  name.

    ```dart
    Future<List<DocumentFile>> listDocuments(DocumentFile dir) =>
        dir.listDocuments(mimeTypes: ['application/pdf'], extensions: ['pdf', '.docx'], nameContains: 'doc_');
    ```

  ℹ️ This method returns all documents in the directory, if list has many items,
  it's better to use stream-based method [listDocumentsStream](#list-documents-stream).


- `find` `📁` Find the document in the directory by name.

  Can be used only on directory & directory must exist.
  Search through `listDocuments` for the first document exact matching the given name. Returns null when no matching
  document is found.

    ```dart
    Future<DocumentFile?> findDocument(DocumentFile dir) => dir.find('file_name.jpg');
    ```

- `delete` `📁` `📄` Delete the file or directory. Can be used on both file & directory.

  Works only if the document exists & has permission to write & flag `canDelete` is set to `true`.
  If the document is a directory, it will delete all content recursively.
  Returns `true` if the document was deleted.

    ```dart
    Future<bool> deleteFile(DocumentFile file) => file.delete();
    Future<bool> deleteDir(DocumentFile dir) => dir.delete();
    ```
- `cache` `📄` Copy the file to the cache directory (external if available, internal otherwise).

  If file with same name already exists in cache, it will be overwritten.
  Works only if the document exists & has permission to read.
  Returns `File` instance of the cached file.

    ```dart
  /// For all types of files
    Future<File?> cacheFile(DocumentFile file) => file.cache();
  /// If file is image (jpg, png, webp) you can specify the quality of the image
    Future<File?> cacheImage(DocumentFile file) => file.cache(imageQuality: 70);
    ```
- `copyTo` `📄` Copy the file to the specified directory.

  File must exist & have flag `canRead` set to `true`.
  Destination directory must exist & have persisted permissions,
  or it can be local app directory like `Directory.path`.
  Optionally You can specify the new name of the file, with or without extension.
  If something goes wrong, it will throw an exception & created file will be deleted.

  ```dart
  ///Copy file to the the directory `DocumentFile` instance with persisted permission uri
  Future<DocumentFile?> copyFile(DocumentFile file) =>
      file.copyTo('content://com.android.externalstorage.documents/tree/primary%3ADocMan', name: 'my new file copy');
  
  ///Copy file to the the local app directory `Directory.path`
  Future<DocumentFile?> copyFileToLocalDir(DocumentFile file) =>
      file.copyTo('/data/user/0/devdf.plugins.docman_example/app_flutter/myDocs', name: 'test_file.txt');
  ```

- `moveTo` `📄` Move the file to the specified directory.

  File must exist & have flag `canRead` & `canDelete` set to `true`.
  Destination directory must exist & have persisted permissions,
  or it can be local app directory like `Directory.path`.
  Optionally You can specify the new name of the file, with or without extension,
  otherwise the file will be moved with the same name.
  If something goes wrong, automatically will delete the created file.
  Returns the `DocumentFile` instance of the moved file.
  After moving the file, the original file will be deleted.

    ```dart
  ///Move file to the the directory `DocumentFile` instance with persisted permission uri
  Future<DocumentFile?> moveFile(DocumentFile file) =>
      file.moveTo('content://com.android.externalstorage.documents/tree/primary%3ADocMan', name: 'moved file name');
  
  ///Move file to the the local app directory `Directory.path`
  Future<DocumentFile?> moveFileToLocalDir(DocumentFile file) =>
      file.moveTo('/data/user/0/devdf.plugins.docman_example/cache/TempDir', name: 'moved_file.txt');
    ```

- `thumbnail` `📄` Get the thumbnail of the file.

  Can be used only on file & file must exist & has flag `canThumbnail` set to `true`.
  You must specify the width & height of the thumbnail. Optionally you can specify the quality of the image
  and set `png` or `webp` to `true` to get the compressed image in that format, otherwise it will be `jpeg`.
  Returns [DocumentThumbnail](#-documentthumbnail-class) instance of the thumbnail image or `null` if the thumbnail is
  not available.
  Commonly used for images, videos, pdfs.

    ```dart
    Future<DocumentThumbnail?> thumbnail(DocumentFile file) => file.thumbnail(width: 256, height: 256, quality: 70);
    ```
  > [!NOTE]
  > ⚠️ Sometimes due to different document providers, thumbnail can have bigger dimensions, than requested.
  Some document providers may not support thumbnail generation.

  > [!TIP]
  > ⚠️ If file is local image, only `jpg`, `png`, `webp`, `gif`
  types are currently supported for thumbnail generation, in all other cases support depends on the document provider.

- `thumbnailFile` `📄` Get the thumbnail of the file as a `File`.

  Same as `thumbnail` method, but returns the thumbnail image as a `File` instance, saved in the cache directory.
  First it will try to save to external cache directory, if not available, then to internal cache directory.

    ```dart
    Future<File?> thumbnailFile(DocumentFile file) => file.thumbnailFile(width: 192, height: 192, webp: true);
    ```

#### 🧩 **DocumentThumbnail class**

`DocumentThumbnail` is a data class that holds information about the thumbnail image.
It stores the `width`, `height` of the image, and the `bytes` (Uint8List) of the image.

#### **Unsupported methods**

Information about currently (temporarily) unsupported methods in the plugin.

> [!CAUTION]
> ⚠️ Currently `📄` `rename` action was commented out due to the issue with the SAF API.
> Very few Documents Providers support renaming files & after renaming, the document may not be found,
> so it's better to use `copy` & `delete` actions instead.

---
<a name="documentfile-examples"></a>

<details>

<summary style="font-weight: bold">🖼️ DocumentFile examples (click for expand/collapse)</summary>

|                                      Local file activity                                      |                                      Picked File actions                                      |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/a5cb398c-1a9f-4aab-91cb-112e31c4565c" /> | <img src="https://github.com/user-attachments/assets/fd510728-9601-47ad-9e14-b183e5bb2f95" /> |

|                                   Picked Directory actions                                    |                                    Local Directory actions                                    |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/f9e851c0-5e49-4a05-a122-909c188e530b" /> | <img src="https://github.com/user-attachments/assets/4c5158f3-b694-4ec0-8fb0-72a58bd61986" /> |

</details>

<hr />

<a name="documents-provider"></a>

## 🗂️ DocumentsProvider

`DocMan` provides a way to set up a simple
custom [DocumentsProvider](https://developer.android.com/reference/kotlin/android/provider/DocumentsProvider)
for your app. The main purpose of this feature is to share app files & directories with other apps,
by `System File Picker UI`. You provide the name of the directory,
where your public files are stored. The plugin will create a custom DocumentsProvider for your app,
that will be accessible by other apps. You can customize it, and set the permissions for the files & directories.

> [!NOTE]
> If you don't want to use the custom DocumentsProvider, you can just delete the `provider.json`,
> if it exists, in the `assets` directory.

> [!TIP]
> When you perform any kind of action on files or directories in the provider directory,
> Provider will reflect the changes in the System File Picker UI.

#### **Setup DocumentsProvider**

1. Create/Copy the `provider.json` file to the `assets` directory in your app.
   You can find the example file in the [plugin's example app](/example/assets/provider.json).
2. Update the `pubspec.yaml` file.

    ```yaml
    flutter:
      assets:
        - assets/provider.json
    ```

#### **DocumentsProvider configuration**

All configuration is stored in the `assets/provider.json` file.

> [!IMPORTANT]
> Once you set up the provider, ***do not change any parameter dynamically***,
> otherwise the provider will not work correctly.

- `rootPath` The name of the directory where your public files are stored.
  This ***parameter is required***. This is an entry point for the provider.
  Directory will be created automatically, if it doesn't exist.
  Plugin first will try to create the directory in the external storage (app files folder), if not available,
  then in the internal storage (app data folder - which is `app_flutter/`)

  Example values: `public_documents`, `provider`, `nested/public/path`.
  ```json
  {
    "rootPath": "public_documents"
  }
  ```

- `providerName` - The name of the provider that will be shown in the System UI,
  if null it will use the app name. Do not set long name, it will be truncated.

  ```json
  {
    "providerName": "DocMan Example"
  }
  ```

- `providerSubtitle` - The subtitle of the provider that will be shown in the System UI, if null it will be hidden.

  ```json
  {
    "providerSubtitle": "Documents & media files"
  }
  ```

- `mimeTypes` - List of mime types that the provider supports. Set this to null to show provider in all scenarios.

  ```json
  {
    "mimeTypes": ["image/*", "video/*"]
  }
  ```
- `extensions` - List of file extensions that the provider supports. Set this to null to show provider in all scenarios.
  ```json
  {
    "extensions": ["pdf", ".docx"]
  }
  ```

  On the init, if you provide `mimeTypes` & `extensions`, the plugin will check if the platform supports them &
  will combine in a single list & filter only supported types.

> [!NOTE]
> If you set `mimeTypes` for example to `["image/*"]`, when `System File Picker UI` is opened by any other
> app, which also wants to get images, it will show your provider in list of providers. But remember if you set
`mimeTypes` or `extensions` to specific types, but you store different types of files in the directory,
> they will be also visible.

> [!IMPORTANT]
> **In short:** if you set `mimeTypes` or `extensions`,
***you have to store only files of these types in the provider directory***.

- `showInSystemUI` - Whether to show the provider in the System UI. If set to `false`, the provider will be hidden.
  This is working only on Android 10 (Api 29) and above, on lower versions it will always be shown.

- `supportRecent` - Whether to add provider files to the `Recent` list.
- `supportSearch` - Whether to include provider files in search in the System UI.
- `maxRecentFiles` - Maximum number of recent files that will be shown in the `Recent` list.
  Android max limit is 64, plugin default is 15.
- `maxSearchResults` - Maximum number of search results that will be shown in the search list.
  Plugin default is 10.

🚩 **Supported flags for directories:**

> [!TIP]
> You can skip the `directories` section, if you plan to support all actions for directories.
> Because by default all actions are set to `true`, even if you don't provide them in the section.

- `create` - Whether the provider supports creation of new files & directories within it.
- `delete` - Whether the provider supports deletion of files & directories.
- `move` - Whether documents in the provider can be moved.
- `rename` - Whether documents in the provider can be renamed.
- `copy` - Whether documents in the provider can be copied.

Section for directories in the `provider.json` file:

```json
{
  "directories": {
    "create": true,
    "delete": true,
    "move": true,
    "rename": true,
    "copy": true
  }
}
``` 

🏳️ **Supported flags for files:**

> [!TIP]
> You can skip the `files` section, if you plan to support all actions for directories.
> Because by default all actions are set to `true`, even if you don't provide them in the section.

- `delete` - Whether the provider supports deletion of files & directories.
- `move` - Whether documents in the provider can be moved.
- `rename` - Whether documents in the provider can be renamed.
- `write` - Whether documents in the provider can be modified.
- `copy` - Whether documents in the provider can be copied.
- `thumbnail` - Indicates that documents can be represented as a thumbnails.
    - The provider supports generating custom thumbnails for videos and PDFs.
    - Thumbnails for images are generated by system.
    - All thumbnails, generated by the provider, are cached in the `thumbs` directory under the `docManMedia` directory.
    - You can clear the thumbnail cache using `DocMan.dir.clearCache()`.

Section for files in the `provider.json` file:

```json
{
  "files": {
    "delete": true,
    "move": true,
    "rename": true,
    "write": true,
    "copy": true,
    "thumbnail": true
  }
}
```

or short version, if all actions are supported:

```json
{
  "files": {
    "delete": false
  }
}
```

<a name="provider-json-example"></a>
<details>

<summary style="font-weight: bold">🗒️ Full Example of the `provider.json` (click for expand/collapse)</summary>

```json
{
  "rootPath": "nested/provider_folder",
  "providerName": "DocMan Example",
  "providerSubtitle": "Documents & media files",
  "mimeTypes": [
    "image/*"
  ],
  "extensions": [
    ".pdf",
    "mp4"
  ],
  "showInSystemUI": true,
  "supportRecent": true,
  "supportSearch": true,
  "maxRecentFiles": 20,
  "maxSearchResults": 20,
  "directories": {
    "create": false,
    "delete": true,
    "move": true,
    "rename": true,
    "copy": true
  },
  "files": {
    "delete": true,
    "move": true,
    "rename": true,
    "write": true,
    "copy": true,
    "thumbnail": true
  }
}
```

</details>



<a name="documents-provider-examples"></a>
<hr />
<details>
<summary style="font-weight: bold">🖼️ DocumentsProvider examples (click for expand/collapse)</summary>

|                             Side menu view in System File Manager                             |                                     Visibility in Recents                                     |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/9d365397-3050-46b8-b0c9-a1f4a4956c82" /> | <img src="https://github.com/user-attachments/assets/5af73262-1991-424b-b6dc-45785c154a95" /> |

|                               DocumentsProvider through Intent                                |                              DocumentsProvider via File Manager                               |
|:---------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------:|
| <img src="https://github.com/user-attachments/assets/c4481d37-1e73-4e13-a3e2-5edfa8936f8a" /> | <img src="https://github.com/user-attachments/assets/4c66fa0c-15bc-4df0-b754-0831700e57e1" /> |

</details>

<hr />

<a name="docman-exceptions"></a>

## 🗃️ DocMan Exceptions

`DocMan` provides a set of exceptions that can be thrown during the plugin operation.

- `DocManException` - Base exception for all exceptions.

Common exceptions for all channels:

- `AlreadyRunningException` Thrown when the same method is already in progress.
- `NoActivityException` Thrown when the activity is not available.
  For example when you try to perform activity actions
  like `open`, `share`, `saveTo` or `pick` & no activity found to handle the request.

📂 `DocManAppDirs()` (`DocMan.dir`) exceptions:

- `AppDirPathException` Thrown when the app directory path is not found.
  For example if device doesn't have external storage.
- `AppDirActionException` Thrown when app tries to perform unimplemented action on app directory.

👆 `DocManPicker()` (`DocMan.pick`) exceptions:

- `PickerMimeTypeException` Thrown for `DocMan.pick.visualMedia()` method, when mimeTypes are not supported.
- `PickerMaxLimitException` Thrown for `DocMan.pick.visualMedia()` method.
  When `limit` parameter is greater than max allowed by the platform,
  currently it
  uses [MediaStore.getPickImagesMaxLimit](https://developer.android.com/reference/android/provider/MediaStore#getPickImagesMaxLimit())
  on supported devices (Android 11 & above), otherwise it forces
  the limit to 100.
- `PickerCountException` Thrown when you set picker parameter `limitResultCancel` to `true`.
  This exception has 2 String properties: `count` - number of picked files, `limit` - the limit set.
  For example when you pick 5 files, but `limit` is set to 3 and `limitResultCancel` is `true`.

📄 `DocumentFile` exceptions:

- `DocumentFileException` Base exception for all `DocumentFile` exceptions thrown by the plugin.

🛡️ `DocManPermissionManager()` (`DocMan.perms`) exceptions:

- `PermissionsException` Base exception thrown by the permissions' manager for all methods.

## 📦 Changelog

Please see [CHANGELOG.md](./CHANGELOG.md) for more information on what has changed recently.

<a name="help--questions"></a>

## ⁉️ Help & Questions

Start a new discussion in the [Discussions Tab](https://github.com/devdfcom/docman/discussions).

## 🌱 Contributing

Any contributions you make are **greatly appreciated**.

Just [fork the repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
and [create a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).

For major changes, please first start a discussion in
the [Discussions Tab](https://github.com/devdfcom/docman/discussions) to discuss what you would
like to change.

> ‼️ By submitting a patch, you agree to allow the project owner(s) to license your work under the terms of
> the [**`MIT License`**](./LICENSE).

🙏 **Thank you!**
