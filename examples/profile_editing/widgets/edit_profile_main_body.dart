part of '../edit_profile_screen.dart';

@immutable
class _MainProfileBody extends StatelessWidget {
  const _MainProfileBody({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileScreenViewModel>();
    return SliverFillRemaining(
      hasScrollBody: false,
      child: IgnorePointer(
        ignoring: !context.read<EditProfileScreenViewModel>().isEditable,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: vm.formFieldKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                ProfileTextField(
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                  title: S.of(context).first_name,
                  validate: (value) => profileNameValidator(value?.removeCountryCode(), context),
                  controller: vm.firstNameController,
                  focusNode: vm.firstNameFocusNode,
                ),
                ProfileTextField(
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                  title: S.of(context).last_name,
                  controller: vm.lastNameController,
                  focusNode: vm.lastNameFocusNode,
                  validate: (value) => profileNameValidator(value, context),
                ),
                _CustomDatePicker(
                  onChange: (date) => vm.setDateOfBirth = date,
                  initialDate: vm.getDateOfBirth,
                  hintText: Formatters.scheduleMonthDayYear(
                    vm.getDateOfBirth,
                  ),
                ),
                _CustomInputPicker(
                  value: vm.getBiologicalSex,
                  onTap: () => _buildCupertinoModal(
                    context: context,
                    actions: <CupertinoActionSheetAction>[
                      CupertinoActionSheetAction(
                        child: Text(
                          S.of(context).female,
                        ),
                        onPressed: () {
                          vm.setBiologicalSex = S.of(context).female;
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoActionSheetAction(
                        child: Text(
                          S.of(context).male,
                        ),
                        onPressed: () {
                          vm.setBiologicalSex = S.of(context).male;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                ProfileTextField(
                  title: S.of(context).email,
                  controller: vm.emailController,
                  focusNode: vm.emailFocusNode,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                ),
                ProfileTextField(
                  title: S.of(context).phone,
                  controller: vm.phoneController,
                  focusNode: vm.phoneFocusNode,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                  validate: (value) => phoneValidator(value?.removeCountryCode(), context),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    Formatters.phoneFormatter,
                  ],
                ),
                ProfileTextField(
                  title: S.of(context).address,
                  controller: vm.addressController,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                ),
                ProfileTextField(
                  title: S.of(context).address_second,
                  controller: vm.addressSecondController,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                ),
                ProfileTextField(
                  title: S.of(context).city,
                  controller: vm.cityController,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                ),
                ProfileTextField(
                  onTap: () async {
                    final state = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => const ChooseState(),
                      ),
                    );
                    if (state != null) {
                      vm.statesController.text = state;
                    }
                  },
                  title: S.of(context).states,
                  controller: vm.statesController,
                  readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                ),
                InkWell(
                  child: ProfileTextField(
                    title: S.of(context).zipCode,
                    controller: vm.zipCodeController,
                    readOnly: !context.read<EditProfileScreenViewModel>().isEditable,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? profileNameValidator(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return S.of(context).thisFieldCantBeEmpty;
    }
    return null;
  }

  String? phoneValidator(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return S.of(context).thisFieldCantBeEmpty;
    } else if (value.length != 15) {
      return S.of(context).incorrectNumberOfCharactersPhoneNumber;
    }
    return null;
  }
}
