// import 'dart:async';

// import 'package:agora_rtc_engine/rtc_engine.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:flutter_vector_icons/flutter_vector_icons.dart';
// import 'package:howl/configs/agora_configs.dart';
// import 'package:howl/models/call.dart';
// import 'package:howl/providers/user_provider.dart';
// import 'package:howl/resources/call_methods.dart';
// import 'package:provider/provider.dart';

// class CallScreen extends StatefulWidget {
//   final Call call;

//   const CallScreen({@required this.call});
//   @override
//   _CallScreenState createState() => _CallScreenState();
// }

// class _CallScreenState extends State<CallScreen> {
//   final CallMethods callMethods = CallMethods();
//   UserProvider userProvider;
//   StreamSubscription callSubscription;

//   static final _users = <int>[];
//   final _infoStrings = <String>[];
//   bool muted = false;

//   @override
//   void initState() {
//     super.initState();
//     initializeAgora();
//     addPostFrameCallback();
//   }

//   addPostFrameCallback() {
//     SchedulerBinding.instance.addPostFrameCallback((_) {
//       userProvider = Provider.of<UserProvider>(context, listen: false);
//       callSubscription = callMethods
//           .callStream(uid: userProvider.getUser.id)
//           .listen((DocumentSnapshot ds) {
//         switch (ds.data) {
//           case null:
//             Navigator.pop(context);
//             break;
//           default:
//             break;
//         }
//       });
//     });
//   }

//   Future<void> initializeAgora() async {
//     if (APP_ID.isEmpty) {
//       setState(() {
//         _infoStrings.add(
//           'APP_ID missing, please provide your APP_ID in settings.dart',
//         );
//         _infoStrings.add('Agora Engine is not starting');
//       });
//       return;
//     }

//     await _initAgoraRtcEngine();
//     _addAgoraEventHandlers();
//     await AgoraRtcEngine.enableWebSdkInteroperability(true);
//     VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
//     configuration.dimensions = Size(1920, 1080);
//     await AgoraRtcEngine.setVideoEncoderConfiguration(configuration);
//     await AgoraRtcEngine.joinChannel(null, widget.call.channelId, null, 0);
//   }

//   Future<void> _initAgoraRtcEngine() async {
//     await AgoraRtcEngine.create(APP_ID);
//     await AgoraRtcEngine.enableVideo();
//   }

//   /// Add agora event handlers
//   void _addAgoraEventHandlers() {
//     AgoraRtcEngine.onError = (dynamic code) {
//       setState(() {
//         final info = 'onError: $code';
//         _infoStrings.add(info);
//       });
//     };

//     AgoraRtcEngine.onJoinChannelSuccess = (
//       String channel,
//       int uid,
//       int elapsed,
//     ) {
//       setState(() {
//         final info = 'onJoinChannel: $channel, uid: $uid';
//         _infoStrings.add(info);
//       });
//     };

//     AgoraRtcEngine.onLeaveChannel = () {
//       setState(() {
//         _infoStrings.add('onLeaveChannel');
//         _users.clear();
//       });
//     };

//     AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
//       setState(() {
//         final info = 'userJoined: $uid';
//         _infoStrings.add(info);
//         _users.add(uid);
//       });
//     };

//     AgoraRtcEngine.onUserOffline = (int uid, int reason) {
//       callMethods.endCall(call: widget.call);
//       setState(() {
//         final info = 'userOffline: $uid';
//         _infoStrings.add(info);
//         _users.remove(uid);
//       });
//     };

//     AgoraRtcEngine.onFirstRemoteVideoFrame = (
//       int uid,
//       int width,
//       int height,
//       int elapsed,
//     ) {
//       setState(() {
//         final info = 'firstRemoteVideo: $uid ${width}x $height';
//         _infoStrings.add(info);
//       });
//     };
//   }

//   void _onToggleMute() {
//     setState(() {
//       muted = !muted;
//     });
//     AgoraRtcEngine.muteLocalAudioStream(muted);
//   }

//   void _onSwitchCamera() {
//     AgoraRtcEngine.switchCamera();
//   }

