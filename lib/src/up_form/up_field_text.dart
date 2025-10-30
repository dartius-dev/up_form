
import 'dart:async';
import 'package:flutter/material.dart';

import 'up_form.dart';

extension UpTextFieldStateEx on UpFieldState<String> {


  void Function(dynamic) textInputSubmitter(TextInputAction? inputAction) => (_)=> textInputSubmit(inputAction);

  FutureOr<void> textInputSubmit(TextInputAction? inputAction) {
    if (inputAction == TextInputAction.done) {
      return form.submit();
    } else if (inputAction == TextInputAction.next || inputAction == TextInputAction.previous) {
      validate();
    } else {
      return submit();
    }
  }

  TextEditingController textController({
    UpFieldComponentCreator<TextEditingController, String>? create,
    bool resetErrorOnChange = true,
  }) {
    if (maybeComponent<TextEditingController>() case final controller?) {
      return controller;
    }
    final controller = registerComponent(
      create==null ? const TextControllerComponentDelegate() : TextControllerComponentDelegate(create),
    );

    // if (resetErrorOnChange) {
    //   registerComponent<HandyTextErrorHandler>(HandyTextErrorHandler.delegate);
    // }
    return controller;
  }

  Widget textFormFieldBuilder(TextFormField Function(UpFieldState<String> field) builder) {
    final textFormField = builder(this);
    assert(textFormField.controller == maybeComponent<TextEditingController>(), "Use field.textController() to set the controller of TextFormField");
    assert(textFormField.key == fieldKey, "Use field.fieldKey to set the key of TextFormField");
    assert(textFormField.forceErrorText == forceError, "Use field.forceError to set the forceErrorText of TextFormField"); // !!! check this
    assert(textFormField.validator == validator, "Use field.validator to set the validator of TextFormField");

    return textFormField;
  }
}
