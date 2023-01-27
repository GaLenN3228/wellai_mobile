import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meta/meta.dart';
import 'package:wellai_flutter/screens/tele_health_screen/call_store/call_store.dart';

part 'telehealth_event.dart';
part 'telehealth_state.dart';

class TelehealthBloc extends Bloc<TelehealthEvent, TelehealthState> {
  //todo вынести в конструктор
  final _localRender = RTCVideoRenderer();
  final _remoteRender = RTCVideoRenderer();

  final FlutterIOSVoIPKit _iosVoIPKit;

  final CallStore _callStore;
  late final StreamSubscription _callSub;
  String savedCallerName = '';

  TelehealthBloc(this._callStore, this._iosVoIPKit,) : super(LoadingTelehealthState()) {
    on<InitialTelehealthEvent>(_onInitialTelehealthEvent);
    on<ChangeCallStateTelehealthEvent>(
      _onChangeCallStateTelehealthState,
      transformer: concurrent(),
    );
    on<CallActionEvent>(_onCallActionEvent);
    on<CallToPatientTelehealthEvent>(_onCallToPatientTelehealthEvent);
  }

  void _onInitialTelehealthEvent(
      InitialTelehealthEvent event, Emitter<TelehealthState> emit) async {
    await _localRender.initialize();
    await _remoteRender.initialize();
    add(ChangeCallStateTelehealthEvent(_callStore.currentState));
    _callSub = _callStore.callStream.listen((event) {
      add(ChangeCallStateTelehealthEvent(event));
    });
  }

  void _onChangeCallStateTelehealthState(ChangeCallStateTelehealthEvent event,
      Emitter<TelehealthState> emit) async {
    switch (event.callModel.state) {
      case CallStoreState.outgoingCall:
        emit(OutgoingCallTelehealthState());
        break;
      case CallStoreState.incomingCall:
        _localRender.srcObject = _callStore.myStream;
        savedCallerName = event.callModel.callerName ?? '';
        emit(IncomingCallTelehealthState(
            _localRender, event.callModel.callerName));
        break;
      case CallStoreState.callConnected:
        if (Platform.isIOS) {
          _iosVoIPKit.endCall();
          _iosVoIPKit.onDidReceiveIncomingPush = (details) => _iosVoIPKit.endCall();
        }
        _remoteRender.srcObject = _callStore.remoteStream;
        _localRender.srcObject = _callStore.myStream;
        emit(
          CallProgressTelehealthState(
            callerName: savedCallerName,
            remoteRender: _remoteRender,
            localRender: _localRender,
          ),
        );
        break;
      case CallStoreState.callTempDisconnect:
        if (Platform.isIOS) {
          _iosVoIPKit.onDidReceiveIncomingPush = null;
        }
        emit(TempConnectionChangesState(isConnected: false));
        break;
      case CallStoreState.callReconnected:
        emit(TempConnectionChangesState(isConnected: true));
        break;
      case CallStoreState.endCall:
        if (Platform.isIOS) {
          _iosVoIPKit.onDidReceiveIncomingPush = null;
        }
        emit(EndCallTelehealthState());
        break;
      case CallStoreState.permissionNotGranted:
        ///should never get PermissionNotGranted here
        break;
    }
  }

  void _onCallActionEvent(
      CallActionEvent event, Emitter<TelehealthState> emit) async {
    ///todo relocate to callStore
    switch (event.action) {
      case CallActions.onOffVideo:
        _callStore.turnOnOffVideo();
        break;
      case CallActions.onOffMice:
        _callStore.muteMic();
        break;
      case CallActions.switchCamera:
        _callStore.switchCamera();
        break;
      case CallActions.hangUp:
        _callStore.cancel();
        break;
      case CallActions.acceptCall:
        _callStore.approve();
        break;
    }
  }

  void _onCallToPatientTelehealthEvent(
      CallToPatientTelehealthEvent event, Emitter<TelehealthState> emit) async {
    _localRender.srcObject = _callStore.myStream;
    emit(OutgoingCallTelehealthState());

    ///todo разобраться с call back'ом
    _callStore.call(event.id, _localRender, () {});
  }

  @override
  Future<void> close() async {
    try {
      await _callStore.closeCallBloc();
      _remoteRender.srcObject = null;
      _localRender.srcObject = null;
    } catch (e) {
      log(e.toString());
    }
    _callSub.cancel();
    _remoteRender.dispose();
    _localRender.dispose();
    await super.close();
  }
}

enum CallActions { onOffVideo, onOffMice, switchCamera, hangUp, acceptCall }
