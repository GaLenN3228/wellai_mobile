import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wellai_flutter/main/flavors/flavor_config.dart';
import 'package:wellai_flutter/network/models/dto_models/encodable.dart';
import 'package:wellai_flutter/network/websocket/models/requests/ws_media_answer_request.dart';
import 'package:wellai_flutter/network/websocket/models/requests/ws_media_offer_request.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_approve_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_call_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_cancel_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_media_answer_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_media_offer_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_remote_peer_ice_candidate_response.dart';
import 'package:wellai_flutter/network/websocket/models/responses/ws_response_base.dart';
import 'package:wellai_flutter/network/websocket/ws_manager/ws_manager.dart';

enum CallStoreState {
  permissionNotGranted,
  outgoingCall,
  incomingCall,
  callConnected,
  endCall,
  callTempDisconnect,
  callReconnected,
}

class CallModel {
  final CallStoreState state;
  final String? callerName;

  CallModel(this.state, {this.callerName});
}

typedef CallStoreCallback = void Function(CallStoreState state, {MediaStream? stream});
typedef StreamStateCallback = void Function(MediaStream? stream);

class CallStore {
  final WSManager wsManager;

  final StreamController<CallModel> _callStreamController =
      StreamController<CallModel>.broadcast();

  late CallModel currentState;
  late StreamSubscription _subscription;
  late StreamSubscription _wsSubscription;

  final _tag = 'CallStore_tag';

  Stream<CallModel> get callStream => _callStreamController.stream;

  Stream<WsResponse> get _stream => wsManager.stream;

  late MediaStream myStream;
  String? room;
  RTCPeerConnection? peerConnection;
  MediaStream? remoteStream;

  CallStore(this.wsManager) {
    _subscription = callStream.listen((event) => currentState = event);
    _init();
  }

  void _init() {
    _wsSubscription = _stream.listen((event) {
      if (event is WsCancelResponse) {
        _onCancelEvent(event);
        return;
      }
      if (event is WsCallResponse) {
        _onCallEvent(event);
        return;
      }
      if (event is WsMediaOfferResponse) {
        _onMediaOfferEvent(event);
        return;
      }
      if (event is WsMediaAnswerResponse) {
        _onMediaAnswerResponse(event);
        return;
      }
      if (event is WsRemotePeerIceCandidateResponse) {
        _onRemotePeerIceCandidateEvent(event);
        return;
      }
      if (event is WsApproveResponse) {
        _onApproveEvent(event);
      }
    });
  }

  void _onCancelEvent(WsCancelResponse event) async {
    room = '';
    _callStreamController.sink.add(CallModel(CallStoreState.endCall));
  }

  Future<void> _onCallEvent(WsCallResponse event) async {
    room = event.room;
    var constraints = {
      "audio": true,
      "video": {'facingMode': 'user', 'optional': []}
    };
    try {
      myStream = await navigator.mediaDevices.getUserMedia(constraints);
      _callStreamController.sink.add(
          CallModel(CallStoreState.incomingCall, callerName: event.callerName));
    } catch (e) {
      _callStreamController.sink
          .add(CallModel(CallStoreState.permissionNotGranted));
      final miceStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;
      if (miceStatus.isDenied || cameraStatus.isDenied) {
        _sendPermissionDenied(event.room);
      }
    }
  }

  Future<void> _onMediaOfferEvent(WsMediaOfferResponse event) async {
    final offer = RTCSessionDescription(event.sdp, event.type);
    log(event.sdp.toString() + '_onMediaOfferEvent', name: _tag);
    peerConnection!.setRemoteDescription(offer);
    final peerAnswer = await peerConnection!.createAnswer();
    final answer = RTCSessionDescription(peerAnswer.sdp, peerAnswer.type);
    peerConnection!.setLocalDescription(answer);
    sendMediaAnswer(answer, event.room);
  }

  Future<void> _onMediaAnswerResponse(WsMediaAnswerResponse event) async {
    log(event.sdp.toString() + '_onMediaAnswerResponse', name: _tag);
    await peerConnection!.setRemoteDescription(
          RTCSessionDescription(event.sdp, event.type),
        );
  }

  Future<void> _onRemotePeerIceCandidateEvent(
      WsRemotePeerIceCandidateResponse event) async {
    final candidate =
        RTCIceCandidate(event.candidate, event.sdpMid, event.sdpMlineIndex);
    log(event.sdpMid.toString() + '_onRemotePeerIceCandidateEvent', name: _tag);
    await peerConnection!.addCandidate(candidate);
  }

