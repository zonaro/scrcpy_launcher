import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'scrcpy_profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrcpy Launcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScrcpyLauncherPage(),
    );
  }
}

class ScrcpyLauncherPage extends StatefulWidget {
  const ScrcpyLauncherPage({super.key});

  @override
  State<ScrcpyLauncherPage> createState() => _ScrcpyLauncherPageState();
}

class _ScrcpyLauncherPageState extends State<ScrcpyLauncherPage> {
  List<ScrcpyProfile> _profiles = [];
  ScrcpyProfile? _selectedProfile;
  final TextEditingController _profileNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _scrcpyPathController = TextEditingController();
  
  // Vídeo
  final TextEditingController _videoBitrateController = TextEditingController(text: '8M');
  final TextEditingController _maxSizeController = TextEditingController();
  final TextEditingController _maxFpsController = TextEditingController();
  final TextEditingController _angleController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _videoBufferController = TextEditingController();
  String _videoCodec = 'h264';
  String _videoSource = 'display';
  
  // Áudio
  final TextEditingController _audioBitrateController = TextEditingController(text: '128K');
  final TextEditingController _audioBufferController = TextEditingController();
  final TextEditingController _audioOutputBufferController = TextEditingController();
  String _audioCodec = 'opus';
  String _audioSource = 'output';
  bool _audioDup = false;
  bool _noAudio = false;
  bool _noAudioPlayback = false;
  bool _requireAudio = false;
  
  // Display
  String _orientation = '0';
  final TextEditingController _displayOrientationController = TextEditingController();
  final TextEditingController _captureOrientationController = TextEditingController();
  final TextEditingController _recordOrientationController = TextEditingController();
  final TextEditingController _displayIdController = TextEditingController();
  String _displayImePolicy = '';
  final TextEditingController _newDisplayController = TextEditingController();
  
  // Controle
  bool _alwaysOnTop = false;
  bool _fullscreen = false;
  bool _showTouches = false;
  bool _noControl = false;
  bool _stayAwake = false;
  bool _turnScreenOff = false;
  bool _powerOffOnClose = false;
  bool _disableScreensaver = false;
  String _keyboard = '';
  String _mouse = '';
  String _gamepad = '';
  final TextEditingController _mouseBindController = TextEditingController();
  bool _otg = false;
  
  // Câmera
  final TextEditingController _cameraIdController = TextEditingController();
  final TextEditingController _cameraSizeController = TextEditingController();
  final TextEditingController _cameraArController = TextEditingController();
  final TextEditingController _cameraFpsController = TextEditingController();
  String _cameraFacing = '';
  bool _cameraHighSpeed = false;
  
  // Conexão
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _tcpipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _tunnelHostController = TextEditingController();
  final TextEditingController _tunnelPortController = TextEditingController();
  bool _selectUsb = false;
  bool _selectTcpip = false;
  bool _forceAdbForward = false;
  bool _killAdbOnClose = false;
  
  // Gravação
  final TextEditingController _recordController = TextEditingController();
  String _recordFormat = '';
  final TextEditingController _pushTargetController = TextEditingController();
  
  // Janela
  bool _windowBorderless = false;
  final TextEditingController _windowTitleController = TextEditingController();
  final TextEditingController _windowXController = TextEditingController();
  final TextEditingController _windowYController = TextEditingController();
  final TextEditingController _windowWidthController = TextEditingController();
  final TextEditingController _windowHeightController = TextEditingController();
  
  // Configurações avançadas
  bool _noPlayback = false;
  bool _noVideoPlayback = false;
  bool _noVideo = false;
  bool _noWindow = false;
  bool _noCleanup = false;
  bool _noClipboardAutosync = false;
  bool _noDownsizeOnError = false;
  bool _noKeyRepeat = false;
  bool _noMipmaps = false;
  bool _noMouseHover = false;
  bool _noPowerOn = false;
  bool _noVdDestroyContent = false;
  bool _noVdSystemDecorations = false;
  bool _legacyPaste = false;
  bool _preferText = false;
  bool _rawKeyEvents = false;
  bool _printFps = false;
  String _pauseOnExit = '';
  final TextEditingController _timeLimitController = TextEditingController();
  final TextEditingController _screenOffTimeoutController = TextEditingController();
  final TextEditingController _shortcutModController = TextEditingController();
  final TextEditingController _startAppController = TextEditingController();
  String _verbosity = '';
  String _renderDriver = '';

