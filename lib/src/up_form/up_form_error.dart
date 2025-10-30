part of 'up_form.dart';

///
/// Throw this error to set the field error in [UpForm.submitter] or [UpField.submitter] methods.
/// ```dart
/// throw UpFormFieldsError(fields: {upFormState[fieldName].fieldKey: "Invalid"});
/// ```
///
class UpFormFieldsError extends UpFormError {
  final Map<UpFieldKey,String> fields;
  const UpFormFieldsError({required this.fields, super.message, super.code, super.exception});

  @override
  String toString() => '${super.toString()}  ${fields.entries.map((e) => '\n . ${e.key}: ${e.value}').join('')}';
}

///
///
///
class UpFormError extends UpFormException{
  final String? code;
  final String? message;
  final Object? exception;
  const UpFormError({this.message, this.code, this.exception});

  @override
  String toString() => '$runtimeType: $message';
}

///
///
///
class UpFormException {
  const UpFormException();
}
