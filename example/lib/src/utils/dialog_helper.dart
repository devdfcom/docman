import 'package:docman_example/src/ui/widgets/list_tiles.dart' show ListHeader;
import 'package:docman_example/src/ui/widgets/modal_text_field.dart';
import 'package:docman_example/src/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

class DialogHelper {
  BuildContext get context => AppRouter.context;

  Future<String?> input({
    required String header,
    required String initValue,
    IconData? leftIcon,
    String? suffixText,
    bool numbersOnly = false,
    bool textOnly = false,
    bool canBeEmpty = false,
    int? maxLength,
    TextInputType? keyboardType,
    FilteringTextInputFormatter? customFilter,
    TextCapitalization? textCapitalization,
  }) async =>
      showModalBottomSheet(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
        ),
        isScrollControlled: true,
        context: context,
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom + 10
                  : MediaQuery.of(context).padding.bottom),
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListHeader(
                padding: EdgeInsets.only(top: 10.0, left: 10.0),
                color: Theme.of(context).colorScheme.onSurface,
                text: header,
              ),
              ModalTextField(
                selected: initValue,
                onSelect: AppRouter.goBack,
                leftIcon: leftIcon,
                canBeEmpty: canBeEmpty,
                numbersOnly: numbersOnly,
                suffixText: suffixText,
                textOnly: textOnly,
                maxLength: maxLength,
                keyboardType: keyboardType,
                customFilter: customFilter,
                textCapitalization: textCapitalization,
              ),
            ],
          ),
        ),
      );
}