  @override
  void dispose() {
    _scrcpyPathController.dispose();
    _videoBitrateController.dispose();
    _maxSizeController.dispose();
    _maxFpsController.dispose();
    _angleController.dispose();
    _cropController.dispose();
    _videoBufferController.dispose();
    _audioBitrateController.dispose();
    _audioBufferController.dispose();
    _audioOutputBufferController.dispose();
    _displayOrientationController.dispose();
    _captureOrientationController.dispose();
    _recordOrientationController.dispose();
    _displayIdController.dispose();
    _newDisplayController.dispose();
    _mouseBindController.dispose();
    _cameraIdController.dispose();
    _cameraSizeController.dispose();
    _cameraArController.dispose();
    _cameraFpsController.dispose();
    _serialController.dispose();
    _tcpipController.dispose();
    _portController.dispose();
    _tunnelHostController.dispose();
    _tunnelPortController.dispose();
    _recordController.dispose();
    _pushTargetController.dispose();
    _windowTitleController.dispose();
    _windowXController.dispose();
    _windowYController.dispose();
    _windowWidthController.dispose();
    _windowHeightController.dispose();
    _timeLimitController.dispose();
    _screenOffTimeoutController.dispose();
    _shortcutModController.dispose();
    _startAppController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadLastConfig();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('scrcpy_profiles');
    setState(() {
      _profiles = ScrcpyProfile.decodeList(json);
    });
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scrcpy_profiles', ScrcpyProfile.encodeList(_profiles));
  }

