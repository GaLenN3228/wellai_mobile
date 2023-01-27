import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wellai_flutter/generated/l10n.dart';
import 'package:wellai_flutter/main/login_bloc/login_bloc.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/screens/agreement_web_view_screen/route/route.dart';
import 'package:wellai_flutter/screens/login_screen/route/route.dart';
import 'package:wellai_flutter/screens/sign_up_with_email_screen/route/route.dart';
import 'package:wellai_flutter/styles/color_palette.dart';
import 'package:wellai_flutter/styles/text_styles.dart';
import 'package:wellai_flutter/widgets/main_button/main_button.dart';
import 'package:wellai_flutter/widgets/snackbar/snackbar.dart';

import 'bloc/sign_in_bloc.dart';

///Sign Up screen where user can sign up with google, apple, or email
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isFirstAgreementConfirmed = false;
  bool isSecondAgreementConfirmed = false;
  bool isThirdAgreementConfirmed = false;
  bool isFourthAgreementConfirmed = false;
  bool isButtonsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state is ErrorSignInState) {
          showCustomSnackbar(
              context, context.read<ErrorHandler>().handleError(state));
        }
        if (state is SuccessSignInState) {
          context.read<LoginBloc>().add(
                LogInEvent(
                  state.tokens.accessToken,
                  state.tokens.refreshToken,
                ),
              );
        }
      },
      buildWhen: (p, c) => (c is InitialSignInState),
      builder: (context, state) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).iHaveReviewedAndAccepted + ':',
                    style: ProjectTextStyles.ui_26Medium,
                  ),
                  const SizedBox(height: 16),
                  _buildFirstAgreement(context),
                  const SizedBox(height: 12),
                  _buildSecondAgreement(context),
                  const SizedBox(height: 12),
                  _buildThirdAgreement(context),
                  const SizedBox(height: 12),
                  _buildFourthAgreement(context),
                  const Spacer(),
                  MainButton(
                    title: S.of(context).sign_up,
                    onTap: () => Navigator.push(
                      context,
                      routeSignUpWithEmail(),
                    ),
                    isEnabled: isButtonsEnabled,
                    disabledBackgroundColor: ColorPalette.light,
                    disabledTextColor: ColorPalette.extraLight,
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    MainButton(
                      title: S.of(context).sign_up_with_apple,
                      color: ColorPalette.black,
                      onTap: () => context
                          .read<SignInBloc>()
                          .add(SignInWithAppleEvent(false)),
                      isEnabled: isButtonsEnabled,
                      disabledTextColor: ColorPalette.disabledAppleColor,
                      disabledBackgroundColor: ColorPalette.black,
                      icon: 'assets/icons_svg/ic_apple.svg',
                    ),
                  ],
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 12),
                    MainButton(
                      color: ColorPalette.white,
                      borderColor: ColorPalette.authBorderColor,
                      textColor: ColorPalette.black,
                      title: S.of(context).sign_up_with_google,
                      onTap: () => context
                          .read<SignInBloc>()
                          .add(SignInWithGoogleEvent(false)),
                      isEnabled: isButtonsEnabled,
                      icon: 'assets/icons_svg/ic_google.svg',
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      text: TextSpan(
                          style: ProjectTextStyles.ui_16Regular.copyWith(
                            color: ColorPalette.gray,
                          ),
                          children: [
                            TextSpan(
                                text: S.of(context).already_have_an_account),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    routeLogIn(),
                                  );
                                },
                              text: ' ' + S.of(context).log_in,
                              style: ProjectTextStyles.ui_16Semi.copyWith(
                                color: ColorPalette.main,
                              ),
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Row _buildFirstAgreement(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildCheckBox(
            onChange: (value) {
              setState(() {
                isFirstAgreementConfirmed = value;
              });
              activateButtonsIfAllConfirmed();
            },
            isChecked: false),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: ProjectTextStyles.ui_14Regular.copyWith(
                color: ColorPalette.gray,
              ),
              children: [
                TextSpan(text: S.of(context).i_agree_to + ' '),
                TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await Navigator.push(
                        context,
                        routeAgreementWebView(
                          urlPath:
                              'https://wellai.health/docs/aggreements/en-US/BT/terms-of-use.html',
                          title: S.of(context).well_ai_terms_of_use,
                        ),
                      );
                    },
                  text: S.of(context).well_ai_terms_of_use + ' ',
                  style: ProjectTextStyles.ui_14Semi.copyWith(
                    color: ColorPalette.main,
                  ),
                ),
                TextSpan(
                  text: S.of(context).and_confirm_that,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Row _buildSecondAgreement(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildCheckBox(
            onChange: (value) {
              setState(() {
                isSecondAgreementConfirmed = value;
              });
              activateButtonsIfAllConfirmed();
            },
            isChecked: isSecondAgreementConfirmed),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: ProjectTextStyles.ui_14Regular.copyWith(
                color: ColorPalette.gray,
              ),
              children: [
                TextSpan(
                  text: S.of(context).i_agree_to + ' ',
                  style: ProjectTextStyles.ui_14Regular
                      .copyWith(color: ColorPalette.gray),
                ),
                TextSpan(
                  text: S.of(context).well_ai_notice_of_privacy,
                  style: ProjectTextStyles.ui_14Semi.copyWith(
                    color: ColorPalette.main,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await Navigator.push(
                        context,
                        routeAgreementWebView(
                          urlPath:
                              'https://wellai.health/docs/aggreements/en-US/BT/privacy-policy.html',
                          title: S.of(context).well_ai_notice_of_privacy,
                        ),
                      );
                    },
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Row _buildThirdAgreement(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildCheckBox(
          onChange: (value) {
            setState(() {
              isThirdAgreementConfirmed = value;
            });
            activateButtonsIfAllConfirmed();
          },
          isChecked: isThirdAgreementConfirmed,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: ProjectTextStyles.ui_14Regular.copyWith(
                color: ColorPalette.gray,
              ),
              children: [
                TextSpan(
                  text: S.of(context).i_agree_to + ' ',
                  style: ProjectTextStyles.ui_14Regular
                      .copyWith(color: ColorPalette.gray),
                ),
                TextSpan(
                  text: S.of(context).well_ai_privacy_police_short,
                  style: ProjectTextStyles.ui_14Semi.copyWith(
                    color: ColorPalette.main,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await Navigator.push(
                        context,
                        routeAgreementWebView(
                          urlPath:
                              'https://wellai.health/docs/aggreements/en-US/BT/financial-agreement.html',
                          title: S.of(context).well_ai_privacy_police_short,
                        ),
                      );
                    },
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Row _buildFourthAgreement(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildCheckBox(
            onChange: (value) {
              setState(() {
                isFourthAgreementConfirmed = value;
              });
              activateButtonsIfAllConfirmed();
            },
            isChecked: false),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: ProjectTextStyles.ui_14Regular.copyWith(
                color: ColorPalette.gray,
              ),
              children: [
                TextSpan(text: S.of(context).i_agree_to + ' '),
                TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await Navigator.push(
                        context,
                        routeAgreementWebView(
                          urlPath:
                          'https://wellai.health/docs/aggreements/en-US/BT/disclamer.html',
                          title: S.of(context).disclaimer,
                        ),
                      );
                    },
                  text: S.of(context).theDisclaimer,
                  style: ProjectTextStyles.ui_14Semi.copyWith(
                    color: ColorPalette.main,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void activateButtonsIfAllConfirmed() {
    if (isFirstAgreementConfirmed &&
        isSecondAgreementConfirmed &&
        isThirdAgreementConfirmed && isFourthAgreementConfirmed) {
      setState(() {
        isButtonsEnabled = true;
      });
    } else if (isButtonsEnabled) {
      setState(() {
        isButtonsEnabled = false;
      });
    }
  }
}

class _BuildCheckBox extends StatefulWidget {
  final Function(bool value) onChange;
  final bool isChecked;

  const _BuildCheckBox(
      {Key? key, required this.onChange, required this.isChecked})
      : super(key: key);

  @override
  _BuildCheckBoxState createState() => _BuildCheckBoxState();
}

class _BuildCheckBoxState extends State<_BuildCheckBox> {
  late bool isChecked;

  @override
  void initState() {
    isChecked = widget.isChecked;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
          widget.onChange(isChecked);
        });
      },
      child: isChecked ? _buildChecked() : _buildNotChecked(),
    );
  }

  Widget _buildChecked() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: ColorPalette.main,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(
          Icons.check,
          size: 16,
          color: ColorPalette.white,
        ),
      ),
    );
  }

  Widget _buildNotChecked() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ColorPalette.borderLightGray,
          width: 2,
        ),
      ),
    );
  }
}