//   @override
//   void dispose() {
//     callSubscription.cancel();

//     _users.clear();
//     // destroy sdk
//     AgoraRtcEngine.leaveChannel();
//     AgoraRtcEngine.destroy();

//     super.dispose();
//   }

//   List<Widget> _getRenderViews() {
//     final List<AgoraRenderWidget> list = [];

//     _users.forEach((int uid) => list.add(AgoraRenderWidget(uid)));
//     return list;
//   }

//   /// Video view wrapper
//   Widget _videoView(view) {
//     return Expanded(child: Container(child: view));
//   }

//   /// Video view row wrapper
//   Widget _expandedVideoRow(List<Widget> views) {
//     final wrappedViews = views.map<Widget>(_videoView).toList();
//     return Expanded(
//       child: Row(
//         children: wrappedViews,
//       ),
//     );
//   }

//   Widget _viewRows() {
//     final views = _getRenderViews();
//     switch (views.length) {
//       case 1:
//         return Container(
//             child: Column(
//           children: <Widget>[_videoView(views[0])],
//         ));
//       case 2:
//         return Container(
//             child: Column(
//           children: <Widget>[
//             _expandedVideoRow([views[0]]),
//             _expandedVideoRow([views[1]])
//           ],
//         ));
//       case 3:
//         return Container(
//             child: Column(
//           children: <Widget>[
//             _expandedVideoRow(views.sublist(0, 2)),
//             _expandedVideoRow(views.sublist(2, 3))
//           ],
//         ));
//       case 4:
//         return Container(
//             child: Column(
//           children: <Widget>[
//             _expandedVideoRow(views.sublist(0, 2)),
//             _expandedVideoRow(views.sublist(2, 4))
//           ],
//         ));
//       default:
//     }
//     return Container();
//   }

//   /// Toolbar layout
//   Widget _toolbar() {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         height: 120,
//         child: Center(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: <Widget>[
//               GestureDetector(
//                 onTap: () {},
//                 child: Container(
//                   decoration: BoxDecoration(
//                       color: Colors.white, shape: BoxShape.circle),
//                   child: Container(
//                     height: 50,
//                     width: 50,
//                     margin: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border:
//                             Border.all(color: Colors.grey.shade400, width: 1)),
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: _onToggleMute,
//                 child: Container(
//                   height: 56,
//                   width: 56,
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                       color:
//                           muted ? Theme.of(context).accentColor : Colors.white,
//                       shape: BoxShape.circle),
//                   child: Icon(
//                     muted ? Feather.mic_off : Feather.mic,
//                     color: muted
//                         ? Colors.white
//                         : Theme.of(context).accentIconTheme.color,
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: _onSwitchCamera,
//                 child: Container(
//                   height: 56,
//                   width: 56,
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                       color: Colors.white, shape: BoxShape.circle),
//                   child: Icon(
//                     Feather.repeat,
//                     color: Theme.of(context).accentIconTheme.color,
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: () => callMethods.endCall(call: widget.call),
//                 child: Container(
//                   height: 56,
//                   width: 56,
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                       color: Colors.redAccent, shape: BoxShape.circle),
//                   child: Icon(
//                     Feather.phone_off,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Info panel to show logs
//   Widget _panel() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       alignment: Alignment.bottomCenter,
//       child: FractionallySizedBox(
//         heightFactor: 0.5,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 48),
//           child: ListView.builder(
//             reverse: true,
//             itemCount: _infoStrings.length,
//             itemBuilder: (BuildContext context, int index) {
//               if (_infoStrings.isEmpty) {
//                 return null;
//               }
//               return Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 3,
//                   horizontal: 10,
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Flexible(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 2,
//                           horizontal: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.yellowAccent,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         child: Text(
//                           _infoStrings[index],
//                           style: TextStyle(color: Colors.blueGrey),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Calling ${userProvider.getUser.username}'),
//       ),
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Stack(
//           children: <Widget>[
//             _viewRows(),
//             _panel(),
//             _toolbar(),
//           ],
//         ),
//       ),
//     );
//   }
// }