  Future<void> _loadLastConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _scrcpyPathController.text = prefs.getString('scrcpyPath') ?? '';
    _videoBitrateController.text = prefs.getString('videoBitrate') ?? '8M';
    _maxSizeController.text = prefs.getString('maxSize') ?? '';
    setState(() {
      _alwaysOnTop = prefs.getBool('alwaysOnTop') ?? false;
      _fullscreen = prefs.getBool('fullscreen') ?? false;
      _showTouches = prefs.getBool('showTouches') ?? false;
      _noControl = prefs.getBool('noControl') ?? false;
      _orientation = prefs.getString('orientation') ?? '0';
    });
  }

  Future<void> _saveLastConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scrcpyPath', _scrcpyPathController.text);
    await prefs.setString('videoBitrate', _videoBitrateController.text);
    await prefs.setString('maxSize', _maxSizeController.text);
    await prefs.setBool('alwaysOnTop', _alwaysOnTop);
    await prefs.setBool('fullscreen', _fullscreen);
    await prefs.setBool('showTouches', _showTouches);
    await prefs.setBool('noControl', _noControl);
    await prefs.setString('orientation', _orientation);
  }

  void _fillFromProfile(ScrcpyProfile profile) {
    _scrcpyPathController.text = profile.scrcpyPath;
    _videoBitrateController.text = profile.videoBitrate;
    _maxSizeController.text = profile.maxSize;
    setState(() {
      _alwaysOnTop = profile.alwaysOnTop;
      _fullscreen = profile.fullscreen;
      _showTouches = profile.showTouches;
      _noControl = profile.noControl;
      _orientation = profile.orientation;
      _videoCodec = profile.videoCodec;
      _audioCodec = profile.audioCodec;
      _audioSource = profile.audioSource;
      _noAudio = profile.noAudio;
      _requireAudio = profile.requireAudio;
      // Adicionar outros campos conforme necessário
    });
  }

  ScrcpyProfile _getCurrentProfile(String name) {
    return ScrcpyProfile(
      name: name,
      scrcpyPath: _scrcpyPathController.text,
      videoBitrate: _videoBitrateController.text,
      maxSize: _maxSizeController.text,
      alwaysOnTop: _alwaysOnTop,
      fullscreen: _fullscreen,
      showTouches: _showTouches,
      noControl: _noControl,
      orientation: _orientation,
      videoCodec: _videoCodec,
      audioCodec: _audioCodec,
      audioSource: _audioSource,
      noAudio: _noAudio,
      requireAudio: _requireAudio,
      // Adicionar outros campos conforme necessário
    );
  }

  Future<void> _saveCurrentAsProfile() async {
    final name = _profileNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um nome para o perfil!')));
      return;
    }
    final profile = _getCurrentProfile(name);
    setState(() {
      _profiles.removeWhere((p) => p.name == name);
      _profiles.add(profile);
      _selectedProfile = profile;
    });
    await _saveProfiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil salvo!')));
  }

  Future<void> _deleteProfile(ScrcpyProfile profile) async {
    setState(() {
      _profiles.removeWhere((p) => p.name == profile.name);
      if (_selectedProfile?.name == profile.name) {
        _selectedProfile = null;
      }
    });
    await _saveProfiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil excluído!')));
  }

  Future<void> _startScrcpy({bool execute = false}) async {
    await _saveLastConfig();
    final path = _scrcpyPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o caminho do scrcpy!')),
      );
      return;
    }
    
    final args = <String>[];
    
    // Vídeo
    if (_videoBitrateController.text.isNotEmpty) args.add('--video-bit-rate=${_videoBitrateController.text}');
    if (_maxSizeController.text.isNotEmpty) args.add('--max-size=${_maxSizeController.text}');
    if (_maxFpsController.text.isNotEmpty) args.add('--max-fps=${_maxFpsController.text}');
    if (_angleController.text.isNotEmpty) args.add('--angle=${_angleController.text}');
    if (_cropController.text.isNotEmpty) args.add('--crop=${_cropController.text}');
    if (_videoBufferController.text.isNotEmpty) args.add('--video-buffer=${_videoBufferController.text}');
    if (_videoCodec != 'h264') args.add('--video-codec=$_videoCodec');
    if (_videoSource != 'display') args.add('--video-source=$_videoSource');
    
    // Áudio
    if (_audioBitrateController.text.isNotEmpty && _audioBitrateController.text != '128K') {
      args.add('--audio-bit-rate=${_audioBitrateController.text}');
    }
    if (_audioBufferController.text.isNotEmpty) args.add('--audio-buffer=${_audioBufferController.text}');
    if (_audioOutputBufferController.text.isNotEmpty) args.add('--audio-output-buffer=${_audioOutputBufferController.text}');
    if (_audioCodec != 'opus') args.add('--audio-codec=$_audioCodec');
    if (_audioSource != 'output') args.add('--audio-source=$_audioSource');
    if (_audioDup) args.add('--audio-dup');
    if (_noAudio) args.add('--no-audio');
    if (_noAudioPlayback) args.add('--no-audio-playback');
    if (_requireAudio) args.add('--require-audio');
    
    // Display
    if (_orientation != '0') args.add('--orientation=$_orientation');
    if (_displayOrientationController.text.isNotEmpty) args.add('--display-orientation=${_displayOrientationController.text}');
    if (_captureOrientationController.text.isNotEmpty) args.add('--capture-orientation=${_captureOrientationController.text}');
    if (_recordOrientationController.text.isNotEmpty) args.add('--record-orientation=${_recordOrientationController.text}');
    if (_displayIdController.text.isNotEmpty) args.add('--display-id=${_displayIdController.text}');
    if (_displayImePolicy.isNotEmpty) args.add('--display-ime-policy=$_displayImePolicy');
    if (_newDisplayController.text.isNotEmpty) args.add('--new-display=${_newDisplayController.text}');
    
    // Controle
    if (_alwaysOnTop) args.add('--always-on-top');
    if (_fullscreen) args.add('--fullscreen');
    if (_showTouches) args.add('--show-touches');
    if (_noControl) args.add('--no-control');
    if (_stayAwake) args.add('--stay-awake');
    if (_turnScreenOff) args.add('--turn-screen-off');
    if (_powerOffOnClose) args.add('--power-off-on-close');
    if (_disableScreensaver) args.add('--disable-screensaver');
    if (_keyboard.isNotEmpty) args.add('--keyboard=$_keyboard');
    if (_mouse.isNotEmpty) args.add('--mouse=$_mouse');
    if (_gamepad.isNotEmpty) args.add('--gamepad=$_gamepad');
    if (_mouseBindController.text.isNotEmpty) args.add('--mouse-bind=${_mouseBindController.text}');
    if (_otg) args.add('--otg');
    
    // Câmera
    if (_cameraIdController.text.isNotEmpty) args.add('--camera-id=${_cameraIdController.text}');
    if (_cameraSizeController.text.isNotEmpty) args.add('--camera-size=${_cameraSizeController.text}');
    if (_cameraArController.text.isNotEmpty) args.add('--camera-ar=${_cameraArController.text}');
    if (_cameraFpsController.text.isNotEmpty) args.add('--camera-fps=${_cameraFpsController.text}');
    if (_cameraFacing.isNotEmpty) args.add('--camera-facing=$_cameraFacing');
    if (_cameraHighSpeed) args.add('--camera-high-speed');
    
    // Conexão
    if (_serialController.text.isNotEmpty) args.add('--serial=${_serialController.text}');
    if (_selectUsb) args.add('--select-usb');
    if (_selectTcpip) args.add('--select-tcpip');
    if (_tcpipController.text.isNotEmpty) args.add('--tcpip=${_tcpipController.text}');
    if (_portController.text.isNotEmpty) args.add('--port=${_portController.text}');
    if (_tunnelHostController.text.isNotEmpty) args.add('--tunnel-host=${_tunnelHostController.text}');
    if (_tunnelPortController.text.isNotEmpty) args.add('--tunnel-port=${_tunnelPortController.text}');
    if (_forceAdbForward) args.add('--force-adb-forward');
    if (_killAdbOnClose) args.add('--kill-adb-on-close');
    
    // Gravação
    if (_recordController.text.isNotEmpty) args.add('--record=${_recordController.text}');
    if (_recordFormat.isNotEmpty) args.add('--record-format=$_recordFormat');
    if (_pushTargetController.text.isNotEmpty) args.add('--push-target=${_pushTargetController.text}');
    
    // Janela
    if (_windowBorderless) args.add('--window-borderless');
    if (_windowTitleController.text.isNotEmpty) args.add('--window-title=${_windowTitleController.text}');
    if (_windowXController.text.isNotEmpty) args.add('--window-x=${_windowXController.text}');
    if (_windowYController.text.isNotEmpty) args.add('--window-y=${_windowYController.text}');
    if (_windowWidthController.text.isNotEmpty) args.add('--window-width=${_windowWidthController.text}');
    if (_windowHeightController.text.isNotEmpty) args.add('--window-height=${_windowHeightController.text}');
    
    // Configurações avançadas
    if (_noPlayback) args.add('--no-playback');
    if (_noVideoPlayback) args.add('--no-video-playback');
    if (_noVideo) args.add('--no-video');
    if (_noWindow) args.add('--no-window');
    if (_noCleanup) args.add('--no-cleanup');
    if (_noClipboardAutosync) args.add('--no-clipboard-autosync');
    if (_noDownsizeOnError) args.add('--no-downsize-on-error');
    if (_noKeyRepeat) args.add('--no-key-repeat');
    if (_noMipmaps) args.add('--no-mipmaps');
    if (_noMouseHover) args.add('--no-mouse-hover');
    if (_noPowerOn) args.add('--no-power-on');
    if (_noVdDestroyContent) args.add('--no-vd-destroy-content');
    if (_noVdSystemDecorations) args.add('--no-vd-system-decorations');
    if (_legacyPaste) args.add('--legacy-paste');
    if (_preferText) args.add('--prefer-text');
    if (_rawKeyEvents) args.add('--raw-key-events');
    if (_printFps) args.add('--print-fps');
    if (_pauseOnExit.isNotEmpty) args.add('--pause-on-exit=$_pauseOnExit');
    if (_timeLimitController.text.isNotEmpty) args.add('--time-limit=${_timeLimitController.text}');
    if (_screenOffTimeoutController.text.isNotEmpty) args.add('--screen-off-timeout=${_screenOffTimeoutController.text}');
    if (_shortcutModController.text.isNotEmpty) args.add('--shortcut-mod=${_shortcutModController.text}');
    if (_startAppController.text.isNotEmpty) args.add('--start-app=${_startAppController.text}');
    if (_verbosity.isNotEmpty) args.add('--verbosity=$_verbosity');
    if (_renderDriver.isNotEmpty) args.add('--render-driver=$_renderDriver');

    final command = '"$path" ${args.join(' ')}';

    if (execute) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iniciando scrcpy...')),
        );
        await Process.start(path, args, mode: ProcessStartMode.detached);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar scrcpy: $e')),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Comando gerado'),
          content: SelectableText(command),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<ScrcpyProfile?>(
            value: _selectedProfile,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Perfil',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<ScrcpyProfile?>(
                value: null,
                child: Text('Configuração manual'),
              ),
              ..._profiles.map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Expanded(child: Text(p.name)),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          tooltip: 'Excluir perfil',
                          onPressed: () async {
                            await _deleteProfile(p);
                          },
                        ),
                      ],
                    ),
                  )),
            ],
            onChanged: (profile) {
              setState(() {
                _selectedProfile = profile;
              });
              if (profile != null) {
                _fillFromProfile(profile);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: TextFormField(
            controller: _profileNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do perfil',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveCurrentAsProfile,
          child: const Text('Salvar como perfil'),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return ExpansionTile(
      title: const Text('📹 Vídeo'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _videoBitrateController,
                      decoration: const InputDecoration(
                        labelText: 'Bitrate do vídeo',
                        hintText: 'Ex: 8M',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Tamanho máximo (px)',
                        hintText: 'Ex: 1024',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxFpsController,
                      decoration: const InputDecoration(
                        labelText: 'FPS máximo',
                        hintText: 'Ex: 60',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _angleController,
                      decoration: const InputDecoration(
                        labelText: 'Ângulo de rotação',
                        hintText: 'Ex: 90',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _videoCodec,
                      decoration: const InputDecoration(
                        labelText: 'Codec de vídeo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'h264', child: Text('H.264')),
                        DropdownMenuItem(value: 'h265', child: Text('H.265')),
                        DropdownMenuItem(value: 'av1', child: Text('AV1')),
                      ],
                      onChanged: (v) => setState(() => _videoCodec = v ?? 'h264'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _videoSource,
                      decoration: const InputDecoration(
                        labelText: 'Fonte de vídeo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'display', child: Text('Display')),
                        DropdownMenuItem(value: 'camera', child: Text('Câmera')),
                      ],
                      onChanged: (v) => setState(() => _videoSource = v ?? 'display'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cropController,
                      decoration: const InputDecoration(
                        labelText: 'Crop (largura:altura:x:y)',
                        hintText: 'Ex: 1920:1080:0:0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _videoBufferController,
                      decoration: const InputDecoration(
                        labelText: 'Buffer de vídeo (ms)',
                        hintText: 'Ex: 50',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return ExpansionTile(
      title: const Text('🎵 Áudio'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _audioBitrateController,
                      decoration: const InputDecoration(
                        labelText: 'Bitrate do áudio',
                        hintText: 'Ex: 128K',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _audioCodec,
                      decoration: const InputDecoration(
                        labelText: 'Codec de áudio',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'opus', child: Text('Opus')),
                        DropdownMenuItem(value: 'aac', child: Text('AAC')),
                        DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                        DropdownMenuItem(value: 'raw', child: Text('Raw')),
                      ],
                      onChanged: (v) => setState(() => _audioCodec = v ?? 'opus'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _audioSource,
                decoration: const InputDecoration(
                  labelText: 'Fonte de áudio',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'output', child: Text('Output')),
                  DropdownMenuItem(value: 'playback', child: Text('Playback')),
                  DropdownMenuItem(value: 'mic', child: Text('Microfone')),
                  DropdownMenuItem(value: 'mic-unprocessed', child: Text('Mic (não processado)')),
                  DropdownMenuItem(value: 'mic-camcorder', child: Text('Mic (câmera)')),
                  DropdownMenuItem(value: 'mic-voice-recognition', child: Text('Mic (reconhecimento de voz)')),
                  DropdownMenuItem(value: 'mic-voice-communication', child: Text('Mic (comunicação)')),
                  DropdownMenuItem(value: 'voice-call', child: Text('Chamada de voz')),
                  DropdownMenuItem(value: 'voice-call-uplink', child: Text('Chamada (uplink)')),
                  DropdownMenuItem(value: 'voice-call-downlink', child: Text('Chamada (downlink)')),
                  DropdownMenuItem(value: 'voice-performance', child: Text('Performance de voz')),
                ],
                onChanged: (v) => setState(() => _audioSource = v ?? 'output'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _audioBufferController,
                      decoration: const InputDecoration(
                        labelText: 'Buffer de áudio (ms)',
                        hintText: 'Ex: 50',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _audioOutputBufferController,
                      decoration: const InputDecoration(
                        labelText: 'Buffer de saída (ms)',
                        hintText: 'Ex: 5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  FilterChip(
                    label: const Text('Duplicar áudio'),
                    selected: _audioDup,
                    onSelected: (v) => setState(() => _audioDup = v),
                  ),
                  FilterChip(
                    label: const Text('Sem áudio'),
                    selected: _noAudio,
                    onSelected: (v) => setState(() => _noAudio = v),
                  ),
                  FilterChip(
                    label: const Text('Sem playback de áudio'),
                    selected: _noAudioPlayback,
                    onSelected: (v) => setState(() => _noAudioPlayback = v),
                  ),
                  FilterChip(
                    label: const Text('Exigir áudio'),
                    selected: _requireAudio,
                    onSelected: (v) => setState(() => _requireAudio = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return ExpansionTile(
      title: const Text('📱 Display'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _orientation,
                decoration: const InputDecoration(
                  labelText: 'Orientação',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('0° (Padrão)')),
                  DropdownMenuItem(value: '90', child: Text('90°')),
                  DropdownMenuItem(value: '180', child: Text('180°')),
                  DropdownMenuItem(value: '270', child: Text('270°')),
                ],
                onChanged: (v) => setState(() => _orientation = v ?? '0'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _displayOrientationController,
                      decoration: const InputDecoration(
                        labelText: 'Orientação do display',
                        hintText: 'Ex: 90, flip90',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _captureOrientationController,
                      decoration: const InputDecoration(
                        labelText: 'Orientação de captura',
                        hintText: 'Ex: @90',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _displayIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID do display',
                        hintText: 'Ex: 0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _displayImePolicy.isEmpty ? null : _displayImePolicy,
                      decoration: const InputDecoration(
                        labelText: 'Política IME',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Padrão')),
                        DropdownMenuItem(value: 'local', child: Text('Local')),
                        DropdownMenuItem(value: 'fallback', child: Text('Fallback')),
                        DropdownMenuItem(value: 'hide', child: Text('Ocultar')),
                      ],
                      onChanged: (v) => setState(() => _displayImePolicy = v ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newDisplayController,
                decoration: const InputDecoration(
                  labelText: 'Novo display',
                  hintText: 'Ex: 1920x1080/420',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlSection() {
    return ExpansionTile(
      title: const Text('🎮 Controle'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                children: [
                  FilterChip(
                    label: const Text('Sempre no topo'),
                    selected: _alwaysOnTop,
                    onSelected: (v) => setState(() => _alwaysOnTop = v),
                  ),
                  FilterChip(
                    label: const Text('Tela cheia'),
                    selected: _fullscreen,
                    onSelected: (v) => setState(() => _fullscreen = v),
                  ),
                  FilterChip(
                    label: const Text('Mostrar toques'),
                    selected: _showTouches,
                    onSelected: (v) => setState(() => _showTouches = v),
                  ),
                  FilterChip(
                    label: const Text('Somente espelhar (sem controle)'),
                    selected: _noControl,
                    onSelected: (v) => setState(() => _noControl = v),
                  ),
                  FilterChip(
                    label: const Text('Manter acordado'),
                    selected: _stayAwake,
                    onSelected: (v) => setState(() => _stayAwake = v),
                  ),
                  FilterChip(
                    label: const Text('Desligar tela'),
                    selected: _turnScreenOff,
                    onSelected: (v) => setState(() => _turnScreenOff = v),
                  ),
                  FilterChip(
                    label: const Text('Desligar ao fechar'),
                    selected: _powerOffOnClose,
                    onSelected: (v) => setState(() => _powerOffOnClose = v),
                  ),
                  FilterChip(
                    label: const Text('Desabilitar screensaver'),
                    selected: _disableScreensaver,
                    onSelected: (v) => setState(() => _disableScreensaver = v),
                  ),
                  FilterChip(
                    label: const Text('Modo OTG'),
                    selected: _otg,
                    onSelected: (v) => setState(() => _otg = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _keyboard.isEmpty ? null : _keyboard,
                      decoration: const InputDecoration(
                        labelText: 'Teclado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Padrão')),
                        DropdownMenuItem(value: 'disabled', child: Text('Desabilitado')),
                        DropdownMenuItem(value: 'sdk', child: Text('SDK')),
                        DropdownMenuItem(value: 'uhid', child: Text('UHID')),
                        DropdownMenuItem(value: 'aoa', child: Text('AOA')),
                      ],
                      onChanged: (v) => setState(() => _keyboard = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _mouse.isEmpty ? null : _mouse,
                      decoration: const InputDecoration(
                        labelText: 'Mouse',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Padrão')),
                        DropdownMenuItem(value: 'disabled', child: Text('Desabilitado')),
                        DropdownMenuItem(value: 'sdk', child: Text('SDK')),
                        DropdownMenuItem(value: 'uhid', child: Text('UHID')),
                        DropdownMenuItem(value: 'aoa', child: Text('AOA')),
                      ],
                      onChanged: (v) => setState(() => _mouse = v ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gamepad.isEmpty ? null : _gamepad,
                      decoration: const InputDecoration(
                        labelText: 'Gamepad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Padrão')),
                        DropdownMenuItem(value: 'disabled', child: Text('Desabilitado')),
                        DropdownMenuItem(value: 'uhid', child: Text('UHID')),
                        DropdownMenuItem(value: 'aoa', child: Text('AOA')),
                      ],
                      onChanged: (v) => setState(() => _gamepad = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _mouseBindController,
                      decoration: const InputDecoration(
                        labelText: 'Mouse bind',
                        hintText: 'Ex: bhsn:++++',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('scrcpy Launcher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scrcpyPathController,
                decoration: const InputDecoration(
                  labelText: 'Caminho do scrcpy',
                  hintText: 'Ex: C:/scrcpy/scrcpy.exe',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Informe o caminho do scrcpy' : null,
              ),
              const SizedBox(height: 16),
              _buildVideoSection(),
              _buildAudioSection(),
              _buildDisplaySection(),
              _buildControlSection(),
              // Adicionar outras seções aqui (câmera, conexão, gravação, janela, avançadas)
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Gerar comando'),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _startScrcpy();
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Iniciar aplicação'),
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            _startScrcpy(execute: true);
          }
        },
      ),
    );
  }
}
