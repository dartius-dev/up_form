
import 'dart:async';
import 'dart:developer' as develop;

import 'package:equalone/equalone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'up_inherited_widget.dart';
import 'up_validators.dart';

part 'up_form_model.dart';
part 'up_field.dart';
part 'up_field_model.dart';
part 'up_field_component.dart';
part 'up_field_group.dart';
part 'up_form_error.dart';


// typedef FormFieldSaver<T> = Object? Function(T? fields);
typedef UpFormSubmitter = Future<void> Function(List<UpFieldState> changedFields);
typedef UpFormTest = bool Function(List<UpFieldState> fields);

enum UpFormIntent { create, update } 

/// [UpForm] extends a [Form] functionality. It places a [Form] widget in the widget tree.
/// 
/// [UpForm] works with [UpField], which provides a [UpFieldKey] global key for the covered [FormField]. 
/// 
/// [UpField] does not place a [FormField] widget in the widget tree, use [UpFieldState.buildFormField] to create a FormField.
/// 
/// ```dart
/// UpField.forFormField<T>(context).buildFormField(
///   builder: (state) {
///   ...
///   }
/// );
/// ```
/// 
/// To submit whole form use [UpFormState.submit] method.
/// 
/// To complete one field use [UpFieldState.submit] method.
///
/// **[UpForm.submit] steps:**
///
/// - validate process, uses a field's validator() callback to check if fields are valid
/// - submit async process (if no errors found and any value is changed)
///   - submit changed fields, by calling the [UpField.submitter] callback (if [UpForm.submitterUseFieldSubmitters] is true or [UpForm.submitter] is null)
///   - submit form, by calling the [UpForm.submitter] callback (if it is set) with list of changed fields 
/// - submitted process (if no errors occurred)
///   - sets field's initialValue to the current value
///   - calls [UpForm.onSubmitted] callback, to say that submit is successfully completed.
/// 
/// **[UpField.submit] steps:**
///
/// - validate process, uses the field validator() callback to check if field is valid
/// - submit async process (if value is valid and changed)
///   - submit field, by calling the [UpField.submitter] callback or [UpForm.submitter] with current field in list
/// - submitted process (if no errors occurred)
///   - sets initialValue to the current value
/// 
/// During submit, if any field has errors, the [UpFormFieldsError] may be thrown to set the appropriate field error.
/// 
/// (!) [UpForm] DOES NOT USE save() method of fields, Up USES submit() instead. 
/// submit() returns Future, so it can be used to save data to a database or send data to a server
/// 
/// 
class UpForm extends StatefulWidget with EqualoneMixin {
  final VoidCallback? onChanged;
  final void Function(Object error)? onError;
  final UpFormTest? canSubmit;
  final UpFormSubmitter? submitter;
  final bool? submitterUseFieldSubmitters;
  final VoidCallback? onSubmitted;
  final bool? canPop;
  final UpFormIntent? intent;
  final PopInvokedWithResultCallback<Object?>? onPopInvokedWithResult;
  final AutovalidateMode? autovalidateMode;
  final Widget child;

  const UpForm({
    super.key, 
    this.onChanged, this.onError, this.canSubmit, this.submitter, this.onSubmitted, this.intent,
    this.submitterUseFieldSubmitters, 
    this.canPop, this.onPopInvokedWithResult, this.autovalidateMode, 
    required this.child
  }); 

  @override
  List<Object?> get equalones => [
    onChanged, canSubmit, submitter, onSubmitted, intent, canPop, onPopInvokedWithResult, autovalidateMode, child
  ];

  static UpFormState of(BuildContext context, {UpFormModelCallback? watch, Object? watchId}) 
    => maybeOf(context, watch: watch, watchId: watchId)!;

  // static HandyFormState? maybeOf(BuildContext context) {
  //   final HandyFormModel? scope = context.dependOnInheritedWidgetOfExactType<HandyFormModel>();
  //   return scope?._state;
  // }
  static UpFormState? maybeOf<T>(BuildContext context, {UpFormModelCallback? watch, Object? watchId}) {
    final aspect = watch != null ? UpFormModelAspect(watch: watch, uid: watchId) : null;
    return context.dependOnInheritedWidgetOfExactType<UpFormModel>(aspect: aspect)?._state;
  }

