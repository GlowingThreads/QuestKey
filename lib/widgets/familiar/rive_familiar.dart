/// Rive renderer for a familiar.
///
/// Drop `assets/images/familiars/<species>.riv` into the project and the
/// den uses it instead of the painter. `FamiliarSprite.loadRive` parses the
/// file once per species and hands it to this widget; if it can't be loaded
/// the den keeps the painter. The file should expose a state
/// machine named `Familiar` (the artboard's first state machine is used as
/// a fallback) with these inputs, all optional:
///
/// * `action` (number): 0 idle, 1 walk, 2 sit, 3 sleep, 4 groom, 5 stretch
/// * `walking` (boolean): true while the familiar crosses the den
/// * `mood` (number): 0 sleepy, 1 watchful, 2 content, 3 joyful
/// * `facingLeft` (boolean): set when the familiar faces left; the stage
///   also mirrors the artboard, so leave this unwired unless the file
///   handles facing itself
/// * `hop` (trigger): fired on a tap or a completed quest
///
/// Uses the Rive 0.13 Flutter runtime, which matches the Flutter version this
/// project pins. Its small native helper (`rive_common`) is compiled into
/// the app by the plugin build, so nothing is downloaded at runtime.
library;

import 'package:flutter/material.dart';
import 'package:quest_key/models/familiar.dart';
import 'package:quest_key/widgets/familiar/familiar_behaviour.dart';
import 'package:rive/rive.dart';

class RiveFamiliar extends StatefulWidget {
  const RiveFamiliar({
    super.key,
    required this.file,
    required this.action,
    required this.mood,
    required this.facingRight,
    required this.hopTrigger,
    this.dimmed = false,
  });

  final RiveFile file;
  final FamiliarAction action;
  final FamiliarMood mood;
  final bool facingRight;
  final int hopTrigger;
  final bool dimmed;

  static const String stateMachineName = 'Familiar';

  static int actionIndex(FamiliarAction action) => switch (action) {
    FamiliarAction.idle => 0,
    FamiliarAction.walk => 1,
    FamiliarAction.sit => 2,
    FamiliarAction.sleep => 3,
    FamiliarAction.groom => 4,
    FamiliarAction.stretch => 5,
    FamiliarAction.hop => 0,
  };

  @override
  State<RiveFamiliar> createState() => _RiveFamiliarState();
}

class _RiveFamiliarState extends State<RiveFamiliar> {
  StateMachineController? _controller;
  SMINumber? _action;
  SMIBool? _walking;
  SMINumber? _mood;
  SMIBool? _facingLeft;
  SMITrigger? _hop;

  void _onInit(Artboard artboard) {
    var controller = StateMachineController.fromArtboard(
      artboard,
      RiveFamiliar.stateMachineName,
    );
    if (controller == null && artboard.stateMachines.isNotEmpty) {
      controller = StateMachineController.fromArtboard(
        artboard,
        artboard.stateMachines.first.name,
      );
    }
    if (controller == null) return;
    artboard.addController(controller);
    _controller = controller;
    _action = controller.findSMI<SMINumber>('action');
    _walking = controller.findSMI<SMIBool>('walking');
    _mood = controller.findSMI<SMINumber>('mood');
    _facingLeft = controller.findSMI<SMIBool>('facingLeft');
    _hop = controller.findSMI<SMITrigger>('hop');
    _sync();
  }

  void _sync() {
    _action?.value = RiveFamiliar.actionIndex(widget.action).toDouble();
    _walking?.value = widget.action == FamiliarAction.walk;
    _mood?.value = widget.mood.index.toDouble();
    _facingLeft?.value = !widget.facingRight;
  }

  @override
  void didUpdateWidget(RiveFamiliar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (widget.hopTrigger != oldWidget.hopTrigger) _hop?.fire();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.dimmed ? 0.45 : 1,
      child: RiveAnimation.direct(
        widget.file,
        fit: BoxFit.contain,
        onInit: _onInit,
        placeHolder: const SizedBox.expand(),
      ),
    );
  }
}
