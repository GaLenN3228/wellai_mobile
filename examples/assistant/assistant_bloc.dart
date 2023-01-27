import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wellai_flutter/generated/l10n.dart';
import 'package:wellai_flutter/main/settings_provider/settings_provider.dart';
import 'package:wellai_flutter/managers/screen_update_manager/screen_update_manager.dart';
import 'package:wellai_flutter/managers/user_store.dart';
import 'package:wellai_flutter/network/models/dto_models/response/dto_assistant_audio_response.dart';
import 'package:wellai_flutter/network/models/dto_models/wellai_models/response/dto_answer_assistant_response.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/screens/assistant_screen/models/chat_message_models.dart';
import 'package:wellai_flutter/screens/assistant_screen/view_model/assistant_view_model.dart';
import 'package:wellai_flutter/utils/chat_question_generator/chat_question_generator.dart';

part 'assistant_event.dart';
part 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc(
    this._repository,
    this._lang,
    this._assistantViewModel,
    this._userStore,
    this._chatMessageFinalizer,
    this._audioPlayer,
    this._settingsManager,
    this._screenUpdateManager,
    this._sessionId,
  ) : super(InitialDataState()) {
    on<SuccessFillProfileAssistantEvent>(_onSuccessFillProfileAssistantEvent);
    on<SendMessageEvent>(_onSendMessageEvent);
    on<StartOverAssisEvent>(_onStartOverAssisEvent);
    on<StopSessionAssisEvent>(_onStopSessionAssisEvent);
  }

  final ScreenUpdateManager _screenUpdateManager;
  final SettingsManager _settingsManager;
  final AssistantViewModel _assistantViewModel;
  final ChatMessageCreator _chatMessageFinalizer;
  final S _lang;
  final AudioPlayer _audioPlayer;
  final List<ChatMsgBase> _chatMessages = [];
  final UserStore _userStore;
  final int? _sessionId;

  bool get _isFilledProfile =>
      _userStore.userInfo.profile != null && (_userStore.userInfo.profile?.profileWasFilled ?? false);

  bool get _isAttachedToClinic => _userStore.userInfo.cabinets?.isNotEmpty ?? false;

  final GlobalRepository _repository;

  @visibleForTesting
  AssistantStage assistantStage = AssisStageInit();

  void _onSuccessFillProfileAssistantEvent(SuccessFillProfileAssistantEvent event, Emitter<AssistantState> emit) {
    final currentAssistStage = assistantStage;
    // _isHaveSubscription = true;
    if (currentAssistStage is AssisStageInit) {
      final firstMessage = _chatMessages.first as SimpleChatMsg;
      _chatMessages.clear();
      add(SendMessageEvent(firstMessage.messages.first));
    } else {
      _chatMessages.removeLast();
      assistantStage = AssisStageAskSymptoms();
      add(SendMessageEvent(_lang.success_fill_profile_data));
    }
  }

  void _onStopSessionAssisEvent(StopSessionAssisEvent event, Emitter<AssistantState> emit) async {
    assistantStage = AssisStageInit();
    _chatMessages.clear();
    _assistantViewModel.changeAssistWidgetsState(false);
    _assistantViewModel.changeFooterState(true);
    _audioPlayer.dispose();
    emit(RestartAssistantState());
  }

  void _onSendMessageEvent(SendMessageEvent event, Emitter<AssistantState> emit) async {
    if (event.message.trim().isEmpty) return;
    _assistantViewModel.changeAssistantAnimatedState(true);

    final currentAssistStage = assistantStage;
    _assistantViewModel.changeAssistWidgetsState(true);

    if (currentAssistStage is AssisStageInit) {
      await _handleInitStage(event, currentAssistStage, emit);
    }

    if (currentAssistStage is AssisStageClarificationOfSymptom) {
      _handleClarificationOfSymptomStage(event, currentAssistStage, emit);
    }

    if (currentAssistStage is AssisStageAskSymptoms) {
      await _handleAskSymptomsStage(event, currentAssistStage, emit);
    }

    if (currentAssistStage is AssisStageWaitingForRetry) {
      await _handleWaitingForRetry(currentAssistStage, emit, event);
    }
  }

  void _onStartOverAssisEvent(StartOverAssisEvent event, Emitter<AssistantState> emit) async {
    _assistantViewModel.changeFooterState(true);
    _chatMessages.clear();
    _chatMessages.add(SimpleChatMsg(
      [_lang.please_tell_me_how_you_are_feeling.replaceFirst('\n', '')],
    ));
    _playText(_lang.please_tell_me_how_you_are_feeling);
    emit(DataState(_chatMessages));
    assistantStage = AssisStageInit();
  }

  Future<void> _handleInitStage(
      SendMessageEvent event, AssisStageInit currentAssistStage, Emitter<AssistantState> emit) async {
    if (currentAssistStage.isAnimationDelayHappen == false) {
      emit(DataState(const []));
      await Future.delayed(const Duration(milliseconds: 700));
      currentAssistStage.isAnimationDelayHappen = true;
    }

    try {
      var messageToHandle = event.message;
      if (_isAttachedToClinic == false) {
        _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
        _chatMessages.add(SimpleChatMsg([_lang.youAreNotAttachedToTheClinicSoYouCannot], isMySide: false));
        _playText([_lang.youAreNotAttachedToTheClinicSoYouCannot].join(', '));
        emit(DataState(_chatMessages));
        return;
      }
      if (_isFilledProfile == false && _chatMessages.isEmpty) {
        _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
        _chatMessages.add(FillProfileMsg());
        _playText([_lang.youHaveNotFilledInYourPersonalDataFillingIn].join(', '));
        emit(DataState(_chatMessages));
        return;
      }
      if (_isFilledProfile == false && _chatMessages.length == 3) {
        if (event.message.toUpperCase() == _lang.yes.toUpperCase()) {
          _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
          // _chatMessages.add(AttachToClinicMsg(hasSubscribeLater: true));
          emit(OpenAttachToClinicScreenState());
          currentAssistStage.isEndCheckAttach = false;
          emit(DataState(_chatMessages));
          return;
        }
        if (event.message.toUpperCase() == _lang.no.toUpperCase()) {
          messageToHandle = _handleRefuseAttachOffer(event, messageToHandle, currentAssistStage);
        }
      }
      if (_isFilledProfile == false && _chatMessages.length == 5 && event.message == _lang.subscribe_later) {
        messageToHandle = _handleRefuseAttachOffer(event, messageToHandle, currentAssistStage);
      }
      if (_isFilledProfile == false && currentAssistStage.isEndCheckAttach == false) {
        emit(DataState(_chatMessages));
        return;
      }

      _chatMessages.add(SimpleChatMsg([messageToHandle], isMySide: true));
      final searchMessage = SimpleChatMsg([_lang.nowSearchingOverMedicalReferences], isMySide: false);
      _chatMessages.add(searchMessage);
      _chatMessages.add(AwaitingAnimatedMsg());
      emit(DataState(_chatMessages));

      final response = await _repository.initAssistant(messageToHandle, sessionId: _sessionId);
      _chatMessages.remove(searchMessage);
      _assistantViewModel.didCreatedFromChat = _sessionId != null;

      ///is not empty
      _chatMessages.add(SimpleChatMsg(
          [_lang.here_are_symptoms_i_heard_you_experiencing, response.name, _lang.is_everything_correct],
          isShowButtons: true));
      assistantStage = AssisStageClarificationOfSymptom();
      emit(DataState(_chatMessages));
      final textToPlay =
          [_lang.here_are_symptoms_i_heard_you_experiencing, response.name, _lang.is_everything_correct].join(', ');
      await _playText(textToPlay);
    } catch (e) {
      if (e is DioError && e.response?.data['message'] == 'this symptom not found') {
        _assistantViewModel.showToolTips();
        _chatMessages.add(
          SimpleChatMsg([_lang.weHaveNotedYourSymptoms]),
        );
        emit(DataState(_chatMessages));
        _playText(_lang.weHaveNotedYourSymptoms);
      } else {
        await _connectionProblemMessage(emit, currentAssistStage);
        if (kDebugMode) rethrow;
      }
    }
  }

  String _handleRefuseAttachOffer(SendMessageEvent event, String messageToHandle, AssisStageInit currentAssistStage) {
    _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
    final firstMessage = _chatMessages.first;
    if (firstMessage is SimpleChatMsg) {
      messageToHandle = firstMessage.messages.first;
      currentAssistStage.isEndCheckAttach = true;
    }
    return messageToHandle;
  }

  void _handleClarificationOfSymptomStage(
    SendMessageEvent event,
    AssisStageClarificationOfSymptom currentAssistStage,
    Emitter<AssistantState> emit,
  ) async {
    emit(DataState(_chatMessages));
    if (event.message.toUpperCase() == _lang.yes.toUpperCase()) {
      _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
      try {
        _chatMessages.add(AwaitingAnimatedMsg());
        assistantStage = AssisStageAskSymptoms();
        add(SendMessageEvent(_lang.yes));
      } catch (e) {
        _connectionProblemMessage(emit, currentAssistStage);
        if (kDebugMode) rethrow;
      }
    }
    if (event.message.toUpperCase() == _lang.no.toUpperCase()) {
      _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
      _chatMessages.add(
        SimpleChatMsg(
          [_lang.please_tell_me_how_you_are_feeling.replaceFirst('\n', '')],
          isShowButtons: true,
          chatButtonTypes: [],
        ),
      );
      _playText(_lang.please_tell_me_how_you_are_feeling);
      assistantStage = AssisStageInit(isAnimationDelayHappen: true, isEndCheckAttach: true);
    }
  }

  Future<void> _connectionProblemMessage(Emitter<AssistantState> emit, AssistantStage currentStage) async {
    _chatMessages.add(SimpleChatMsg([_lang.i_have_some_trouble_with_connection],
        chatButtonTypes: [ChatButtonTypes.retry], isShowButtons: true));
    assistantStage = AssisStageWaitingForRetry(currentStage);
    emit(DataState(_chatMessages));
    await _playText(_lang.i_have_some_trouble_with_connection);
  }

  Future<void> _handleAskSymptomsStage(
      SendMessageEvent event, AssisStageAskSymptoms currentAssistStage, Emitter<AssistantState> emit) async {
    try {
      emit(DataState(_chatMessages));
      if (event.message.toUpperCase() == _lang.yes.toUpperCase() ||
          event.message.toUpperCase() == _lang.no.toUpperCase() ||
          event.message == _lang.success_fill_profile_data ||
          event.message == _lang.call_later) {
        final lastChatMessage = _chatMessages.last;
        if (lastChatMessage is! AwaitingAnimatedMsg) {
          _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
          _chatMessages.add(AwaitingAnimatedMsg());
        }
        final response = await _repository.assistantAnswer(event.message);

        var messageText = '';
        var description = '';
        if (response is DTONextAssistantResponse) {
          messageText = _chatMessageFinalizer.generateQuestion(response.name);
          description = response.description ?? '';
          _chatMessages.add(
            SimpleChatMsg(
              [messageText],
              description: description,
              isShowButtons: true,
            ),
          );
        }

        if (response is DTOErrorAssistantResponse) {
          messageText = response.message;
          if (messageText == 'didnt find anything') {
            messageText = _lang.weHaveNotedYourSymptoms;
            _chatMessages.add(
              SimpleChatMsg([messageText],
                  description: description,
                  isShowButtons: true,
                  sessionId: response.sessionId,
                  chatButtonTypes: [ChatButtonTypes.scheduleTelehealth]),
            );
            assistantStage = AssisStageInit(isAnimationDelayHappen: true, isEndCheckAttach: true);
          }
        }
        if (response is DTONotFoundAssistantResponse) {
          //
        }
        if (response is DTOResultAssistantResponse) {
          _screenUpdateManager.update(ScreenTypeForUpdate.sessionAndChat);
          final result = ResultDiseasesChatMsg.fromDTO(response);
          messageText += _chatMessageFinalizer.createPossibleDiseasesMessage(
              _userStore.userInfo.profile?.getFullName ?? '', result.diseases.map((e) => e.name).join(','));
          _chatMessages.add(DisclaimerChatMsg());
          _chatMessages.add(result);
        }
        final result = _chatMessages.whereType<ResultDiseasesChatMsg>();

        emit(DataState(_chatMessages, isSlowAnimation: result.isNotEmpty));
        _playText(messageText);
      }
    } catch (e) {
      _connectionProblemMessage(emit, currentAssistStage);
      if (kDebugMode) rethrow;
    }
  }

  _handleWaitingForRetry(
      AssisStageWaitingForRetry currentAssistStage, Emitter<AssistantState> emit, SendMessageEvent event) {
    if (event.message == _lang.retry) {
      _chatMessages.add(SimpleChatMsg([event.message], isMySide: true));
      final message = (_chatMessages[_chatMessages.length - 4] as SimpleChatMsg).messages.first;
      assistantStage = currentAssistStage.previousStage;
      add(SendMessageEvent(message));
    }
  }

  // String _convertSymptomResultToMessage(String symptomResult) {
  //   if (symptomResult == GeneratorConstants.finished_asking_questions) {
  //     if (isAttachedToTheClinic) {
  //       return _chatMessageFinalizer.createPossibleDiseasesMessage(
  //           'Max',
  //           _nextSymptomCalculator!
  //               .getResult()
  //               .diseases
  //               .map((e) => e.name)
  //               .join(', '));
  //     } else {
  //       return _lang.i_have_diagnoses_buy_subscription;
  //     }
  //   }
  //   if (symptomResult == GeneratorConstants.didnt_find_anything) {
  //     return _lang.i_didnt_find_anything_please_try_again;
  //   }
  //   return _chatMessageFinalizer.generateQuestion(symptomResult);

  // }

  Future<void> _playText(String text) async {
    if (_settingsManager.settingsModel.isVoiceAssistantAvailable) {
      try {
        final ttsResponse = await _repository.textToSpeech(text: text).timeout(const Duration(seconds: 4));
        final audioPath = await _createAndWriteMp3File(ttsResponse);
        await _audioPlayer.stop();
        await _audioPlayer.play(audioPath, isLocal: true);
      } catch (e) {
        log(e.toString() + '❌❌❌');
      }
    }
  }

  Future<String> _createAndWriteMp3File(DTOAssistantAudio audioResponse) async {
    var mp3Bytes = base64.decode(audioResponse.audioContent);
    final tempDir = await getTemporaryDirectory();
    final mp3File = File('${tempDir.path}/${const Uuid().v1()}assistant.mp3');
    if (await mp3File.exists()) {
      mp3File.deleteSync();
    }
    await mp3File.writeAsBytes(mp3Bytes);
    return mp3File.path;
  }
}

abstract class AssistantStage {}

class AssisStageInit implements AssistantStage {
  bool isAnimationDelayHappen;
  bool isEndCheckAttach;

  AssisStageInit({
    this.isAnimationDelayHappen = false,
    this.isEndCheckAttach = false,
  });
}

class AssisStageClarificationOfSymptom implements AssistantStage {
  AssisStageClarificationOfSymptom();
}

class AssisStageWaitingForAttach implements AssistantStage {}

class AssisStageWaitingForRetry implements AssistantStage {
  final AssistantStage previousStage;

  AssisStageWaitingForRetry(this.previousStage);
}

class AssisStageAskSymptoms implements AssistantStage {
  bool isAskAboutCovid = false;
}