  static V? valueOf<V>(BuildContext context, UpFormModelValueCallback<V> value,{
    UpFormModelCallback? watch, Object? watchId
  }) {
    final aspect = UpFormValueAspect<V>(value: value, watch: watch ?? value, uid: watchId);
    return aspect.valueOf(context.dependOnInheritedWidgetOfExactType<UpFormModel>(aspect: aspect));
  }

  @override
  State<UpForm> createState() => UpFormState();

  static void _noop() {}
}

///
///
///
mixin UpFormMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<UpFormState>();
  UpFormState get form => formKey.currentState!;
}

///
///
///
class UpFormState extends State<UpForm> {
  final List<UpFieldState> _fields = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _notifier = ValueNotifier<UpFormModel?>(null);

  UpFormModel? _model;
  _UpFormErrorState? _errorState;
  FormState get _formState => _formKey.currentState!;
  late Form _formWidget;


  ChangeNotifier get notifier => _notifier;
  UpFormIntent get intent => widget.intent ?? UpFormIntent.update;

  UpFieldState operator[](Object id) => fieldById(id)!;

  bool get isSubmittable => _fields.isNotEmpty && !hasError
    && _fields.every((f)=>!f.mandatory || f.isNotEmpty);

  bool get canSubmit {
    // final fields = _fields;
    // final fieldStates = _fields.map((e)=>"${e.id}:${e.mandatory?'M':''}${e.isEmpty?'E':''}").toList(); 
    return widget.canSubmit?.call(_fields) ?? isSubmittable;
  }

  bool get hasError => _errorState!=null;

  List<UpFieldState> get fields => List.unmodifiable(_fields);
  UpFieldState<T>? fieldById<T>(Object id) =>  _fields.fieldById<T>(id);
  UpFieldState<T>? fieldByKey<T>(UpFieldKey key) =>  _fields.skipWhile((f) => f.fieldKey != key || f is! UpFieldState<T>).firstOrNull as UpFieldState<T>?;

  List<UpFieldState>? errors() => switch(_errorState?.invalidFields){
    Set<UpFieldKey> errors when errors.isNotEmpty => [ for(final f in _fields) if (errors.contains(f.fieldKey)) f],
    _ => null,
  };
  
  Map keyedValues({List<UpFieldState>? fields, bool namedOnly = false, Object? Function(UpFieldState)? key}) => {
      for(final field in fields ?? _fields) 
        if ((key!=null ? key(field) : field.id) case Object fieldKey when !namedOnly || fieldKey is String) 
          fieldKey: field.value
    };

  bool validate([UpFieldKey? fieldKey]) {
    setState();

    // validate whole form
    if (fieldKey == null) {
      if (validateGranularly() case final fields when fields.isNotEmpty) {
        _errorState = _UpFormErrorState(invalidFields: fields.map((f) => f.fieldKey).toSet());
        return false;
      }
      _errorState = null;
      return true;
    }
    
    // validate one field
  final field = fieldByKey(fieldKey)!;

    if (field._validate()) {
      _errorState = _errorState?.removeField(fieldKey);
      return true;
      // if (_errorState?.invalidFields.contains(fieldKey) == true) {
      //     _errorState = _errorState!.invalidFields.length > 1 
      //       ? _errorState!.copyWith(invalidFields: _errorState!.invalidFields.difference({fieldKey}))
      //       : null;
      // }
    }
    _errorState = _errorState?.addField(fieldKey) ?? _UpFormErrorState(invalidFields: {fieldKey});
    return false;
  }

  Set<UpFieldState> validateGranularly() {
    return { ..._fields.where((f) => !f._validate())}; // _formState.validateGranularly();
  }


  void reset() {
    _formState.reset();
    for (final field in _fields) {
      field.reset();
    }
  }

