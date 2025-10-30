part of 'up_form.dart';

///
///
///
class UpFieldGroup extends StatefulWidget {
  final Widget child;
  const UpFieldGroup({super.key, required this.child});

  static UpFieldGroupState of(BuildContext context) => maybeOf(context)!;
  static UpFieldGroupState? maybeOf(BuildContext context) => context.findAncestorStateOfType<UpFieldGroupState>();

  @override
  State<UpFieldGroup> createState() => UpFieldGroupState();
}

///
///
///
class UpFieldGroupState extends State<UpFieldGroup> {
  late final UpFieldGroupState? parent;
  final List<UpFieldState> fields = [];

  @override
  void initState() {
    super.initState();
    parent = context.findAncestorStateOfType<UpFieldGroupState>();
  }

  void _register(UpFieldState field) {
    context.findAncestorStateOfType<UpFieldGroupState>()?._register(field);
    if (fields.contains(field)) return;
    fields.add(field);
  }
  
  void _unregister(UpFieldState field) {
    parent?._unregister(field);
    fields.remove(field);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}