import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../app/constants.dart';
import '../../core/services/ar_placement_support_service.dart';

class ArPlacementScreen extends StatefulWidget {
  final String modelPath;
  final String itemName;

  const ArPlacementScreen({
    super.key,
    required this.modelPath,
    required this.itemName,
  });

  @override
  State<ArPlacementScreen> createState() => _ArPlacementScreenState();
}

class _ArPlacementScreenState extends State<ArPlacementScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;

  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  bool _planeDetected = false;
  ArPlacementSupport? _arPlacementSupport;

  @override
  void initState() {
    super.initState();
    _loadArPlacementSupport();
  }

  Future<void> _loadArPlacementSupport() async {
    final support = await ArPlacementSupportService.getSupport();
    if (!mounted) return;

    setState(() {
      _arPlacementSupport = support;
    });
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final support = _arPlacementSupport;
    if (support == null) {
      return _buildCompatibilityLoadingScreen();
    }

    if (!support.isSupported) {
      return _buildUnsupportedScreen(support.message ?? 'This device cannot start the AR placement experience.');
    }

    return Scaffold(
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _removeAll,
                      tooltip: 'Remove all',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instruction banner
          if (!_planeDetected)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Move your phone slowly to detect surfaces',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tap to place hint
          if (_planeDetected && _nodes.isEmpty)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Tap on a surface to place furniture',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Placed successfully hint
          if (_nodes.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Drag to move • Rotate with two fingers',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }

  Widget _buildUnsupportedScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android, size: 48, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                const Text(
                  'AR placement is unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Back to 3D Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;
    _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _arSessionManager?.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handlePans: true,
        handleRotation: true,
      );
      _arObjectManager?.onInitialize();
    });

    // Planes are visually shown by ARCore (showPlanes: true).
    // We mark _planeDetected once the first plane tap succeeds.
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (_arAnchorManager == null || _arObjectManager == null) return;

    // Mark that we detected a plane on first valid tap
    if (!_planeDetected && mounted) {
      setState(() => _planeDetected = true);
    }

    final planeHit = hitTestResults.where(
      (hit) => hit.type == ARHitTestResultType.plane,
    );
    if (planeHit.isEmpty) return;

    final hit = planeHit.first;

    // Create anchor at the tapped position
    final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await _arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor != true) return;

    _anchors.add(newAnchor);

    // Determine node type based on model path
    final NodeType nodeType;
    final String uri;
    if (widget.modelPath.startsWith('http')) {
      nodeType = NodeType.webGLB;
      uri = widget.modelPath;
    } else {
      // Local flutter asset
      nodeType = NodeType.localGLTF2;
      uri = widget.modelPath;
    }

    // Attach 3D model to the anchor
    final newNode = ARNode(
      type: nodeType,
      uri: uri,
      scale: vm.Vector3(0.5, 0.5, 0.5),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    final didAddNode = await _arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
    if (didAddNode == true) {
      _nodes.add(newNode);
      if (mounted) setState(() {});
    }
  }

  Future<void> _removeAll() async {
    if (_arAnchorManager == null) return;
    for (final anchor in _anchors) {
      await _arAnchorManager!.removeAnchor(anchor);
    }
    _anchors.clear();
    _nodes.clear();
    if (mounted) setState(() {});
  }
}
