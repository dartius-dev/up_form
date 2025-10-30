
import 'package:flutter/material.dart';

import '../up_form/up_form.dart';

// TODO may we avoid this class and use TextEditingController directly in UpFieldState?
// see Pinput implementation, it uses TextEditingController directly

/// 
///
///
class ControlledTextFormField extends FormField<String> {
  ControlledTextFormField({
    super.key,
    String? initialValue,
    super.enabled,
    super.autovalidateMode,
    this.controller,
    super.forceErrorText,
    super.validator,
    super.errorBuilder,
    this.groupId = EditableText,
    super.restorationId,
    required super.builder,
  }) : assert(initialValue == null || controller == null),
       super(
         initialValue: controller != null ? controller.text : (initialValue ?? ''),
       );

  factory ControlledTextFormField.from( UpFieldState<String> field, {
    TextEditingController? controller,
    FormFieldErrorBuilder? errorBuilder,
    AutovalidateMode? autovalidateMode,
    bool? enabled,
    String?  restorationId,    
    required FormFieldBuilder<String> builder,
  }) {
    return ControlledTextFormField(
  key: field.fieldKey,
      controller: controller,
      initialValue: field.initialValue,
  forceErrorText: field.forceError,
  validator: field.validator,
      enabled: field.enabled && enabled!=false,
      errorBuilder: errorBuilder,
      autovalidateMode: autovalidateMode,
      restorationId: restorationId,
      builder: builder,
    );
  }
  final TextEditingController? controller;

  final Object groupId;

  @override
  FormFieldState<String> createState() => ControlledTextFormFieldState();
}

///
///
///
class ControlledTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;

  TextEditingController get controller => widget.controller ?? _controller!;

  @override
  ControlledTextFormField get widget => super.widget as ControlledTextFormField;

  @override
  void initState() {
    super.initState();
    (widget.controller ?? _setupController(TextEditingValue(text: widget.initialValue ?? ''))).addListener(_handleControllerChanged);
  }
  
  TextEditingController _setupController(TextEditingValue value) {
    if (_controller == null) {
      _controller = TextEditingController.fromValue(value);
    } else {
      _controller!.value = value;
    }
    return _controller!;
  }

  @override
  void didUpdateWidget(ControlledTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (widget.controller == null) { 
        // oldWidget.controller != null, cuz widget.controller != oldWidget.controller
        _setupController(oldWidget.controller!.value).addListener(_handleControllerChanged);
      } else {
        setValue(widget.controller!.text);
        if (oldWidget.controller == null) {
          _controller?.removeListener(_handleControllerChanged);
          _controller?.dispose();
          _controller = null;
        }
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    _controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);

    // if value set outside of this class, we need to update the controller
    if (controller.text != value) {
      controller.value = TextEditingValue(text: value ?? '');
    }
  }

  @override
  void reset() {
    controller.value = TextEditingValue(text: widget.initialValue ?? '');
    super.reset();
  }

  void _handleControllerChanged() {
    if (controller.text == value) return;
    super.didChange(controller.text);
  }
}
