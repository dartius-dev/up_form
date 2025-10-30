import 'package:equalone/equalone.dart';
import 'package:flutter/material.dart';


class TextFieldClearButton extends StatelessWidget with EqualoneMixin {
  
  final FocusNode focusNode;
  final TextEditingController textController;
  final Widget emptyIcon;
  final Widget clearIcon;
  final bool? hide;

  const TextFieldClearButton({
    required this.textController,
    required this.focusNode,
    this.hide, 
    this.emptyIcon = const SizedBox.shrink(), 
    this.clearIcon = const Icon(Icons.clear),
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: focusNode, builder: (_, child) {
        return (hide ?? !focusNode.hasFocus) ? emptyIcon : child!;
      },
      child: ListenableBuilder(listenable: textController, builder: (_, child) {
          return textController.text.isEmpty ? emptyIcon : child!;
        },
        child: TextFieldTapRegion(
          child: InkWell(
            canRequestFocus: false,
            radius: 1,
            onTap: clear,
            child: clearIcon,
          ),
        )
      )
    );
  }

  void clear() {
    focusNode.requestFocus();
    textController.clear();
  }
  
  @override
  List<Object?> get equalones => [focusNode, textController, hide, emptyIcon];
}