  /// submit callbacks may throw the [UpFormFieldsError] exception to set enforceErrors
  FutureOr<void> submit([UpFieldKey? fieldKey]) async {
    try {
      await (fieldKey != null ? _submitField(fieldKey) : _submitForm());
    } catch (e) {
      if (e is UpFormFieldsError) {
        _errorState = _UpFormErrorState(code: e.code, message: e.message, forceErrors: e.fields, exception: e.exception);
        // for(final key in _errorState!.forceErrors.keys) { fieldByKey(key)?._refresh(); }
      } else if (e is! AssertionError && widget.onError != null) {
        widget.onError!(e);
      } else {
        rethrow;
      }
    }
    setState();
  }


  @override
  void initState() {
    super.initState();
    _buildForm();
    assert((){
      if (widget.intent!=null) return true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_fields.any((f)=>f.mandatory && f.isEmpty)) {
            develop.log('!!!\n!!! Up.intent is not set.\n!!! Up may behave unexpectedly and have unintended consequences.\n!!!');
        }
      });
      return true;
    }());
  }

  @override
  @protected
  void setState([VoidCallback fn = UpForm._noop]) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose(); 
  }

  @override
  void didUpdateWidget(covariant UpForm oldWidget) {
    if (oldWidget.child != widget.child  ||
        oldWidget.autovalidateMode != widget.autovalidateMode  ||
        oldWidget.intent != widget.intent ||
        oldWidget.submitterUseFieldSubmitters != widget.submitterUseFieldSubmitters ||
        oldWidget.canPop != widget.canPop ||
        oldWidget.onPopInvokedWithResult != widget.onPopInvokedWithResult
    ) {
      _buildForm();
    }
    super.didUpdateWidget(oldWidget);
  }
  
  @override
  Widget build(BuildContext context) {
    _model = UpFormModel._(this, 
      widget: widget, 
      fields: _fields.map((f)=>f._model!).toList(), 
      canSubmit: canSubmit,
      errorState: _errorState,
      child: _formWidget
    );

    Timer.run(()=>_notifier.value = _model); // notify listeners after the build is done);

    return _model!;
  }


  void _buildForm() {
    _formWidget = Form(
      key: _formKey,
      onChanged: _onFieldChanged,
      autovalidateMode: widget.autovalidateMode,
      canPop: widget.canPop,
      onPopInvokedWithResult: widget.onPopInvokedWithResult,
      child:  widget.child,
    );
  }

  void _onFieldModelUpdated() {
    setState();
  }

  /// is called by Form.onChanged, when any field changes (didChange or reset)
  /// TextFormField calls didChange when the text changes
  ///  
  void _onFieldChanged() {
    for(final field in _fields) {
      field._refresh();
    }
    _scheduleFrameCallback(_onFieldChangedFrameCallback);
    setState();
  }
  
  void _onFieldChangedFrameCallback() {
    if (_errorState != null) {
      var invalidFields = _errorState!.invalidFields;
      if (invalidFields.isEmpty || invalidFields.any((f) => !f.currentState!.hasError)) {
        invalidFields = invalidFields.where((f) => f.currentState!.hasError).toSet();
        _errorState = invalidFields.isNotEmpty ? _UpFormErrorState(invalidFields: invalidFields) : null;
      }
    }
    widget.onChanged?.call();
  }

  void _scheduleFrameCallback(VoidCallback callback) {
    if (_scheduleFrameCallbacks.isEmpty) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        final callbacks = [..._scheduleFrameCallbacks];
        _scheduleFrameCallbacks.clear();
        for(final callback in callbacks) { callback(); }
      });
    }
    _scheduleFrameCallbacks.add(callback);
  }

  final _scheduleFrameCallbacks = <VoidCallback>{};

  void _register(UpFieldState field) {
    if (_fields.contains(field)) return;
     _fields.add(field);
     Timer.run(setState);
  }


  void _unregister(UpFieldState field) {
    _fields.remove(field);
    Timer.run(setState);
  }


  Future<void> _submitForm() async {
  //  if (_errorState != null) {
  //    var invalidFields = _errorState!.invalidFields;
  //    if (invalidFields.isEmpty || invalidFields.any((f) => !f.currentState!.hasError)) {
  //      invalidFields = invalidFields.where((f) => f.currentState!.hasError).toSet();
  //      _errorState = invalidFields.isNotEmpty ? _UpFormErrorState(invalidFields: invalidFields) : null;
  //    }
  //  }
    if (_errorState!=null) {
      setState((){ _errorState = null; });

      final completer = Completer();
      WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
      await completer.future; // wait for the next frame to reset the force errors
    }

    if (!validate()) return;

    // _formState.save();
    final updated = <UpFieldState>[];
    for(final field in _fields) {
      if (field.initialValue!=field.value) updated.add(field);
    }

  if (updated.isNotEmpty || intent==UpFormIntent.create) {
      final fieldSubmitters = (widget.submitterUseFieldSubmitters==true || widget.submitter==null) 
        ?  switch(updated.map((f) => f._submitter).whereType<Future Function()>()){
            final submitters when submitters.isNotEmpty => submitters.toList(), _ => null,
          }
        : null;

      assert(!(widget.submitter!=null && widget.submitterUseFieldSubmitters!=true && updated.any((f) => f._submitter!=null)),
        'field.submitters are set along with form.submitter\nSet submitterUseFieldSubmitters to declare the rules for submitter usage'
      );
      if (fieldSubmitters!=null && widget.submitterUseFieldSubmitters!=false) {
        await Future.wait(fieldSubmitters.map((c) => c()).toList());
      }
      if (widget.submitter?.call(updated) case Future future) {
        await future;
      } 
    }
    
    for(final field in _fields) {
      field._submitted();
    }
    widget.onSubmitted?.call();
  }


  Future<void> _submitField(UpFieldKey fieldKey) async {
    
    if (!validate(fieldKey)) return;

    final field = fieldByKey(fieldKey)!;
    if (field.initialValue!=field.value) {
      final submitting = field._submitter!=null 
        ? field._submitter!() 
        : (intent != UpFormIntent.create ? widget.submitter?.call([field]) : null);

      if (submitting case Future future) {
        await future;
      }
    }
    field._submitted();
  }


}



