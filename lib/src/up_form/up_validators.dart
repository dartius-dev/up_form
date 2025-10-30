
import 'package:equalone/equalone.dart';
import 'package:flutter/widgets.dart';

typedef ContextBasedMessage = String Function(BuildContext context);

typedef UpValidator<T> = ContextBasedValidator<T>;
typedef UpTextValidator = ContextBasedTextValidator;


abstract class ContextBasedTextValidator with ContextBasedValidator<String> {

  const factory ContextBasedTextValidator.filled() = FilledContextBasedTextValidator;
  const factory ContextBasedTextValidator.numeric({ContextBasedMessage? message}) = NumericContextBasedTextValidator;
  const factory ContextBasedTextValidator.email({ContextBasedMessage? message}) = EmailContextBasedTextValidator;
  const factory ContextBasedTextValidator.decimal({ContextBasedMessage? message}) = DecimalContextBasedTextValidator;
  const factory ContextBasedTextValidator.regexp(String pattern, {ContextBasedMessage? message}) = RegexpContextBasedTextValidator;
  const factory ContextBasedTextValidator.length({required int min, int? max, ContextBasedMessage? message}) = LengthContextBasedTextValidator;

  const ContextBasedTextValidator();
}

  
///
///
///
class ContextBasedValidators<T> extends ContextBasedValidator<T> {
  final List<ContextBasedValidator<T>> validators;

  const ContextBasedValidators(this.validators);

  @override
  ContextBasedMessage? doValidate(T? value) {
    for(final validator in validators) {
      if (validator.doValidate(value) case ContextBasedMessage result) return result;
    }
    return null;
  }
}

///
///
///
class RequiredContextBasedValidator<T> extends ContextBasedValidator<T> {

  const RequiredContextBasedValidator();

  @override
  ContextBasedMessage? doValidate(Object? value) => Equalone.empty(value) ? ContextBasedValidator.requiredValue : null;
}

///
///
///
class FormFieldContextBasedValidator<T> extends ContextBasedValidator<T> {
  final FormFieldValidator<T> validator;
  @override
  final Map<String, Object?> messageParams;

  const FormFieldContextBasedValidator(this.validator, {this.messageParams = const {}});

  @override
  ContextBasedMessage? doValidate(T? value) => switch(validator(value)) {
    final String message => (_)=>message,
    _ => null,
  };
 
}

///
///
///
class TestContextBasedValidator<T> extends ContextBasedValidator<T> {
  final bool Function(T? value) test;
  final ContextBasedMessage? message;
  const TestContextBasedValidator(this.test, {this.message});

  @override
  ContextBasedMessage? doValidate(T? value) 
      => test(value) ? null : (message ?? ContextBasedValidator.invalidValue);
}

///
///
///
class FilledContextBasedTextValidator extends RegexpContextBasedTextValidator {
  const FilledContextBasedTextValidator({super.message}) : super(r"^\S(.*\S)?$");
}

///
///
///
class EmailContextBasedTextValidator extends RegexpContextBasedTextValidator {
  const EmailContextBasedTextValidator({super.message}) : super(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
}

///
///
///
class NumericContextBasedTextValidator extends RegexpContextBasedTextValidator {
  const NumericContextBasedTextValidator({super.message}) : super(r"^[0-9]+?$");
}

///
///
///
class DecimalContextBasedTextValidator extends RegexpContextBasedTextValidator {
  const DecimalContextBasedTextValidator({super.message}) : super(r"^[0-9]+?([.,][0-9]+)?$");
}

///
///
///
class RegexpContextBasedTextValidator extends ContextBasedTextValidator {

  final String pattern;
  final ContextBasedMessage? message;
  const RegexpContextBasedTextValidator(this.pattern, {this.message});

  @override
  ContextBasedMessage? doValidate(String? value) 
      => value==null || !re.hasMatch(value) ? message ?? ContextBasedValidator.invalidValue : null;

  RegExp get re => RegExp(pattern);
  
  // RegExp get re => _regExps[pattern] ?? (_regExps[pattern] = RegExp(pattern));
  // static final _regExps = <String, RegExp>{};   
}

///
///
///
class LengthContextBasedTextValidator extends ContextBasedTextValidator {

  final int min;
  final int? max;
  final ContextBasedMessage? message;
  const LengthContextBasedTextValidator({required this.min, this.max, this.message});

  @override
  @protected
  ContextBasedMessage? doValidate(String? value) => switch(value?.characters.length){
    final int n => n>=min && (max==null || n<=max!) ? null : (message ?? ContextBasedValidator.invalidValue),
    _ => message ?? ContextBasedValidator.requiredValue,
  };
  
  @override
  @protected
  Map<String, dynamic> get messageParams => {
    'min': min,
    if (max!=null) 'max': max!,
  };  
}



///
///
///
abstract mixin class ContextBasedValidator<T> {

  const factory ContextBasedValidator.from(FormFieldValidator<T> validator, {Map<String, Object?> messageParams}) = FormFieldContextBasedValidator<T>;

  const factory ContextBasedValidator.test(bool Function(T?) test, {ContextBasedMessage? message}) = TestContextBasedValidator<T>;
  const factory ContextBasedValidator.list(List<ContextBasedValidator<T>> validators) = ContextBasedValidators<T>;
  const factory ContextBasedValidator.required() = RequiredContextBasedValidator<T>;

  const ContextBasedValidator();

  String? validate(T? value, [BuildContext? context]) 
    => switch(doValidate(value)?.call(context ?? ContextBasedValidator.localeContext)) {
      final String message when message.contains('{{') => _prepareMessage(message),
      final result => result,
    };
  
  FormFieldValidator<T> withContext(BuildContext context) => (value) => validate(value, context);

  @protected
  ContextBasedMessage? doValidate(T? value);
  @protected
  Map<String, dynamic> get messageParams => {};

  String _prepareMessage(String message) {
    messageParams.forEach((key, value) {
      message = message.replaceAll('{{$key}}', value.toString());
    });
    return message;
  }

  /// Call this method in main.dart to initialize the validator messages
  /// ```dart
  /// ContextBasedValidator.initialize(
  ///   invalidValueMessage: (context) => MyAppLocalizations.of(context).invalidErrorText,
  ///   requiredValueMessage: (context) => FormBuilderLocalizations.of(context).requiredErrorText,
  ///   localeContextGlobalKey: _rootNavigatorKey,
  /// );
  /// ```
  static void initialize({
    ContextBasedMessage? invalidValueMessage,
    ContextBasedMessage? requiredValueMessage,
    GlobalKey? localeContextGlobalKey,
  }) {
    if (invalidValueMessage case ContextBasedMessage value) invalidValue = value;
    if (requiredValueMessage case ContextBasedMessage value) requiredValue = value;
    _localeContextGlobalKey = localeContextGlobalKey;
  }
  static ContextBasedMessage invalidValue = _invalidValue;
  static ContextBasedMessage requiredValue = _requiredValue;
  static BuildContext get localeContext {
    assert(_localeContextGlobalKey !=null, 
      'ContextBasedValidator.localeContext is not defined.\n'
      'Add ContextBasedValidator.initialize(localeContextGlobalKey: _rootNavigatorKey) in main.dart to set it.'
    );
    return _localeContextGlobalKey!.currentContext!;
  }
  static GlobalKey? _localeContextGlobalKey;

  static String _invalidValue(BuildContext context) => 'Invalid value';
  static String _requiredValue(BuildContext context) => 'Value is required';
}

