import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:wellai_flutter/managers/error_handler/error_handler.dart';
import 'package:wellai_flutter/managers/network_info.dart';
import 'package:wellai_flutter/managers/user_store.dart';
import 'package:wellai_flutter/network/models/dto_models/request/paggination.dart';
import 'package:wellai_flutter/network/models/dto_models/response/dto_nurse_chat_store.dart';
import 'package:wellai_flutter/network/models/dto_models/response/dto_user_info.dart';
import 'package:wellai_flutter/network/repository/global_repository.dart';
import 'package:wellai_flutter/network/websocket/models/requests/ws_chat_init_request.dart';
import 'package:wellai_flutter/network/websocket/models/requests/ws_chat_message_request.dart';
import 'package:wellai_flutter/network/websocket/models/requests/ws_join_chat_request.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_chat_message_response.dart';
import 'package:wellai_flutter/screens/assistant_screen/models/chat_message_models.dart';
import 'package:wellai_flutter/screens/nurse_chat_screen/view_model/nurse_chat_view_model.dart';
import 'package:wellai_flutter/screens/nurse_chat_screen/ws_chat_wrapper.dart';

part 'nurse_chat_event.dart';
part 'nurse_chat_state.dart';

class NurseChatBloc extends Bloc<NurseChatEvent, NurseChatState> {
  final WsChatWrapper _chatWrapper;
  int _chatId = 0;

  late StreamSubscription _messagesSub;
  SideType sideType = SideType.user;
  final NurseChatViewModel _viewModel;
  final GlobalRepository _repository;
  final UserStore _userStore;
  final NetworkInfo _networkInfo;
  late StreamSubscription<bool> _networkConnectionSub;

  NurseChatBloc(
    this._chatWrapper,
    this._viewModel,
    this._repository,
    this._userStore,
    this._networkInfo,
  ) : super(LoadingNurseChatState()) {
    on<SendMessageEvent>(_onSendMessageEvent);
    on<GetMessageEvent>(_onGetMessageEvent);
    on<InitialNurseChatEvent>(_onInitialNurseChatEvent);
    on<ReconnectNurseChatEvent>(_onReconnectNurseChatEvent);
    _messagesSub = _chatWrapper.messagesStream.where((event) {
      final ev = event as WsChatMessageResponse;
      return ev.chatId == _chatId;
    }).listen((event) {
      add(GetMessageEvent(event as WsChatMessageResponse));
    });
    _networkConnectionSub = _networkInfo.reconnectionStream.listen((event) {
      if (event == true) {
        add(ReconnectNurseChatEvent());
      }
    });
  }

  late int sessionId;
  bool isAnswered = false;
  bool isFinish = false;
  final List<ChatMsgBase> _chatMessages = [];

  _onSendMessageEvent(SendMessageEvent event, Emitter<NurseChatState> emit) async {
    var images;
    if ((event.message.isEmpty || event.message.trim().isEmpty) &&
        event.type == ChatMessageType.common) return;
    final currentState = state;
    if (currentState is DataNurseChatState) {
      if (event.images != null) {
        images = event.images?.map((image) => DTOImage(path: image)).toList();
      }
      _chatMessages.insert(
        0,
        typeToMessage(
          event.type,
          event.message,
          images: images,
          isMySide: true,
          isUpload: true,
        ),
      );
      emit(currentState.copyWith(messages: _chatMessages));
      if (event.type != ChatMessageType.images) {
        await _chatWrapper.sendMessage(WSChatMessageRequest(event.type, _chatId, event.message));
      }
      if (event.stopChat) {
        _viewModel.isChatActive = false;
      }
    }
  }

  void _onGetMessageEvent(GetMessageEvent event, Emitter<NurseChatState> emit) async {
    var images;
    if (event.response.type == ChatMessageType.images) {
      images = await _repository.getImagesById(event.response.text);
    }
    ChatMsgBase message = typeToMessage(event.response.type, event.response.text, images: images);
    _chatMessages.insert(0, message);
    emit(DataNurseChatState(messages: _chatMessages, sessionId: sessionId));
  }

