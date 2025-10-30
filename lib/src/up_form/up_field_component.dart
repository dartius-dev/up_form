part of 'up_form.dart';

typedef UpFieldComponentCreator<T, V> = T Function(UpFieldState<V> field);
typedef UpFieldComponentDisposer<T> = void Function(T component);

///
///
///
class UpFieldComponentCustomDelegate<T extends Object, V> extends UpFieldComponentDelegate<T, V> {
  final UpFieldComponentCreator<T, V> _create;
  final UpFieldComponentDisposer<T>? _dispose;

  const UpFieldComponentCustomDelegate(this._create, {UpFieldComponentDisposer<T>? dispose}) : _dispose = dispose;

  @override
  T create(UpFieldState<V> field) => _create(field);

  @override
  void dispose(T instance) => _dispose?.call(instance);
}

///
///
///
class FocusNodeComponentDelegate<T extends Object, V> extends UpFieldComponentDelegate<FocusNode, V> {

  const FocusNodeComponentDelegate([this._create = defaultCreator]);

  @override
  FocusNode create(UpFieldState field) => _create(field);

  @override
  void dispose(FocusNode instance) => instance.dispose();
  
  static FocusNode defaultCreator(UpFieldState _) => FocusNode();

  final UpFieldComponentCreator<FocusNode, dynamic> _create;
}

///
///
///
class TextControllerComponentDelegate<T extends Object, V> extends UpFieldComponentDelegate<TextEditingController, V> {

  const TextControllerComponentDelegate([this._create = defaultCreator]);

  @override
  TextEditingController create(UpFieldState<V> field) => _create(field);

  @override
  void dispose(TextEditingController instance) => instance.dispose();

  static TextEditingController defaultCreator(UpFieldState field) => TextEditingController(text: field.initialValue);

  final UpFieldComponentCreator<TextEditingController, V> _create;
}
///
///
///
abstract class UpFieldComponentDelegate<T, V> {
  const UpFieldComponentDelegate();
  T create(UpFieldState<V> field);
  void dispose(T instance){}
}

///
///
///
class _UpFieldComponentEntry<T extends Object, V> {
  final UpFieldComponentDelegate<T, V> delegate;
  final UpFieldState<V> field;
  final T instance;

  _UpFieldComponentEntry(this.field, this.delegate, [T? instance]) : instance = instance ?? delegate.create(field);
  void dispose() => delegate.dispose(instance);
}