/// - [invalidFields] are fields with validation errors Gets from FormFieldState.errorText.
/// It includes errors from [forceErrors] as well.
/// - [forceErrors] are fields with enforced errors. Set by submit callbacks, and should be 
/// set to Up.forceErrors to show the errorText). is used to set enforced errors for 
/// the form fields.
/// 
/// [FormField.forceErrorText] has higher priority than a validate error.
/// 
class _UpFormErrorState with EqualoneMixin {

  final Map<UpFieldKey,String> forceErrors;
  final Set<UpFieldKey> invalidFields;
  final String? code;
  final String? message;
  final Object? exception;

  const _UpFormErrorState({
    this.code, this.message, this.exception, this.forceErrors = const {}, this.invalidFields = const {}
  });

  @override
  List<Object?> get equalones => [Equalone(forceErrors), Equalone(invalidFields), code, message, exception];

  _UpFormErrorState copyWith({
    Map<UpFieldKey, String>? forceErrors,
    Set<UpFieldKey>? invalidFields,
    String? code,
    String? message,
    Object? exception,
  }) => _UpFormErrorState(
        forceErrors: forceErrors ?? this.forceErrors,
        invalidFields: invalidFields ?? this.invalidFields,
        code: code ?? this.code,
        message: message ?? this.message,
        exception: exception ?? this.exception,
      );
  
  _UpFormErrorState? removeField(UpFieldKey? exclude) {
    if (invalidFields.contains(exclude) != true) {
      assert(!forceErrors.containsKey(exclude));
      return this;
    }
    return invalidFields.length > 1 
      ? copyWith(invalidFields: invalidFields.difference({exclude}), forceErrors: {...forceErrors}..remove(exclude))
      : null;
  }

  _UpFormErrorState addField(UpFieldKey invalid) => copyWith(
    invalidFields: { ...invalidFields, invalid }, forceErrors: {...forceErrors}..remove(invalid)
  );

}

