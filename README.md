# UpForm

![beta](https://github.com/dartius-dev/up_form/raw/main//example/assets/beta.svg)

UpForm is a Flutter package that enhances standard form capabilities by providing advanced reactivity, flexible controls, and convenient form building. 

It introduces a set of widgets and utilities for managing form fields, validation, and submission logic in a more modular and extensible way. 

UpForm supports context-based validation, custom field components, and improved state management, making it easier to build complex, interactive forms in Flutter applications.

## Features

- Modular form field management
- Context-based validation
- Custom field components
- Advanced reactivity and state management
- Flexible form submission logic

## Getting Started

Add UpForm to your `pubspec.yaml`:

```yaml
dependencies:
	up_form: <latest>
```

Import in your Dart code:

```dart
import 'package:up_form/up_form.dart';
```

## Usage Example

Here is a simple example of using UpForm in a Flutter app:

```dart
  // ... somewhere in State.build()  
  UpForm(
    key: formKey,
    intent: UpFormIntent.create,
    submitter: submit,
    onError: onError,
    child: Column(children: [
      UpField<String>.named(
        name: 'text_input',
        label: 'Text input',
        mandatory: true,
        child: Builder(builder: (context) {
          final upField = UpField.of<String>(context);
          return TextFormField(
            key: upField.fieldKey,
            decoration: upField.decoration(),
            controller: upField.textController(),
            focusNode: upField.focusNode(),
            validator: upField.validator,
            forceErrorText: upField.forceError,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: 
                upField.textInputSubmitter(TextInputAction.next),
          );
        }),
      ),
      // ... more fields and submit button ...
    ]),
  )

  // ... somewhere in State
  Future<void> submit(List<UpFieldState> changedFields) {
    // ... submit 
  }
  void onError(Object? error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$error")),
  );
```

For more advanced usage and examples, see the `example` directory.

## License

MIT

