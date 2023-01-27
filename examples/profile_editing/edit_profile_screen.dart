import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wellai_flutter/generated/assets.gen.dart';
import 'package:wellai_flutter/generated/l10n.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/screens/edit_profile_screen/route/route.dart';
import 'package:wellai_flutter/screens/fill_profile_info/fill_profile_info.dart';
import 'package:wellai_flutter/styles/color_palette.dart';
import 'package:wellai_flutter/styles/formatters.dart';
import 'package:wellai_flutter/styles/text_styles.dart';
import 'package:wellai_flutter/widgets/keyboard_notifier/keyboard_notifier.dart';
import 'package:wellai_flutter/widgets/loading_layer/loading_layer.dart';
import 'package:wellai_flutter/widgets/main_avatar/main_avatar.dart';
import 'package:wellai_flutter/widgets/main_button/main_button.dart';
import 'package:wellai_flutter/widgets/persistent_footer_container/persistent_footer_container.dart';
import 'package:wellai_flutter/widgets/primary_text_button/primary_text_button.dart';
import 'package:wellai_flutter/widgets/profile_text_field/profile_text_field.dart';
import 'package:wellai_flutter/widgets/snackbar/snackbar.dart';
import 'package:wellai_flutter/utils/extensions/phone_code_extension.dart';

import 'bloc/edit_profile_screen_bloc.dart';
import 'view_model/profile_screen_view_model.dart';

part 'widgets/custom_input_picker.dart';
part 'widgets/edit_profile_app_bar.dart';
part 'widgets/edit_profile_bloc_listener.dart';
part 'widgets/edit_profile_date_picker.dart';
part 'widgets/edit_profile_main_body.dart';
part 'widgets/edit_profile_persistent_footer.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardNotifier(
      child: _EditProfileBlocListener(
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: const [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      _EditProfileAppBar(),
                      _MainProfileBody(),
                    ],
                  ),
                ),
                _PersistentFooter()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
void _buildCupertinoModal({
  required BuildContext context,
  required List<CupertinoActionSheetAction> actions,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => CupertinoActionSheet(
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: Text(S.of(context).cancel),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );
}
