# Flutter Quill Editor

> Reference for: Flutter Expert  
> Load when: Rich text editor, Quill, Delta, toolbar, formatting  
> Note: Uses custom version at `customs/flutter_quill` (API compatible with standard flutter_quill)

## Overview

Flutter Quill is a rich text editor for Flutter based on Quill.js. It provides:

- **Rich text editing**: Bold, italic, underline, lists, links, code blocks, etc.
- **Delta format**: Document stored as JSON Delta (operational transform format).
- **Customizable toolbar**: Built-in toolbar buttons or custom implementations.
- **Extensions**: Image, video, camera, and other embed types via `flutter_quill_extensions`.
- **Localization**: Multi-language support via `FlutterQuillLocalizations`.

## Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_quill:
    path: customs/flutter_quill
  flutter_quill_extensions:
    path: customs/flutter_quill/flutter_quill_extensions
```

```dart
// Localization setup
import 'package:flutter_quill/flutter_quill.dart';

MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    FlutterQuillLocalizations.delegate,  // Add this
  ],
  // ...
)
```

## QuillController

```dart
import 'package:flutter_quill/flutter_quill.dart';

// Basic controller
final controller = QuillController.basic();

// With configuration
final controller = QuillController.basic(
  config: QuillControllerConfig(
    clipboardConfig: QuillClipboardConfig(
      enableExternalRichPaste: true,
      onImagePaste: (imageBytes) async {
        // Handle image paste, return image URL
        return imageUrl;
      },
    ),
  ),
);

// From Delta JSON
final delta = Delta.fromJson(jsonDecode(deltaJson));
final controller = QuillController(
  document: Document.fromDelta(delta),
  selection: const TextSelection.collapsed(offset: 0),
);

// Get Delta JSON
final deltaJson = jsonEncode(controller.document.toDelta().toJson());
```

## QuillEditor

```dart
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

QuillEditor(
  focusNode: focusNode,
  scrollController: scrollController,
  controller: controller,
  config: QuillEditorConfig(
    placeholder: 'Quick notes...',
    padding: const EdgeInsets.all(16),
    customStyles: DefaultStyles(),
    embedBuilders: [
      ...FlutterQuillEmbeds.editorBuilders(
        imageEmbedConfig: QuillEditorImageEmbedConfig(
          imageProviderBuilder: (context, imageUrl) {
            if (imageUrl.startsWith('assets/')) {
              return AssetImage(imageUrl);
            }
            // Handle network images, etc.
            return null;
          },
        ),
        videoEmbedConfig: QuillEditorVideoEmbedConfig(
          customVideoBuilder: (videoUrl, readOnly) {
            // Custom video widget
            return null;
          },
        ),
      ),
    ],
  ),
)
```

## QuillToolbar

```dart
import 'package:flutter_quill/flutter_quill.dart';

// Individual toolbar buttons
QuillToolbarClearFormatButton(controller: controller),
QuillToolbarImageButton(controller: controller),
QuillToolbarCameraButton(controller: controller),

// Toggle style buttons (bold, italic, underline, etc.)
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.bold,
),
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.italic,
),
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.underline,
),

// Lists
QuillToolbarToggleCheckListButton(controller: controller),
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.ol,  // Ordered list
),
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.ul,  // Unordered list
),

// Code and quotes
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.inlineCode,
),
QuillToolbarToggleStyleButton(
  controller: controller,
  attribute: Attribute.blockQuote,
),

// Links
QuillToolbarLinkStyleButton(controller: controller),

// History (undo/redo)
QuillToolbarHistoryButton(
  isUndo: true,
  controller: controller,
),
QuillToolbarHistoryButton(
  isUndo: false,
  controller: controller,
),
```

## Custom Toolbar Button Options

```dart
final iconTheme = QuillIconTheme(
  iconButtonSelectedData: IconButtonData(),
);

QuillToolbarToggleStyleButton(
  options: QuillToolbarToggleStyleButtonOptions(
    iconTheme: iconTheme,
  ),
  controller: controller,
  attribute: Attribute.bold,
),
```

## Common Attributes

```dart
// Text styles
Attribute.bold
Attribute.italic
Attribute.underline
Attribute.strikeThrough

// Lists
Attribute.ol        // Ordered list
Attribute.ul         // Unordered list
Attribute.check       // Checklist

// Code
Attribute.inlineCode
Attribute.codeBlock

// Quotes
Attribute.blockQuote

// Links
Attribute.link(url)

// Headers
Attribute.h1
Attribute.h2
Attribute.h3
```

## Delta Operations

```dart
// Insert text
controller.document.compose(
  Delta()..insert('Hello'),
  ChangeSource.local,
);

// Format selection
controller.formatText(
  TextSelection(baseOffset: 0, extentOffset: 5),
  Attribute.bold,
);

// Get current selection
final selection = controller.selection;

// Get document content as plain text
final text = controller.document.toPlainText();

// Get Delta JSON
final deltaJson = jsonEncode(controller.document.toDelta().toJson());
```

## Extensions (flutter_quill_extensions)

```dart
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

// Image button
QuillToolbarImageButton(controller: controller),

// Camera button
QuillToolbarCameraButton(controller: controller),

// Video button (if enabled)
QuillToolbarVideoButton(controller: controller),

// Embed builders in editor config
embedBuilders: [
  ...FlutterQuillEmbeds.editorBuilders(
    imageEmbedConfig: QuillEditorImageEmbedConfig(...),
    videoEmbedConfig: QuillEditorVideoEmbedConfig(...),
  ),
],
```

## Quick Reference

| Task              | API                                                                  |
| ----------------- | -------------------------------------------------------------------- |
| Create controller | `QuillController.basic()` or `QuillController(document: ...)`        |
| Editor widget     | `QuillEditor(controller: ..., config: ...)`                          |
| Toolbar button    | `QuillToolbar*Button(controller: ...)`                               |
| Format text       | `controller.formatText(selection, attribute)`                        |
| Insert text       | `controller.document.compose(Delta()..insert(...), ...)`             |
| Get Delta JSON    | `jsonEncode(controller.document.toDelta().toJson())`                 |
| Load from Delta   | `QuillController(document: Document.fromDelta(Delta.fromJson(...)))` |
| Plain text        | `controller.document.toPlainText()`                                  |
| Image embed       | `QuillToolbarImageButton` + `FlutterQuillEmbeds.editorBuilders`      |
| Localization      | `FlutterQuillLocalizations.delegate`                                 |

## Constraints

- Use `FocusNode` with editor for proper keyboard handling.
- Delta format is JSON; store as string in database.
- Extensions require `flutter_quill_extensions` package.
- Custom embed builders must return widgets or null.
- Toolbar buttons require the same `controller` instance as editor.