  ChatMsgBase typeToMessage(ChatMessageType type, String text,
      {bool isMySide = false, List<DTOImage>? images, bool isUpload = false}) {
    switch (type) {
      case ChatMessageType.init:
        return SimpleChatMsg([text], isMySide: isMySide);
      case ChatMessageType.common:
        return SimpleChatMsg([text], isMySide: isMySide);
      case ChatMessageType.thankForMessage:
        return ShowHistoryMsg(
          text.splitMapJoin('\n')[0],
          text.splitMapJoin('\n')[1],
          isMySide: isMySide,
        );
      case ChatMessageType.offerTelehealth:
        return NoticeMessage(isMySide);
      case ChatMessageType.offerFinish:
        return SimpleChatMsg([text],
            isShowButtons: true,
            chatButtonTypes: [ChatButtonTypes.yes, ChatButtonTypes.noIStillHaveQuestions],
            isMySide: isMySide);
      case ChatMessageType.finish:
        return SimpleChatMsg([text], isMySide: isMySide);
      case ChatMessageType.note:
        return ShowNurseNoteMessage(text);
      case ChatMessageType.approve:
        return SimpleChatMsg([text], isMySide: isMySide);
      case ChatMessageType.images:
        return ImagesMsg(images ?? [], isMySide, _chatId, isUpload, DateTime.now());
      default:
        return SimpleChatMsg([text], isMySide: isMySide);
    }
  }

  @override
  Future<void> close() async {
    _networkConnectionSub.cancel();
    _messagesSub.cancel();
    await super.close();
  }

  void _onInitialNurseChatEvent(InitialNurseChatEvent event, Emitter<NurseChatState> emit) async {
    try {
      if (event.userId != null) {
        sessionId = event.sessionId!;
        final result = await _chatWrapper.initChat(
          WSChatInitRequest(event.userId!, sessionId: event.sessionId),
        );
        _chatId = result.id;
        await _chatWrapper.joinChat(WSJoinChatRequest(_chatId));
      }
      final chatId = event.chatId;
      if (chatId != null) {
        _chatId = chatId;
        final messagesResponse = await _fillChatMessages();
        final chatStoreStatus = messagesResponse.chatstore?[0].status;
        if (_isCompletedChat(chatStoreStatus)) {
          _viewModel.isChatActive = false;
        } else if (_isNotClosedChat(chatStoreStatus)) {
          emit(SuccessDialogState());
          await _chatWrapper.joinChat(WSJoinChatRequest(_chatId));
        }
        emit(DataNurseChatState(messages: _chatMessages, sessionId: sessionId));
      }
    } catch (e, stackTrace) {
      emit(ErrorNurseChatState(e, stackTrace));
      if (kDebugMode) rethrow;
    }
  }

  _onReconnectNurseChatEvent(ReconnectNurseChatEvent event, Emitter<NurseChatState> emit) async {
    _chatMessages.clear();
    final messages = await _fillChatMessages();
    final sessionId = _getSessionIdFromChatStore(messages);
    emit(DataNurseChatState(messages: _chatMessages, sessionId: sessionId));
  }

  bool _isCompletedChat(ChatStoreStatus? status) {
    return status == ChatStoreStatus.finish || status == ChatStoreStatus.close;
  }

  bool _isNotClosedChat(ChatStoreStatus? status) {
    return status != ChatStoreStatus.close;
  }

  Future<DtoNurseChatStore> _fillChatMessages() async {
    var result;
    final messagesResponse =
        await _repository.getNursesChatsStore(id: _chatId, pagination: Pagination());
    sessionId = _getSessionIdFromChatStore(messagesResponse);
    final chatStore = messagesResponse.chatstore!.first;
    _viewModel.isChatWithoutAssistant = chatStore.session?.assistant == null;
    final chats = chatStore.messages?.map<Future<ChatMsgBase>>(
      (e) async {
        var images;
        ChatMessageType type = messagesResponse.transformStringToMessageType(e.type ?? '');
        if (e.text != null && e.text!.isNotEmpty) {
          if (type == ChatMessageType.images) {
            images = await _repository.getImagesById(e.text!);
          }
        }
        return typeToMessage(
          type,
          e.text ?? '',
          isMySide: (_userStore.userInfo.id == e.owner?.id &&
              (type == ChatMessageType.common || type == ChatMessageType.images)),
          images: images,
          isUpload: false,
        );
      },
    );

    if (chats != null) {
      result = await Future.wait(chats);
      _chatMessages.addAll(result ?? '');
    }
    return messagesResponse;
  }

  int _getSessionIdFromChatStore(DtoNurseChatStore? messages) {
    return (messages?.chatstore != null && messages?.chatstore?[0].session != null)
        ? messages!.chatstore![0].session!.id!
        : 0;
  }
}

enum SideType { user, nurse }