  Future<void> _onApproveEvent(WsApproveResponse event) async {
    room = event.room;
    await createPeer();
    for (final track in myStream.getTracks()) {
      await peerConnection!.addTrack(track, myStream);
    }
    final localPeerOffer = await peerConnection!.createOffer();
    final offer =
        RTCSessionDescription(localPeerOffer.sdp, localPeerOffer.type);
    await peerConnection!.setLocalDescription(offer);
    sendMediaOffer(offer, event.room);
  }

  Future<void> createPeer() async {
    final _iceServers = {
      'iceTransportPolicy': "all",
      "iceServers": [
        {
          "urls": ['stun:${FlavorConfig.instance!.values.webRtcTransport}']
        },
        {
          "urls": ['turn:${FlavorConfig.instance!.values.webRtcTransport}'],
          "username": 'username',
          "credential": 'password'
        }
      ]
    };

    peerConnection = await createPeerConnection({..._iceServers});

    peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _callStreamController.sink.add(CallModel(CallStoreState.callTempDisconnect));
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _callStreamController.sink.add(CallModel(CallStoreState.callReconnected));
      }
    };

    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == "video") {
        remoteStream = event.streams[0];
        _callStreamController.sink.add(CallModel(CallStoreState.callConnected));
      }
    };

    peerConnection!.onIceCandidate = (event) {
      if (event.candidate != null) {
        //todo refactor to model
        wsManager.emit(
            'iceCandidate',
            SimpleEncodable({
              'room': room,
              'candidate': {
                "candidate": event.candidate,
                "sdpMid": event.sdpMid,
                "sdpMlineIndex": event.sdpMLineIndex,
                "sdpMLineIndex": event.sdpMLineIndex
              }
            }));
      }
    };

    _callStreamController.sink.add(CallModel(CallStoreState.callConnected));
  }

  ///todo разобраться зачем тут call back с названием function)
  call(number, RTCVideoRenderer localRenderer, VoidCallback function) async {
    final response = await wsManager.emitWithAck<WsCallResponse>(
      'call',
      SimpleEncodable({'to': number}),
    );
    room = response.room;
    const constraints = {
      "audio": true,
      "video": {'facingMode': 'user', 'optional': []},
    };
    myStream = await navigator.mediaDevices.getUserMedia(constraints);
    function.call();
  }

  void _sendPermissionDenied(String room) {
    wsManager.emit('permission-denied', SimpleEncodable({'room': room}));
  }

  cancel() async {
    //todo to model
    if (room != null) {
      wsManager.emit('cancel', SimpleEncodable({"room": room}));
      room = "";
    }
    _callStreamController.sink.add(CallModel(CallStoreState.endCall));
  }

  approve() async {
    await createPeer();
    for (final track in myStream.getTracks()) {
      await peerConnection?.addTrack(track, myStream);
    }
    wsManager.emit("approve", SimpleEncodable({"room": room}));
    _callStreamController.sink.add(CallModel(CallStoreState.callConnected));
  }

  sendMediaAnswer(RTCSessionDescription peerAnswer, String? room) {
    wsManager.emit(
        WSMediaAnswerRequest.name,
        WSMediaAnswerRequest(
            room, RTCSessionDescription(peerAnswer.sdp, peerAnswer.type)));
  }

  sendMediaOffer(RTCSessionDescription peerOffer, String? room) {
    wsManager.emit(
        WSMediaOfferRequest.name,
        WSMediaOfferRequest(
            room, RTCSessionDescription(peerOffer.sdp, peerOffer.type)));
  }

  void switchCamera() {
    Helper.switchCamera(myStream.getVideoTracks()[0]);
  }

  void muteMic() {
    bool enabled = myStream.getAudioTracks()[0].enabled;
    myStream.getAudioTracks()[0].enabled = !enabled;
  }

  void turnOnOffVideo() {
    bool enabled = myStream.getVideoTracks()[0].enabled;
    myStream.getVideoTracks()[0].enabled = !enabled;
  }

  Future<void> closeCallBloc() async {
    await myStream.dispose();
    await remoteStream?.dispose();
    await peerConnection?.close();
    peerConnection = null;
  }

  ///now used nowhere
  void dispose() {
    _subscription.cancel();
    _wsSubscription.cancel();
    _callStreamController.close();
  }
}
