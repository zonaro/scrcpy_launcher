import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:innerlibs/innerlibs.dart';
import 'scrcpy_profile.dart';
import 'scrcpy_manager.dart';
import 'config_manager.dart';

class AdbDevice {
  final String serial;
  final String status;
  final String? model;
  final String? product;
  final String displayName;

  AdbDevice({
    required this.serial,
    required this.status,
    this.model,
    this.product,
    String? displayName,
  }) : displayName = displayName ?? _generateDisplayName(serial, model, product);

  static String _generateDisplayName(String serial, String? model, String? product) {
    if (model != null && model.isNotEmpty) {
      return '$model ($serial)';
    }
    if (product != null && product.isNotEmpty) {
      return '$product ($serial)';
    }
    return serial;
  }

  bool get isOnline => status == 'device';
  bool get isOffline => status == 'offline';
  bool get isUnauthorized => status == 'unauthorized';

  @override
  String toString() => displayName;
}

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystemApp;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
  });

  String get displayName => '$appName\n$packageName';

  @override
  String toString() => displayName;
}

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
  
  // Dispositivos ADB
  List<AdbDevice> _adbDevices = [];
  AdbDevice? _selectedDevice;
  bool _isLoadingDevices = false;
  
  // Aplicativos instalados
  List<InstalledApp> _installedApps = [];
  bool _isLoadingApps = false;
  
  // Status do scrcpy
  bool _isCheckingVersion = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _installedVersion;
  String? _latestVersion;
  bool _hasUpdate = false;
  
  // Vídeo
  final TextEditingController _videoBitrateController = TextEditingController(text: '8M');
  final TextEditingController _maxSizeController = TextEditingController();
  final TextEditingController _maxFpsController = TextEditingController();
  String _videoCodec = 'h264';
  final TextEditingController _videoEncoderController = TextEditingController();
  String _videoSource = 'display';
  final TextEditingController _videoBufferController = TextEditingController();
  final TextEditingController _angleController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  
  // Áudio
  final TextEditingController _audioBitrateController = TextEditingController(text: '128K');
  final TextEditingController _audioBufferController = TextEditingController();
  final TextEditingController _audioOutputBufferController = TextEditingController();
  String _audioCodec = 'opus';
  final TextEditingController _audioEncoderController = TextEditingController();
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
  String _cameraFacing = '';
  final TextEditingController _cameraFpsController = TextEditingController();
  bool _cameraHighSpeed = false;
  
  // Conexão
  final TextEditingController _serialController = TextEditingController();
  bool _selectUsb = false;
  bool _selectTcpip = false;
  final TextEditingController _tcpipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _tunnelHostController = TextEditingController();
  final TextEditingController _tunnelPortController = TextEditingController();
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
  
  // Avançado
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
  final TextEditingController _renderDriverController = TextEditingController();
  final TextEditingController _v4l2SinkController = TextEditingController();
  final TextEditingController _v4l2BufferController = TextEditingController();

  @override
  void dispose() {
    _scrcpyPathController.dispose();
    _profileNameController.dispose();
    
    // Vídeo
    _videoBitrateController.dispose();
    _maxSizeController.dispose();
    _maxFpsController.dispose();
    _videoEncoderController.dispose();
    _videoBufferController.dispose();
    _angleController.dispose();
    _cropController.dispose();
    
    // Áudio
    _audioBitrateController.dispose();
    _audioBufferController.dispose();
    _audioOutputBufferController.dispose();
    _audioEncoderController.dispose();
    
    // Display
    _displayOrientationController.dispose();
    _captureOrientationController.dispose();
    _recordOrientationController.dispose();
    _displayIdController.dispose();
    _newDisplayController.dispose();
    
    // Controle
    _mouseBindController.dispose();
    
    // Câmera
    _cameraIdController.dispose();
    _cameraSizeController.dispose();
    _cameraArController.dispose();
    _cameraFpsController.dispose();
    
    // Conexão
    _serialController.dispose();
    _tcpipController.dispose();
    _portController.dispose();
    _tunnelHostController.dispose();
    _tunnelPortController.dispose();
    
    // Gravação
    _recordController.dispose();
    _pushTargetController.dispose();
    
    // Janela
    _windowTitleController.dispose();
    _windowXController.dispose();
    _windowYController.dispose();
    _windowWidthController.dispose();
    _windowHeightController.dispose();
    
    // Avançado
    _timeLimitController.dispose();
    _screenOffTimeoutController.dispose();
    _shortcutModController.dispose();
    _startAppController.dispose();
    _renderDriverController.dispose();
    _v4l2SinkController.dispose();
    _v4l2BufferController.dispose();
    
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadLastConfig();
    _initializeScrcpy();
    _refreshAdbDevices();
  }

  Future<void> _initializeScrcpy() async {
    await _checkScrcpyInstallation();
  }

  Future<void> _refreshAdbDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      final devices = await _getAdbDevices();
      setState(() {
        _adbDevices = devices;
        // Se um dispositivo estava selecionado, tentar manter a seleção
        if (_selectedDevice != null) {
          final found = devices.where((d) => d.serial == _selectedDevice!.serial).firstOrNull;
          _selectedDevice = found;
        }
        // Se nenhum dispositivo selecionado e há dispositivos disponíveis, selecionar o primeiro online
        if (_selectedDevice == null && devices.isNotEmpty) {
          final onlineDevice = devices.where((d) => d.isOnline).firstOrNull;
          _selectedDevice = onlineDevice ?? devices.first;
        }
      });
      
      // Carregar apps do dispositivo selecionado
      _refreshInstalledApps();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dispositivos: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  Future<List<AdbDevice>> _getAdbDevices() async {
    final devices = <AdbDevice>[];
    
    try {
      // Procurar adb na mesma pasta do scrcpy
      String adbPath = 'adb';
      final scrcpyPath = _scrcpyPathController.text.trim();
      if (scrcpyPath.isNotEmpty) {
        final scrcpyDir = Directory(scrcpyPath).parent.path;
        final adbInScrcpyDir = '$scrcpyDir${Platform.pathSeparator}adb.exe';
        if (await File(adbInScrcpyDir).exists()) {
          adbPath = adbInScrcpyDir;
        }
      }

      // Executar adb devices -l
      final result = await Process.run(adbPath, ['devices', '-l']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty || trimmedLine.startsWith('List of devices')) {
            continue;
          }
          
          // Formato: serial status model:MODEL product:PRODUCT
          final parts = trimmedLine.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final serial = parts[0];
            final status = parts[1];
            
            String? model;
            String? product;
            
            // Extrair informações adicionais
            for (int i = 2; i < parts.length; i++) {
              final part = parts[i];
              if (part.startsWith('model:')) {
                model = part.substring(6);
              } else if (part.startsWith('product:')) {
                product = part.substring(8);
              }
            }
            
            devices.add(AdbDevice(
              serial: serial,
              status: status,
              model: model,
              product: product,
            ));
          }
        }
      }
    } catch (e) {
      // Se ADB não estiver disponível, retornar lista vazia
      print('Erro ao executar ADB: $e');
    }
    
    return devices;
  }

  Future<void> _refreshInstalledApps() async {
    if (_selectedDevice == null || !_selectedDevice!.isOnline) {
      setState(() {
        _installedApps = [];
      });
      return;
    }

    setState(() {
      _isLoadingApps = true;
    });

    try {
      final apps = await _getInstalledApps(_selectedDevice!.serial);
      setState(() {
        _installedApps = apps;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aplicativos: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingApps = false;
      });
    }
  }

  Future<List<InstalledApp>> _getInstalledApps(String deviceSerial) async {
    final apps = <InstalledApp>[];
    
    try {
      // Procurar adb na mesma pasta do scrcpy
      String adbPath = 'adb';
      final scrcpyPath = _scrcpyPathController.text.trim();
      if (scrcpyPath.isNotEmpty) {
        final scrcpyDir = Directory(scrcpyPath).parent.path;
        final adbInScrcpyDir = '$scrcpyDir${Platform.pathSeparator}adb.exe';
        if (await File(adbInScrcpyDir).exists()) {
          adbPath = adbInScrcpyDir;
        }
      }

      // Executar adb shell pm list packages -3 (apenas apps de terceiros)
      var result = await Process.run(adbPath, ['-s', deviceSerial, 'shell', 'pm', 'list', 'packages', '-3']);
      
      if (result.exitCode == 0) {
        final packages = result.stdout.toString().split('\n');
        
        // Buscar nomes dos aplicativos em lotes para melhorar performance
        for (final packageLine in packages) {
          final trimmed = packageLine.trim();
          if (trimmed.startsWith('package:')) {
            final packageName = trimmed.substring(8);
            if (packageName.isNotEmpty) {
              // Tentar obter o nome do aplicativo
              String appName = packageName;
              try {
                final labelResult = await Process.run(adbPath, [
                  '-s', deviceSerial, 'shell', 'pm', 'dump', packageName, '|', 'grep', '-A', '1', 'labelRes'
                ]);
                
                // Se falhar com grep, tentar método alternativo
                if (labelResult.exitCode != 0) {
                  final simpleResult = await Process.run(adbPath, [
                    '-s', deviceSerial, 'shell', 'pm', 'list', 'packages', '-f', packageName
                  ]);
                  
                  if (simpleResult.exitCode == 0) {
                    // Extrair nome mais legível se possível
                    final parts = packageName.split('.');
                    if (parts.length > 1) {
                      appName = parts.last.replaceAll('_', ' ').split(' ').map((word) => 
                        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
                      ).join(' ');
                    }
                  }
                }
              } catch (e) {
                // Se falhar, usar o nome do pacote como fallback
                print('Erro ao obter nome do app $packageName: $e');
              }
              
              apps.add(InstalledApp(
                packageName: packageName,
                appName: appName,
                isSystemApp: false,
              ));
            }
          }
        }
      }
      
      // Adicionar alguns apps do sistema comuns
      final systemApps = [
        InstalledApp(packageName: 'com.android.settings', appName: 'Settings', isSystemApp: true),
        InstalledApp(packageName: 'com.android.chrome', appName: 'Chrome', isSystemApp: true),
        InstalledApp(packageName: 'com.google.android.gms', appName: 'Google Play Services', isSystemApp: true),
        InstalledApp(packageName: 'com.android.vending', appName: 'Play Store', isSystemApp: true),
        InstalledApp(packageName: 'com.android.camera2', appName: 'Camera', isSystemApp: true),
        InstalledApp(packageName: 'com.android.gallery3d', appName: 'Gallery', isSystemApp: true),
      ];
      
      apps.addAll(systemApps);
      
      // Ordenar por nome do app
      apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      
    } catch (e) {
      print('Erro ao executar ADB para listar apps: $e');
    }
    
    return apps;
  }

  Future<void> _checkScrcpyInstallation() async {
    setState(() {
      _isCheckingVersion = true;
    });

    try {
      // Primeiro, verificar no diretório da aplicação
      final defaultPath = await ScrcpyManager.getDefaultInstallPath();
      if (await ScrcpyManager.isScrcpyInstalled(defaultPath)) {
        _scrcpyPathController.text = defaultPath;
        await ScrcpyManager.setInstallPath(defaultPath);
      } else {
        // Se não encontrar na aplicação, verificar se já existe um caminho salvo
        String? savedPath = await ScrcpyManager.getInstallPath();
        if (savedPath != null && savedPath.isNotEmpty && await ScrcpyManager.isScrcpyInstalled(savedPath)) {
          _scrcpyPathController.text = savedPath;
        } else {
          // Auto-detectar instalações existentes no sistema
          final existingPaths = await ScrcpyManager.findExistingInstallations();
          if (existingPaths.isNotEmpty) {
            _scrcpyPathController.text = existingPaths.first;
            await ScrcpyManager.setInstallPath(existingPaths.first);
          }
        }
      }

      // Verificar versão instalada
      if (_scrcpyPathController.text.isNotEmpty) {
        _installedVersion = await ScrcpyManager.getScrcpyVersion(_scrcpyPathController.text);
      }

      // Verificar última versão disponível
      final latestRelease = await ScrcpyManager.getLatestRelease();
      if (latestRelease != null) {
        _latestVersion = latestRelease.version;
        
        if (_installedVersion != null) {
          _hasUpdate = await ScrcpyManager.hasNewVersionAvailable();
        } else {
          _hasUpdate = true; // Se não há versão instalada, considerar que há update
        }
      }

      // Se não há scrcpy instalado, sugerir download
      if (_scrcpyPathController.text.isEmpty || _installedVersion == null) {
        if (mounted) {
          _showDownloadDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar scrcpy: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVersion = false;
        });
      }
    }
  }

  Future<void> _downloadScrcpy() async {
    try {
      final latestRelease = await ScrcpyManager.getLatestRelease();
      if (latestRelease == null) {
        throw Exception('Nenhuma versão encontrada');
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final scrcpyPath = await ScrcpyManager.downloadRelease(
        latestRelease,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      _scrcpyPathController.text = scrcpyPath;
      _installedVersion = latestRelease.version;
      _hasUpdate = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('scrcpy ${latestRelease.version} baixado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar scrcpy: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('scrcpy não encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O scrcpy não foi encontrado em seu sistema.'),
            const SizedBox(height: 16),
            const Text('O scrcpy será baixado e instalado automaticamente na pasta da aplicação.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadScrcpy();
            },
            child: const Text('Baixar scrcpy'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualização disponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versão instalada: $_installedVersion'),
            Text('Versão disponível: $_latestVersion'),
            const SizedBox(height: 16),
            const Text('Deseja atualizar o scrcpy?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadScrcpy();
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfiles() async {
    final profiles = await ConfigManager.loadProfiles();
    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _saveProfiles() async {
    await ConfigManager.saveProfiles(_profiles);
  }

  Future<void> _loadLastConfig() async {
    final config = await ConfigManager.loadMainConfig();
    
    // Configurações básicas
    _scrcpyPathController.text = config['scrcpyPath'] ?? '';
    
    // Vídeo
    _videoBitrateController.text = config['videoBitrate'] ?? '8M';
    _maxSizeController.text = config['maxSize'] ?? '';
    _maxFpsController.text = config['maxFps'] ?? '';
    _videoCodec = config['videoCodec'] ?? 'h264';
    _videoEncoderController.text = config['videoEncoder'] ?? '';
    _videoSource = config['videoSource'] ?? 'display';
    _videoBufferController.text = config['videoBuffer'] ?? '';
    _angleController.text = config['angle'] ?? '';
    _cropController.text = config['crop'] ?? '';
    
    // Áudio
    _audioBitrateController.text = config['audioBitrate'] ?? '128K';
    _audioBufferController.text = config['audioBuffer'] ?? '';
    _audioOutputBufferController.text = config['audioOutputBuffer'] ?? '';
    _audioCodec = config['audioCodec'] ?? 'opus';
    _audioEncoderController.text = config['audioEncoder'] ?? '';
    _audioSource = config['audioSource'] ?? 'output';
    _audioDup = config['audioDup'] ?? false;
    _noAudio = config['noAudio'] ?? false;
    _noAudioPlayback = config['noAudioPlayback'] ?? false;
    _requireAudio = config['requireAudio'] ?? false;
    
    // Display
    _orientation = config['orientation'] ?? '0';
    _displayOrientationController.text = config['displayOrientation'] ?? '';
    _captureOrientationController.text = config['captureOrientation'] ?? '';
    _recordOrientationController.text = config['recordOrientation'] ?? '';
    _displayIdController.text = config['displayId'] ?? '';
    _displayImePolicy = config['displayImePolicy'] ?? '';
    _newDisplayController.text = config['newDisplay'] ?? '';
    
    setState(() {
      // Controle
      _alwaysOnTop = config['alwaysOnTop'] ?? false;
      _fullscreen = config['fullscreen'] ?? false;
      _showTouches = config['showTouches'] ?? false;
      _noControl = config['noControl'] ?? false;
      _stayAwake = config['stayAwake'] ?? false;
      _turnScreenOff = config['turnScreenOff'] ?? false;
      _powerOffOnClose = config['powerOffOnClose'] ?? false;
      _disableScreensaver = config['disableScreensaver'] ?? false;
      _keyboard = config['keyboard'] ?? '';
      _mouse = config['mouse'] ?? '';
      _gamepad = config['gamepad'] ?? '';
      _otg = config['otg'] ?? false;
      
      // Câmera
      _cameraFacing = config['cameraFacing'] ?? '';
      _cameraHighSpeed = config['cameraHighSpeed'] ?? false;
      
      // Conexão
      _selectUsb = config['selectUsb'] ?? false;
      _selectTcpip = config['selectTcpip'] ?? false;
      _forceAdbForward = config['forceAdbForward'] ?? false;
      _killAdbOnClose = config['killAdbOnClose'] ?? false;
      
      // Gravação
      _recordFormat = config['recordFormat'] ?? '';
      
      // Janela
      _windowBorderless = config['windowBorderless'] ?? false;
      
      // Avançado
      _noPlayback = config['noPlayback'] ?? false;
      _noVideoPlayback = config['noVideoPlayback'] ?? false;
      _noVideo = config['noVideo'] ?? false;
      _noWindow = config['noWindow'] ?? false;
      _noCleanup = config['noCleanup'] ?? false;
      _noClipboardAutosync = config['noClipboardAutosync'] ?? false;
      _noDownsizeOnError = config['noDownsizeOnError'] ?? false;
      _noKeyRepeat = config['noKeyRepeat'] ?? false;
      _noMipmaps = config['noMipmaps'] ?? false;
      _noMouseHover = config['noMouseHover'] ?? false;
      _noPowerOn = config['noPowerOn'] ?? false;
      _noVdDestroyContent = config['noVdDestroyContent'] ?? false;
      _noVdSystemDecorations = config['noVdSystemDecorations'] ?? false;
      _legacyPaste = config['legacyPaste'] ?? false;
      _preferText = config['preferText'] ?? false;
      _rawKeyEvents = config['rawKeyEvents'] ?? false;
      _printFps = config['printFps'] ?? false;
      _pauseOnExit = config['pauseOnExit'] ?? '';
      _verbosity = config['verbosity'] ?? '';
    });
    
    // Controladores de texto restantes
    _mouseBindController.text = config['mouseBind'] ?? '';
    _cameraIdController.text = config['cameraId'] ?? '';
    _cameraSizeController.text = config['cameraSize'] ?? '';
    _cameraArController.text = config['cameraAr'] ?? '';
    _cameraFpsController.text = config['cameraFps'] ?? '';
    _serialController.text = config['serial'] ?? '';
    _tcpipController.text = config['tcpip'] ?? '';
    _portController.text = config['port'] ?? '';
    _tunnelHostController.text = config['tunnelHost'] ?? '';
    _tunnelPortController.text = config['tunnelPort'] ?? '';
    _recordController.text = config['record'] ?? '';
    _pushTargetController.text = config['pushTarget'] ?? '';
    _windowTitleController.text = config['windowTitle'] ?? '';
    _windowXController.text = config['windowX'] ?? '';
    _windowYController.text = config['windowY'] ?? '';
    _windowWidthController.text = config['windowWidth'] ?? '';
    _windowHeightController.text = config['windowHeight'] ?? '';
    _timeLimitController.text = config['timeLimit'] ?? '';
    _screenOffTimeoutController.text = config['screenOffTimeout'] ?? '';
    _shortcutModController.text = config['shortcutMod'] ?? '';
    _startAppController.text = config['startApp'] ?? '';
    _renderDriverController.text = config['renderDriver'] ?? '';
    _v4l2SinkController.text = config['v4l2Sink'] ?? '';
    _v4l2BufferController.text = config['v4l2Buffer'] ?? '';
  }

  Future<void> _saveLastConfig() async {
    final config = {
      // Configurações básicas
      'scrcpyPath': _scrcpyPathController.text,
      
      // Vídeo
      'videoBitrate': _videoBitrateController.text,
      'maxSize': _maxSizeController.text,
      'maxFps': _maxFpsController.text,
      'videoCodec': _videoCodec,
      'videoEncoder': _videoEncoderController.text,
      'videoSource': _videoSource,
      'videoBuffer': _videoBufferController.text,
      'angle': _angleController.text,
      'crop': _cropController.text,
      
      // Áudio
      'audioBitrate': _audioBitrateController.text,
      'audioBuffer': _audioBufferController.text,
      'audioOutputBuffer': _audioOutputBufferController.text,
      'audioCodec': _audioCodec,
      'audioEncoder': _audioEncoderController.text,
      'audioSource': _audioSource,
      'audioDup': _audioDup,
      'noAudio': _noAudio,
      'noAudioPlayback': _noAudioPlayback,
      'requireAudio': _requireAudio,
      
      // Display
      'orientation': _orientation,
      'displayOrientation': _displayOrientationController.text,
      'captureOrientation': _captureOrientationController.text,
      'recordOrientation': _recordOrientationController.text,
      'displayId': _displayIdController.text,
      'displayImePolicy': _displayImePolicy,
      'newDisplay': _newDisplayController.text,
      
      // Controle
      'alwaysOnTop': _alwaysOnTop,
      'fullscreen': _fullscreen,
      'showTouches': _showTouches,
      'noControl': _noControl,
      'stayAwake': _stayAwake,
      'turnScreenOff': _turnScreenOff,
      'powerOffOnClose': _powerOffOnClose,
      'disableScreensaver': _disableScreensaver,
      'keyboard': _keyboard,
      'mouse': _mouse,
      'gamepad': _gamepad,
      'mouseBind': _mouseBindController.text,
      'otg': _otg,
      
      // Câmera
      'cameraId': _cameraIdController.text,
      'cameraSize': _cameraSizeController.text,
      'cameraAr': _cameraArController.text,
      'cameraFacing': _cameraFacing,
      'cameraFps': _cameraFpsController.text,
      'cameraHighSpeed': _cameraHighSpeed,
      
      // Conexão
      'serial': _serialController.text,
      'selectUsb': _selectUsb,
      'selectTcpip': _selectTcpip,
      'tcpip': _tcpipController.text,
      'port': _portController.text,
      'tunnelHost': _tunnelHostController.text,
      'tunnelPort': _tunnelPortController.text,
      'forceAdbForward': _forceAdbForward,
      'killAdbOnClose': _killAdbOnClose,
      
      // Gravação
      'record': _recordController.text,
      'recordFormat': _recordFormat,
      'pushTarget': _pushTargetController.text,
      
      // Janela
      'windowBorderless': _windowBorderless,
      'windowTitle': _windowTitleController.text,
      'windowX': _windowXController.text,
      'windowY': _windowYController.text,
      'windowWidth': _windowWidthController.text,
      'windowHeight': _windowHeightController.text,
      
      // Avançado
      'noPlayback': _noPlayback,
      'noVideoPlayback': _noVideoPlayback,
      'noVideo': _noVideo,
      'noWindow': _noWindow,
      'noCleanup': _noCleanup,
      'noClipboardAutosync': _noClipboardAutosync,
      'noDownsizeOnError': _noDownsizeOnError,
      'noKeyRepeat': _noKeyRepeat,
      'noMipmaps': _noMipmaps,
      'noMouseHover': _noMouseHover,
      'noPowerOn': _noPowerOn,
      'noVdDestroyContent': _noVdDestroyContent,
      'noVdSystemDecorations': _noVdSystemDecorations,
      'legacyPaste': _legacyPaste,
      'preferText': _preferText,
      'rawKeyEvents': _rawKeyEvents,
      'printFps': _printFps,
      'pauseOnExit': _pauseOnExit,
      'timeLimit': _timeLimitController.text,
      'screenOffTimeout': _screenOffTimeoutController.text,
      'shortcutMod': _shortcutModController.text,
      'startApp': _startAppController.text,
      'verbosity': _verbosity,
      'renderDriver': _renderDriverController.text,
      'v4l2Sink': _v4l2SinkController.text,
      'v4l2Buffer': _v4l2BufferController.text,
      
      // Informações do scrcpy
      'scrcpy_installed_version': _installedVersion ?? '',
      'scrcpy_install_path': _scrcpyPathController.text,
    };
    await ConfigManager.saveMainConfig(config);
  }

  ScrcpyProfile _getCurrentProfile(String name) {
    return ScrcpyProfile(
      name: name,
      scrcpyPath: _scrcpyPathController.text,
      
      // Vídeo
      videoBitrate: _videoBitrateController.text,
      maxSize: _maxSizeController.text,
      maxFps: _maxFpsController.text,
      videoCodec: _videoCodec,
      videoEncoder: _videoEncoderController.text,
      videoSource: _videoSource,
      videoBuffer: _videoBufferController.text,
      angle: _angleController.text,
      crop: _cropController.text,
      
      // Áudio
      audioBitrate: _audioBitrateController.text,
      audioBuffer: _audioBufferController.text,
      audioOutputBuffer: _audioOutputBufferController.text,
      audioCodec: _audioCodec,
      audioEncoder: _audioEncoderController.text,
      audioSource: _audioSource,
      audioDup: _audioDup,
      noAudio: _noAudio,
      noAudioPlayback: _noAudioPlayback,
      requireAudio: _requireAudio,
      
      // Display
      orientation: _orientation,
      displayOrientation: _displayOrientationController.text,
      captureOrientation: _captureOrientationController.text,
      recordOrientation: _recordOrientationController.text,
      displayId: _displayIdController.text,
      displayImePolicy: _displayImePolicy,
      newDisplay: _newDisplayController.text,
      
      // Controle
      alwaysOnTop: _alwaysOnTop,
      fullscreen: _fullscreen,
      showTouches: _showTouches,
      noControl: _noControl,
      stayAwake: _stayAwake,
      turnScreenOff: _turnScreenOff,
      powerOffOnClose: _powerOffOnClose,
      disableScreensaver: _disableScreensaver,
      keyboard: _keyboard,
      mouse: _mouse,
      gamepad: _gamepad,
      mouseBind: _mouseBindController.text,
      otg: _otg,
      
      // Câmera
      cameraId: _cameraIdController.text,
      cameraSize: _cameraSizeController.text,
      cameraAr: _cameraArController.text,
      cameraFacing: _cameraFacing,
      cameraFps: _cameraFpsController.text,
      cameraHighSpeed: _cameraHighSpeed,
      
      // Conexão
      serial: _serialController.text,
      selectUsb: _selectUsb,
      selectTcpip: _selectTcpip,
      tcpip: _tcpipController.text,
      port: _portController.text,
      tunnelHost: _tunnelHostController.text,
      tunnelPort: _tunnelPortController.text,
      forceAdbForward: _forceAdbForward,
      killAdbOnClose: _killAdbOnClose,
      
      // Gravação
      record: _recordController.text,
      recordFormat: _recordFormat,
      pushTarget: _pushTargetController.text,
      
      // Janela
      windowBorderless: _windowBorderless,
      windowTitle: _windowTitleController.text,
      windowX: _windowXController.text,
      windowY: _windowYController.text,
      windowWidth: _windowWidthController.text,
      windowHeight: _windowHeightController.text,
      
      // Avançado
      noPlayback: _noPlayback,
      noVideoPlayback: _noVideoPlayback,
      noVideo: _noVideo,
      noWindow: _noWindow,
      noCleanup: _noCleanup,
      noClipboardAutosync: _noClipboardAutosync,
      noDownsizeOnError: _noDownsizeOnError,
      noKeyRepeat: _noKeyRepeat,
      noMipmaps: _noMipmaps,
      noMouseHover: _noMouseHover,
      noPowerOn: _noPowerOn,
      noVdDestroyContent: _noVdDestroyContent,
      noVdSystemDecorations: _noVdSystemDecorations,
      legacyPaste: _legacyPaste,
      preferText: _preferText,
      rawKeyEvents: _rawKeyEvents,
      printFps: _printFps,
      pauseOnExit: _pauseOnExit,
      timeLimit: _timeLimitController.text,
      screenOffTimeout: _screenOffTimeoutController.text,
      shortcutMod: _shortcutModController.text,
      startApp: _startAppController.text,
      verbosity: _verbosity,
      renderDriver: _renderDriverController.text,
      v4l2Sink: _v4l2SinkController.text,
      v4l2Buffer: _v4l2BufferController.text,
    );
  }

  void _fillFromProfile(ScrcpyProfile profile) {
    _scrcpyPathController.text = profile.scrcpyPath;
    
    // Vídeo
    _videoBitrateController.text = profile.videoBitrate;
    _maxSizeController.text = profile.maxSize;
    _maxFpsController.text = profile.maxFps;
    _videoCodec = profile.videoCodec;
    _videoEncoderController.text = profile.videoEncoder;
    _videoSource = profile.videoSource;
    _videoBufferController.text = profile.videoBuffer;
    _angleController.text = profile.angle;
    _cropController.text = profile.crop;
    
    // Áudio
    _audioBitrateController.text = profile.audioBitrate;
    _audioBufferController.text = profile.audioBuffer;
    _audioOutputBufferController.text = profile.audioOutputBuffer;
    _audioCodec = profile.audioCodec;
    _audioEncoderController.text = profile.audioEncoder;
    _audioSource = profile.audioSource;
    _audioDup = profile.audioDup;
    _noAudio = profile.noAudio;
    _noAudioPlayback = profile.noAudioPlayback;
    _requireAudio = profile.requireAudio;
    
    // Display
    _orientation = profile.orientation;
    _displayOrientationController.text = profile.displayOrientation;
    _captureOrientationController.text = profile.captureOrientation;
    _recordOrientationController.text = profile.recordOrientation;
    _displayIdController.text = profile.displayId;
    _displayImePolicy = profile.displayImePolicy;
    _newDisplayController.text = profile.newDisplay;
    
    // Controle
    _alwaysOnTop = profile.alwaysOnTop;
    _fullscreen = profile.fullscreen;
    _showTouches = profile.showTouches;
    _noControl = profile.noControl;
    _stayAwake = profile.stayAwake;
    _turnScreenOff = profile.turnScreenOff;
    _powerOffOnClose = profile.powerOffOnClose;
    _disableScreensaver = profile.disableScreensaver;
    _keyboard = profile.keyboard;
    _mouse = profile.mouse;
    _gamepad = profile.gamepad;
    _mouseBindController.text = profile.mouseBind;
    _otg = profile.otg;
    
    // Câmera
    _cameraIdController.text = profile.cameraId;
    _cameraSizeController.text = profile.cameraSize;
    _cameraArController.text = profile.cameraAr;
    _cameraFacing = profile.cameraFacing;
    _cameraFpsController.text = profile.cameraFps;
    _cameraHighSpeed = profile.cameraHighSpeed;
    
    // Conexão
    _serialController.text = profile.serial;
    _selectUsb = profile.selectUsb;
    _selectTcpip = profile.selectTcpip;
    _tcpipController.text = profile.tcpip;
    _portController.text = profile.port;
    _tunnelHostController.text = profile.tunnelHost;
    _tunnelPortController.text = profile.tunnelPort;
    _forceAdbForward = profile.forceAdbForward;
    _killAdbOnClose = profile.killAdbOnClose;
    
    // Gravação
    _recordController.text = profile.record;
    _recordFormat = profile.recordFormat;
    _pushTargetController.text = profile.pushTarget;
    
    // Janela
    _windowBorderless = profile.windowBorderless;
    _windowTitleController.text = profile.windowTitle;
    _windowXController.text = profile.windowX;
    _windowYController.text = profile.windowY;
    _windowWidthController.text = profile.windowWidth;
    _windowHeightController.text = profile.windowHeight;
    
    // Avançado
    _noPlayback = profile.noPlayback;
    _noVideoPlayback = profile.noVideoPlayback;
    _noVideo = profile.noVideo;
    _noWindow = profile.noWindow;
    _noCleanup = profile.noCleanup;
    _noClipboardAutosync = profile.noClipboardAutosync;
    _noDownsizeOnError = profile.noDownsizeOnError;
    _noKeyRepeat = profile.noKeyRepeat;
    _noMipmaps = profile.noMipmaps;
    _noMouseHover = profile.noMouseHover;
    _noPowerOn = profile.noPowerOn;
    _noVdDestroyContent = profile.noVdDestroyContent;
    _noVdSystemDecorations = profile.noVdSystemDecorations;
    _legacyPaste = profile.legacyPaste;
    _preferText = profile.preferText;
    _rawKeyEvents = profile.rawKeyEvents;
    _printFps = profile.printFps;
    _pauseOnExit = profile.pauseOnExit;
    _timeLimitController.text = profile.timeLimit;
    _screenOffTimeoutController.text = profile.screenOffTimeout;
    _shortcutModController.text = profile.shortcutMod;
    _startAppController.text = profile.startApp;
    _verbosity = profile.verbosity;
    _renderDriverController.text = profile.renderDriver;
    _v4l2SinkController.text = profile.v4l2Sink;
    _v4l2BufferController.text = profile.v4l2Buffer;
    
    setState(() {});
  }

  Future<void> _saveCurrentAsProfile() async {
    final name = _profileNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o perfil!')),
      );
      return;
    }
    final profile = _getCurrentProfile(name);
    setState(() {
      _profiles.removeWhere((p) => p.name == name);
      _profiles.add(profile);
      _selectedProfile = profile;
    });
    await _saveProfiles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo!')),
    );
  }

  Future<void> _deleteProfile(ScrcpyProfile profile) async {
    setState(() {
      _profiles.removeWhere((p) => p.name == profile.name);
      if (_selectedProfile?.name == profile.name) {
        _selectedProfile = null;
      }
    });
    await _saveProfiles();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil excluído!')),
    );
  }

  Future<void> _startScrcpy({bool execute = false}) async {
    await _saveLastConfig();
    final path = _scrcpyPathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('scrcpy não encontrado! Faça o download primeiro.')),
      );
      return;
    }
    
    final args = <String>[];
    
    // Dispositivo selecionado
    if (_selectedDevice != null) {
      args.add('--serial=${_selectedDevice!.serial}');
    } else if (_serialController.text.isNotEmpty) {
      args.add('--serial=${_serialController.text}');
    }
    
    // Vídeo
    if (_videoBitrateController.text.isNotEmpty) {
      args.add('--video-bit-rate=${_videoBitrateController.text}');
    }
    if (_maxSizeController.text.isNotEmpty) {
      args.add('--max-size=${_maxSizeController.text}');
    }
    if (_maxFpsController.text.isNotEmpty) {
      args.add('--max-fps=${_maxFpsController.text}');
    }
    if (_videoCodec != 'h264' && _videoCodec.isNotEmpty) {
      args.add('--video-codec=$_videoCodec');
    }
    if (_videoEncoderController.text.isNotEmpty) {
      args.add('--video-encoder=${_videoEncoderController.text}');
    }
    if (_videoSource != 'display') {
      args.add('--video-source=$_videoSource');
    }
    if (_videoBufferController.text.isNotEmpty) {
      args.add('--video-buffer=${_videoBufferController.text}');
    }
    if (_angleController.text.isNotEmpty) {
      args.add('--angle=${_angleController.text}');
    }
    if (_cropController.text.isNotEmpty) {
      args.add('--crop=${_cropController.text}');
    }
    
    // Áudio
    if (!_noAudio) {
      if (_audioBitrateController.text.isNotEmpty && _audioBitrateController.text != '128K') {
        args.add('--audio-bit-rate=${_audioBitrateController.text}');
      }
      if (_audioBufferController.text.isNotEmpty) {
        args.add('--audio-buffer=${_audioBufferController.text}');
      }
      if (_audioOutputBufferController.text.isNotEmpty) {
        args.add('--audio-output-buffer=${_audioOutputBufferController.text}');
      }
      if (_audioCodec != 'opus' && _audioCodec.isNotEmpty) {
        args.add('--audio-codec=$_audioCodec');
      }
      if (_audioEncoderController.text.isNotEmpty) {
        args.add('--audio-encoder=${_audioEncoderController.text}');
      }
      if (_audioSource != 'output') {
        args.add('--audio-source=$_audioSource');
      }
      if (_audioDup) args.add('--audio-dup');
      if (_requireAudio) args.add('--require-audio');
    }
    if (_noAudio) args.add('--no-audio');
    if (_noAudioPlayback) args.add('--no-audio-playback');
    
    // Display
    if (_orientation != '0') args.add('--orientation=$_orientation');
    if (_displayOrientationController.text.isNotEmpty) {
      args.add('--display-orientation=${_displayOrientationController.text}');
    }
    if (_captureOrientationController.text.isNotEmpty) {
      args.add('--capture-orientation=${_captureOrientationController.text}');
    }
    if (_recordOrientationController.text.isNotEmpty) {
      args.add('--record-orientation=${_recordOrientationController.text}');
    }
    if (_displayIdController.text.isNotEmpty) {
      args.add('--display-id=${_displayIdController.text}');
    }
    if (_displayImePolicy.isNotEmpty) {
      args.add('--display-ime-policy=$_displayImePolicy');
    }
    if (_newDisplayController.text.isNotEmpty) {
      args.add('--new-display=${_newDisplayController.text}');
    }
    
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
    if (_mouseBindController.text.isNotEmpty) {
      args.add('--mouse-bind=${_mouseBindController.text}');
    }
    if (_otg) args.add('--otg');
    
    // Câmera
    if (_videoSource == 'camera') {
      if (_cameraIdController.text.isNotEmpty) {
        args.add('--camera-id=${_cameraIdController.text}');
      }
      if (_cameraSizeController.text.isNotEmpty) {
        args.add('--camera-size=${_cameraSizeController.text}');
      }
      if (_cameraArController.text.isNotEmpty) {
        args.add('--camera-ar=${_cameraArController.text}');
      }
      if (_cameraFacing.isNotEmpty) {
        args.add('--camera-facing=$_cameraFacing');
      }
      if (_cameraFpsController.text.isNotEmpty) {
        args.add('--camera-fps=${_cameraFpsController.text}');
      }
      if (_cameraHighSpeed) args.add('--camera-high-speed');
    }
    
    // Conexão
    if (_serialController.text.isNotEmpty) {
      args.add('--serial=${_serialController.text}');
    }
    if (_selectUsb) args.add('--select-usb');
    if (_selectTcpip) args.add('--select-tcpip');
    if (_tcpipController.text.isNotEmpty) {
      args.add('--tcpip=${_tcpipController.text}');
    }
    if (_portController.text.isNotEmpty) {
      args.add('--port=${_portController.text}');
    }
    if (_tunnelHostController.text.isNotEmpty) {
      args.add('--tunnel-host=${_tunnelHostController.text}');
    }
    if (_tunnelPortController.text.isNotEmpty) {
      args.add('--tunnel-port=${_tunnelPortController.text}');
    }
    if (_forceAdbForward) args.add('--force-adb-forward');
    if (_killAdbOnClose) args.add('--kill-adb-on-close');
    
    // Gravação
    if (_recordController.text.isNotEmpty) {
      args.add('--record=${_recordController.text}');
    }
    if (_recordFormat.isNotEmpty) {
      args.add('--record-format=$_recordFormat');
    }
    if (_pushTargetController.text.isNotEmpty) {
      args.add('--push-target=${_pushTargetController.text}');
    }
    
    // Janela
    if (_windowBorderless) args.add('--window-borderless');
    if (_windowTitleController.text.isNotEmpty) {
      args.add('--window-title="${_windowTitleController.text}"');
    }
    if (_windowXController.text.isNotEmpty) {
      args.add('--window-x=${_windowXController.text}');
    }
    if (_windowYController.text.isNotEmpty) {
      args.add('--window-y=${_windowYController.text}');
    }
    if (_windowWidthController.text.isNotEmpty) {
      args.add('--window-width=${_windowWidthController.text}');
    }
    if (_windowHeightController.text.isNotEmpty) {
      args.add('--window-height=${_windowHeightController.text}');
    }
    
    // Avançado
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
    if (_pauseOnExit.isNotEmpty) {
      args.add('--pause-on-exit=$_pauseOnExit');
    }
    if (_timeLimitController.text.isNotEmpty) {
      args.add('--time-limit=${_timeLimitController.text}');
    }
    if (_screenOffTimeoutController.text.isNotEmpty) {
      args.add('--screen-off-timeout=${_screenOffTimeoutController.text}');
    }
    if (_shortcutModController.text.isNotEmpty) {
      args.add('--shortcut-mod=${_shortcutModController.text}');
    }
    if (_startAppController.text.isNotEmpty) {
      args.add('--start-app=${_startAppController.text}');
    }
    if (_verbosity.isNotEmpty) {
      args.add('--verbosity=$_verbosity');
    }
    if (_renderDriverController.text.isNotEmpty) {
      args.add('--render-driver=${_renderDriverController.text}');
    }
    if (_v4l2SinkController.text.isNotEmpty) {
      args.add('--v4l2-sink=${_v4l2SinkController.text}');
    }
    if (_v4l2BufferController.text.isNotEmpty) {
      args.add('--v4l2-buffer=${_v4l2BufferController.text}');
    }

    final command = '"$path" ${args.join(' ')}';

    if (execute) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iniciando scrcpy...')),
        );
        
        if (Platform.isWindows) {
          // No Windows, usar PowerShell para iniciar o processo sem mostrar janela
          final psCommand = '''
Start-Process -FilePath "$path" -ArgumentList "${args.map((arg) => arg.contains(' ') ? '"$arg"' : arg).join('", "')}" -WindowStyle Hidden
''';
          
          await Process.start(
            'powershell',
            ['-WindowStyle', 'Hidden', '-Command', psCommand],
            mode: ProcessStartMode.detached,
            runInShell: false,
          );
        } else {
          // Em outros sistemas, usar o modo detached normal
          await Process.start(path, args, mode: ProcessStartMode.detached);
        }
      } catch (e) {
        // Se falhar com PowerShell, tentar método alternativo
        try {
          if (Platform.isWindows) {
            await Process.start(
              'cmd',
              ['/c', 'start', '/min', '"scrcpy"', path, ...args],
              mode: ProcessStartMode.detached,
              runInShell: false,
            );
          } else {
            await Process.start(path, args, mode: ProcessStartMode.detached);
          }
        } catch (e2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao iniciar scrcpy: $e2')),
          );
        }
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

  Widget _buildDeviceDropdown() {
    return DropdownButtonFormField<AdbDevice?>(
      value: _selectedDevice,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Dispositivo',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(
          _selectedDevice?.isOnline == true 
            ? Icons.smartphone 
            : _selectedDevice?.isUnauthorized == true
              ? Icons.lock
              : Icons.smartphone_outlined,
          color: _selectedDevice?.isOnline == true 
            ? Colors.green 
            : _selectedDevice?.isUnauthorized == true
              ? Colors.orange
              : Colors.grey,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        if (_adbDevices.isEmpty && !_isLoadingDevices)
          const DropdownMenuItem<AdbDevice?>(
            value: null,
            child: Text(
              'Nenhum dispositivo encontrado',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ..._adbDevices.map((device) => DropdownMenuItem(
          value: device,
          child: Row(
            children: [
              Icon(
                device.isOnline 
                  ? Icons.circle 
                  : device.isUnauthorized
                    ? Icons.warning
                    : Icons.circle_outlined,
                size: 12,
                color: device.isOnline 
                  ? Colors.green 
                  : device.isUnauthorized
                    ? Colors.orange
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!device.isOnline)
                Text(
                  ' (${device.status})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        )),
      ],
      onChanged: (device) {
        setState(() {
          _selectedDevice = device;
          // Atualizar o campo serial se um dispositivo foi selecionado
          if (device != null) {
            _serialController.text = device.serial;
          }
        });
        // Carregar apps do novo dispositivo selecionado
        _refreshInstalledApps();
      },
    );
  }

  Widget _buildScrcpyStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                const Text(
                  'Status do scrcpy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_hasUpdate)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.system_update),
                    label: const Text('Atualizar'),
                    onPressed: _isDownloading ? null : _showUpdateDialog,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isCheckingVersion)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Verificando versão...'),
                ],
              )
            else if (_isDownloading)
              Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Baixando scrcpy... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_installedVersion != null) ...[
                    Text('Versão instalada: $_installedVersion'),
                    Text('Local: ${_scrcpyPathController.text}'),
                    if (_latestVersion != null)
                      Text('Última versão: $_latestVersion'),
                    if (_hasUpdate)
                      const Text(
                        'Nova versão disponível!',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'scrcpy está atualizado',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ] else ...[
                    const Text(
                      'scrcpy não encontrado',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Será instalado na pasta da aplicação'),
                    if (_latestVersion != null)
                      Text('Última versão disponível: $_latestVersion'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Verificar atualizações'),
                        onPressed: _isCheckingVersion || _isDownloading
                            ? null
                            : _checkScrcpyInstallation,
                      ),
                      const SizedBox(width: 8),
                      if (_installedVersion == null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Baixar scrcpy'),
                          onPressed: _isDownloading ? null : _downloadScrcpy,
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return ResponsiveRow(
      horizontalSpacing: 8,
      runSpacing: 8,
      children: [
        ResponsiveColumn(
          xxs: 12,
          sm: 6,
          md: 4,
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
        ResponsiveColumn(
          xxs: 12,
          sm: 6,
          md: 4,
          child: TextFormField(
            controller: _profileNameController,
            decoration: const InputDecoration(
              labelText: 'Nome do perfil',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ResponsiveColumn(
          xxs: 12,
          sm: 12,
          md: 4,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveCurrentAsProfile,
              child: const Text('Salvar como perfil'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Vídeo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _videoBitrateController,
                    decoration: const InputDecoration(
                      labelText: 'Bitrate do vídeo',
                      hintText: 'Ex: 8M',
                      border: OutlineInputBorder(),
                      helperText: 'Taxa de bits do vídeo (padrão: 8M)',
                    ),
                    onTap: () => _showTooltip(context, 'Define a taxa de bits do vídeo. Valores maiores melhoram a qualidade mas aumentam o uso de rede. Ex: 2M, 8M, 15M'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _maxSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Tamanho máximo (px)',
                      hintText: 'Ex: 1024',
                      border: OutlineInputBorder(),
                      helperText: 'Largura máxima em pixels',
                    ),
                    onTap: () => _showTooltip(context, 'Limita a largura e altura máxima do vídeo. A proporção é mantida. Ex: 800, 1024, 1920'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _maxFpsController,
                    decoration: const InputDecoration(
                      labelText: 'FPS máximo',
                      hintText: 'Ex: 30',
                      border: OutlineInputBorder(),
                      helperText: 'Frames por segundo',
                    ),
                    onTap: () => _showTooltip(context, 'Limita o número de frames por segundo. Menor FPS reduz o uso de recursos. Ex: 15, 30, 60'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _videoCodec,
                    decoration: const InputDecoration(
                      labelText: 'Codec de vídeo',
                      border: OutlineInputBorder(),
                      helperText: 'Codec para codificação',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'h264', child: Text('H.264 (padrão)')),
                      DropdownMenuItem(value: 'h265', child: Text('H.265 (HEVC)')),
                      DropdownMenuItem(value: 'av1', child: Text('AV1')),
                    ],
                    onChanged: (v) => setState(() => _videoCodec = v ?? 'h264'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _videoSource,
                    decoration: const InputDecoration(
                      labelText: 'Fonte de vídeo',
                      border: OutlineInputBorder(),
                      helperText: 'Origem do vídeo',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'display', child: Text('Tela do dispositivo')),
                      DropdownMenuItem(value: 'camera', child: Text('Câmera')),
                    ],
                    onChanged: (v) => setState(() => _videoSource = v ?? 'display'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _videoBufferController,
                    decoration: const InputDecoration(
                      labelText: 'Buffer de vídeo (ms)',
                      hintText: 'Ex: 50',
                      border: OutlineInputBorder(),
                      helperText: 'Delay em milissegundos',
                    ),
                    onTap: () => _showTooltip(context, 'Adiciona buffering de vídeo para compensar instabilidades de rede e obter reprodução mais suave'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _angleController,
                    decoration: const InputDecoration(
                      labelText: 'Ângulo de rotação (°)',
                      hintText: 'Ex: 90',
                      border: OutlineInputBorder(),
                      helperText: 'Rotação personalizada',
                    ),
                    onTap: () => _showTooltip(context, 'Rotaciona o vídeo por um ângulo personalizado em graus (sentido horário)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _cropController,
                    decoration: const InputDecoration(
                      labelText: 'Recorte (crop)',
                      hintText: 'width:height:x:y',
                      border: OutlineInputBorder(),
                      helperText: 'Área para espelhar',
                    ),
                    onTap: () => _showTooltip(context, 'Recorta a tela para espelhar apenas parte dela. Formato: largura:altura:x:y. Ex: 1224:1440:0:0'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _videoEncoderController,
                    decoration: const InputDecoration(
                      labelText: 'Encoder específico',
                      hintText: 'Nome do encoder',
                      border: OutlineInputBorder(),
                      helperText: 'Encoder de hardware',
                    ),
                    onTap: () => _showTooltip(context, 'Especifica um encoder de vídeo específico. Use --list-encoders para ver opções disponíveis'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Áudio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _audioCodec,
                    decoration: const InputDecoration(
                      labelText: 'Codec de áudio',
                      border: OutlineInputBorder(),
                      helperText: 'Codec para codificação',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'opus', child: Text('Opus (padrão)')),
                      DropdownMenuItem(value: 'aac', child: Text('AAC')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'raw', child: Text('RAW (PCM 16-bit)')),
                    ],
                    onChanged: (v) => setState(() => _audioCodec = v ?? 'opus'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _audioSource,
                    decoration: const InputDecoration(
                      labelText: 'Fonte de áudio',
                      border: OutlineInputBorder(),
                      helperText: 'Origem do áudio',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'output', child: Text('Saída do dispositivo')),
                      DropdownMenuItem(value: 'mic', child: Text('Microfone')),
                      DropdownMenuItem(value: 'playback', child: Text('Reprodução de apps')),
                      DropdownMenuItem(value: 'mic-unprocessed', child: Text('Microfone (raw)')),
                      DropdownMenuItem(value: 'mic-camcorder', child: Text('Microfone (filmadora)')),
                      DropdownMenuItem(value: 'mic-voice-recognition', child: Text('Microfone (reconhecimento)')),
                      DropdownMenuItem(value: 'mic-voice-communication', child: Text('Microfone (comunicação)')),
                      DropdownMenuItem(value: 'voice-call', child: Text('Chamada de voz')),
                      DropdownMenuItem(value: 'voice-call-uplink', child: Text('Chamada (upload)')),
                      DropdownMenuItem(value: 'voice-call-downlink', child: Text('Chamada (download)')),
                    ],
                    onChanged: (v) => setState(() => _audioSource = v ?? 'output'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _audioBitrateController,
                    decoration: const InputDecoration(
                      labelText: 'Bitrate do áudio',
                      hintText: 'Ex: 128K',
                      border: OutlineInputBorder(),
                      helperText: 'Taxa de bits do áudio',
                    ),
                    onTap: () => _showTooltip(context, 'Define a taxa de bits do áudio. Padrão: 128K. Valores: 64K, 128K, 256K'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _audioBufferController,
                    decoration: const InputDecoration(
                      labelText: 'Buffer de áudio (ms)',
                      hintText: 'Ex: 50',
                      border: OutlineInputBorder(),
                      helperText: 'Delay para suavizar',
                    ),
                    onTap: () => _showTooltip(context, 'Buffer de áudio para minimizar falhas. Padrão: 50ms. Valores menores = menos latência'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _audioOutputBufferController,
                    decoration: const InputDecoration(
                      labelText: 'Buffer de saída (ms)',
                      hintText: 'Ex: 5',
                      border: OutlineInputBorder(),
                      helperText: 'Buffer da saída de áudio',
                    ),
                    onTap: () => _showTooltip(context, 'Buffer da saída de áudio. Padrão: 5ms. Altere apenas se houver áudio robótico'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _audioEncoderController,
                    decoration: const InputDecoration(
                      labelText: 'Encoder específico',
                      hintText: 'Nome do encoder',
                      border: OutlineInputBorder(),
                      helperText: 'Encoder de áudio',
                    ),
                    onTap: () => _showTooltip(context, 'Especifica um encoder de áudio específico. Use --list-encoders para ver opções'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Sem áudio'),
                  selected: _noAudio,
                  onSelected: (v) => setState(() => _noAudio = v),
                  tooltip: 'Desabilita completamente o áudio',
                ),
                FilterChip(
                  label: const Text('Não reproduzir áudio'),
                  selected: _noAudioPlayback,
                  onSelected: (v) => setState(() => _noAudioPlayback = v),
                  tooltip: 'Captura áudio mas não reproduz no computador',
                ),
                FilterChip(
                  label: const Text('Duplicar áudio'),
                  selected: _audioDup,
                  onSelected: (v) => setState(() => _audioDup = v),
                  tooltip: 'Mantém áudio tocando no dispositivo enquanto espelha',
                ),
                FilterChip(
                  label: const Text('Exigir áudio'),
                  selected: _requireAudio,
                  onSelected: (v) => setState(() => _requireAudio = v),
                  tooltip: 'Falha se o áudio não estiver disponível',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Display',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _orientation,
                    decoration: const InputDecoration(
                      labelText: 'Orientação',
                      border: OutlineInputBorder(),
                      helperText: 'Orientação da exibição',
                    ),
                    items: const [
                      DropdownMenuItem(value: '0', child: Text('0° (Padrão)')),
                      DropdownMenuItem(value: '90', child: Text('90° (Horário)')),
                      DropdownMenuItem(value: '180', child: Text('180°')),
                      DropdownMenuItem(value: '270', child: Text('270° (Anti-horário)')),
                      DropdownMenuItem(value: 'flip0', child: Text('Espelho horizontal')),
                      DropdownMenuItem(value: 'flip90', child: Text('Espelho + 90°')),
                      DropdownMenuItem(value: 'flip180', child: Text('Espelho + 180°')),
                      DropdownMenuItem(value: 'flip270', child: Text('Espelho + 270°')),
                    ],
                    onChanged: (v) => setState(() => _orientation = v ?? '0'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _displayIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID do display',
                      hintText: 'Ex: 1',
                      border: OutlineInputBorder(),
                      helperText: 'Display específico',
                    ),
                    onTap: () => _showTooltip(context, 'ID do display para espelhar (use --list-displays para ver opções)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _displayImePolicy,
                    decoration: const InputDecoration(
                      labelText: 'Política do teclado virtual',
                      border: OutlineInputBorder(),
                      helperText: 'Onde mostrar o teclado',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Padrão')),
                      DropdownMenuItem(value: 'local', child: Text('Display local')),
                    ],
                    onChanged: (v) => setState(() => _displayImePolicy = v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _captureOrientationController,
                    decoration: const InputDecoration(
                      labelText: 'Orientação de captura',
                      hintText: 'Ex: 90, @90',
                      border: OutlineInputBorder(),
                      helperText: 'Orientação na captura',
                    ),
                    onTap: () => _showTooltip(context, 'Orientação aplicada na captura. Use @ para travar (ex: @90)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _displayOrientationController,
                    decoration: const InputDecoration(
                      labelText: 'Orientação do display',
                      hintText: 'Ex: 90',
                      border: OutlineInputBorder(),
                      helperText: 'Orientação da exibição',
                    ),
                    onTap: () => _showTooltip(context, 'Orientação aplicada na exibição no computador'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _recordOrientationController,
                    decoration: const InputDecoration(
                      labelText: 'Orientação da gravação',
                      hintText: 'Ex: 90',
                      border: OutlineInputBorder(),
                      helperText: 'Orientação na gravação',
                    ),
                    onTap: () => _showTooltip(context, 'Orientação aplicada na gravação do vídeo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _newDisplayController,
                    decoration: const InputDecoration(
                      labelText: 'Novo display virtual',
                      hintText: '1920x1080 ou 1920x1080/420',
                      border: OutlineInputBorder(),
                      helperText: 'Cria display virtual',
                    ),
                    onTap: () => _showTooltip(context, 'Cria um display virtual com resolução específica. Ex: 1920x1080, 1920x1080/420 (com DPI)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Controle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _keyboard.isEmpty ? '' : _keyboard,
                    decoration: const InputDecoration(
                      labelText: 'Modo do teclado',
                      border: OutlineInputBorder(),
                      helperText: 'Como simular teclado',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('SDK (padrão)')),
                      DropdownMenuItem(value: 'uhid', child: Text('UHID (recomendado)')),
                      DropdownMenuItem(value: 'aoa', child: Text('AOA (USB apenas)')),
                      DropdownMenuItem(value: 'disabled', child: Text('Desabilitado')),
                    ],
                    onChanged: (v) => setState(() => _keyboard = v ?? ''),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _mouse.isEmpty ? '' : _mouse,
                    decoration: const InputDecoration(
                      labelText: 'Modo do mouse',
                      border: OutlineInputBorder(),
                      helperText: 'Como simular mouse',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('SDK (padrão)')),
                      DropdownMenuItem(value: 'uhid', child: Text('UHID')),
                      DropdownMenuItem(value: 'aoa', child: Text('AOA (USB apenas)')),
                      DropdownMenuItem(value: 'disabled', child: Text('Desabilitado')),
                    ],
                    onChanged: (v) => setState(() => _mouse = v ?? ''),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _gamepad.isEmpty ? '' : _gamepad,
                    decoration: const InputDecoration(
                      labelText: 'Modo do gamepad',
                      border: OutlineInputBorder(),
                      helperText: 'Como simular gamepad',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Desabilitado')),
                      DropdownMenuItem(value: 'uhid', child: Text('UHID')),
                      DropdownMenuItem(value: 'aoa', child: Text('AOA (USB apenas)')),
                    ],
                    onChanged: (v) => setState(() => _gamepad = v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _mouseBindController,
                    decoration: const InputDecoration(
                      labelText: 'Configuração de botões do mouse',
                      hintText: 'bhsn:++++',
                      border: OutlineInputBorder(),
                      helperText: 'Atalhos dos botões',
                    ),
                    onTap: () => _showTooltip(context, 'Define atalhos para botões do mouse. Formato: principal:secundário. Caracteres: +forward -ignore b=BACK h=HOME s=APP_SWITCH n=notifications'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _shortcutModController,
                    decoration: const InputDecoration(
                      labelText: 'Modificador de atalhos',
                      hintText: 'lalt,ralt,lctrl',
                      border: OutlineInputBorder(),
                      helperText: 'Teclas modificadoras',
                    ),
                    onTap: () => _showTooltip(context, 'Define quais teclas servem como modificador para atalhos. Opções: lalt, ralt, lctrl, rctrl, lsuper, rsuper'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Sempre no topo'),
                  selected: _alwaysOnTop,
                  onSelected: (v) => setState(() => _alwaysOnTop = v),
                  tooltip: 'Mantém a janela sempre visível por cima de outras',
                ),
                FilterChip(
                  label: const Text('Tela cheia'),
                  selected: _fullscreen,
                  onSelected: (v) => setState(() => _fullscreen = v),
                  tooltip: 'Inicia em modo tela cheia',
                ),
                FilterChip(
                  label: const Text('Mostrar toques'),
                  selected: _showTouches,
                  onSelected: (v) => setState(() => _showTouches = v),
                  tooltip: 'Mostra indicadores visuais dos toques na tela',
                ),
                FilterChip(
                  label: const Text('Sem controle'),
                  selected: _noControl,
                  onSelected: (v) => setState(() => _noControl = v),
                  tooltip: 'Desabilita todos os controles (somente espelhamento)',
                ),
                FilterChip(
                  label: const Text('Manter tela ligada'),
                  selected: _stayAwake,
                  onSelected: (v) => setState(() => _stayAwake = v),
                  tooltip: 'Evita que a tela do dispositivo desligue',
                ),
                FilterChip(
                  label: const Text('Desligar tela'),
                  selected: _turnScreenOff,
                  onSelected: (v) => setState(() => _turnScreenOff = v),
                  tooltip: 'Desliga a tela do dispositivo ao iniciar',
                ),
                FilterChip(
                  label: const Text('Desligar ao fechar'),
                  selected: _powerOffOnClose,
                  onSelected: (v) => setState(() => _powerOffOnClose = v),
                  tooltip: 'Desliga o dispositivo ao fechar o scrcpy',
                ),
                FilterChip(
                  label: const Text('Desabilitar protetor'),
                  selected: _disableScreensaver,
                  onSelected: (v) => setState(() => _disableScreensaver = v),
                  tooltip: 'Impede que o protetor de tela do computador seja ativado',
                ),
                FilterChip(
                  label: const Text('Modo OTG'),
                  selected: _otg,
                  onSelected: (v) => setState(() => _otg = v),
                  tooltip: 'Controla usando AOA sem depuração USB (sem vídeo/áudio)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Configurações de Câmera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (_videoSource == 'camera')
                  const Icon(Icons.camera_alt, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _cameraIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID da câmera',
                      hintText: 'Ex: 0, 1',
                      border: OutlineInputBorder(),
                      helperText: 'Câmera específica',
                    ),
                    onTap: () => _showTooltip(context, 'ID específico da câmera (use --list-cameras para ver opções)'),
                    enabled: _videoSource == 'camera',
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _cameraFacing.isEmpty ? '' : _cameraFacing,
                    decoration: const InputDecoration(
                      labelText: 'Orientação da câmera',
                      border: OutlineInputBorder(),
                      helperText: 'Qual câmera usar',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Primeira disponível')),
                      DropdownMenuItem(value: 'front', child: Text('Frontal')),
                      DropdownMenuItem(value: 'back', child: Text('Traseira')),
                      DropdownMenuItem(value: 'external', child: Text('Externa')),
                    ],
                    onChanged: _videoSource == 'camera' ? (v) => setState(() => _cameraFacing = v ?? '') : null,
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _cameraSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Resolução da câmera',
                      hintText: '1920x1080',
                      border: OutlineInputBorder(),
                      helperText: 'Resolução específica',
                    ),
                    onTap: () => _showTooltip(context, 'Define resolução específica da câmera (ex: 1920x1080)'),
                    enabled: _videoSource == 'camera',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _cameraArController,
                    decoration: const InputDecoration(
                      labelText: 'Proporção da câmera',
                      hintText: '16:9 ou 1.77',
                      border: OutlineInputBorder(),
                      helperText: 'Aspecto da imagem',
                    ),
                    onTap: () => _showTooltip(context, 'Define proporção da câmera. Ex: 4:3, 16:9, 1.77, sensor'),
                    enabled: _videoSource == 'camera',
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _cameraFpsController,
                    decoration: const InputDecoration(
                      labelText: 'FPS da câmera',
                      hintText: 'Ex: 30, 60',
                      border: OutlineInputBorder(),
                      helperText: 'Frames por segundo',
                    ),
                    onTap: () => _showTooltip(context, 'Define FPS específico para captura da câmera'),
                    enabled: _videoSource == 'camera',
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: FilterChip(
                    label: const Text('Alta velocidade'),
                    selected: _cameraHighSpeed,
                    onSelected: _videoSource == 'camera' ? (v) => setState(() => _cameraHighSpeed = v) : null,
                    tooltip: 'Modo de captura em alta velocidade (câmera lenta)',
                  ),
                ),
              ],
            ),
            if (_videoSource != 'camera')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'As configurações de câmera só são aplicadas quando "Câmera" está selecionada como fonte de vídeo.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Conexão',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _serialController,
                    decoration: InputDecoration(
                      labelText: 'Serial do dispositivo',
                      hintText: _selectedDevice != null ? 'Usando dispositivo selecionado: ${_selectedDevice!.serial}' : 'abc123456789',
                      border: const OutlineInputBorder(),
                      helperText: _selectedDevice != null 
                        ? 'Dispositivo selecionado na barra superior será usado'
                        : 'Dispositivo específico (ou selecione na barra superior)',
                      prefixIcon: _selectedDevice != null 
                        ? Icon(
                            Icons.link,
                            color: _selectedDevice!.isOnline ? Colors.green : Colors.orange,
                          )
                        : const Icon(Icons.smartphone_outlined),
                    ),
                    onTap: () => _showTooltip(context, _selectedDevice != null 
                      ? 'O dispositivo selecionado na barra superior será usado automaticamente. Você pode digitar um serial diferente aqui para sobrescrever.'
                      : 'Serial específico do dispositivo (use adb devices para ver ou selecione um dispositivo na barra superior)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _tcpipController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço TCP/IP',
                      hintText: '192.168.1.100:5555',
                      border: OutlineInputBorder(),
                      helperText: 'Conexão wireless',
                    ),
                    onTap: () => _showTooltip(context, 'Conecta via TCP/IP (WiFi). Ex: 192.168.1.100:5555'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Porta do servidor',
                      hintText: 'Ex: 27183',
                      border: OutlineInputBorder(),
                      helperText: 'Porta para tunneling',
                    ),
                    onTap: () => _showTooltip(context, 'Porta usada para estabelecer túnel ADB (padrão: 27183)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _tunnelHostController,
                    decoration: const InputDecoration(
                      labelText: 'Host do túnel',
                      hintText: '192.168.1.2',
                      border: OutlineInputBorder(),
                      helperText: 'Servidor ADB remoto',
                    ),
                    onTap: () => _showTooltip(context, 'Host do servidor ADB remoto para tunneling'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _tunnelPortController,
                    decoration: const InputDecoration(
                      labelText: 'Porta do túnel',
                      hintText: 'Ex: 1234',
                      border: OutlineInputBorder(),
                      helperText: 'Porta do túnel',
                    ),
                    onTap: () => _showTooltip(context, 'Força uma porta diferente para o túnel (situações complexas)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Selecionar USB'),
                  selected: _selectUsb,
                  onSelected: (v) => setState(() => _selectUsb = v),
                  tooltip: 'Força uso de dispositivo USB quando múltiplos estão disponíveis',
                ),
                FilterChip(
                  label: const Text('Selecionar TCP/IP'),
                  selected: _selectTcpip,
                  onSelected: (v) => setState(() => _selectTcpip = v),
                  tooltip: 'Força uso de dispositivo TCP/IP quando múltiplos estão disponíveis',
                ),
                FilterChip(
                  label: const Text('Forçar ADB forward'),
                  selected: _forceAdbForward,
                  onSelected: (v) => setState(() => _forceAdbForward = v),
                  tooltip: 'Força conexão forward em vez de reverse para tunneling',
                ),
                FilterChip(
                  label: const Text('Encerrar ADB ao fechar'),
                  selected: _killAdbOnClose,
                  onSelected: (v) => setState(() => _killAdbOnClose = v),
                  tooltip: 'Encerra servidor ADB ao fechar scrcpy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: _isLoadingDevices 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
              tooltip: 'Atualizar dispositivos',
              onPressed: _isLoadingDevices ? null : _refreshAdbDevices,
            ),
        ],
        title: _buildDeviceDropdown()
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildScrcpyStatusSection(),
              const SizedBox(height: 16),
              _buildProfileSection(),
              const SizedBox(height: 16),
              _buildVideoSection(),
              const SizedBox(height: 16),
              _buildAudioSection(),
              const SizedBox(height: 16),
              _buildDisplaySection(),
              const SizedBox(height: 16),
              _buildControlSection(),
              const SizedBox(height: 16),
              _buildCameraSection(),
              const SizedBox(height: 16),
              _buildConnectionSection(),
              const SizedBox(height: 16),
              _buildRecordingSection(),
              const SizedBox(height: 16),
              _buildFilesSection(),
              const SizedBox(height: 16),
              _buildWindowSection(),
              const SizedBox(height: 16),
              _buildAdvancedSection(),
              const SizedBox(height: 24),
              _buildDocumentationSection(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Gerar comando'),
                onPressed: () => _startScrcpy(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Iniciar aplicação'),
        onPressed: () => _startScrcpy(execute: true),
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Gravação',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _recordController,
                    decoration: const InputDecoration(
                      labelText: 'Arquivo de gravação',
                      hintText: 'video.mp4',
                      border: OutlineInputBorder(),
                      helperText: 'Nome do arquivo',
                      suffixIcon: Icon(Icons.video_file),
                    ),
                    onTap: () => _showTooltip(context, 'Caminho para gravar vídeo e áudio. Extensões: .mp4, .mkv, .opus, .flac, .wav'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _recordFormat.isEmpty ? '' : _recordFormat,
                    decoration: const InputDecoration(
                      labelText: 'Formato da gravação',
                      border: OutlineInputBorder(),
                      helperText: 'Container do arquivo',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Auto (pela extensão)')),
                      DropdownMenuItem(value: 'mp4', child: Text('MP4')),
                      DropdownMenuItem(value: 'mkv', child: Text('Matroska (MKV)')),
                      DropdownMenuItem(value: 'opus', child: Text('OPUS')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'wav', child: Text('WAV')),
                    ],
                    onChanged: (v) => setState(() => _recordFormat = v ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Arquivos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _pushTargetController,
                    decoration: const InputDecoration(
                      labelText: 'Pasta de destino para arquivos',
                      hintText: '/sdcard/Downloads/',
                      border: OutlineInputBorder(),
                      helperText: 'Onde salvar no dispositivo',
                      prefixIcon: Icon(Icons.folder),
                    ),
                    onTap: () => _showTooltip(context, 'Pasta onde arquivos arrastados para scrcpy são salvos no dispositivo. Padrão: /sdcard/Download/'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Janela',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _windowTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Título da janela',
                      hintText: 'Meu Dispositivo',
                      border: OutlineInputBorder(),
                      helperText: 'Título personalizado',
                    ),
                    onTap: () => _showTooltip(context, 'Define um título personalizado para a janela (padrão: modelo do dispositivo)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: FilterChip(
                    label: const Text('Sem bordas'),
                    selected: _windowBorderless,
                    onSelected: (v) => setState(() => _windowBorderless = v),
                    tooltip: 'Remove decorações da janela (bordas, barra de título)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Posição e Tamanho Inicial',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 3,
                  child: TextFormField(
                    controller: _windowXController,
                    decoration: const InputDecoration(
                      labelText: 'Posição X',
                      hintText: '100',
                      border: OutlineInputBorder(),
                      helperText: 'Pixels da esquerda',
                    ),
                    onTap: () => _showTooltip(context, 'Posição horizontal inicial da janela em pixels'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 3,
                  child: TextFormField(
                    controller: _windowYController,
                    decoration: const InputDecoration(
                      labelText: 'Posição Y',
                      hintText: '100',
                      border: OutlineInputBorder(),
                      helperText: 'Pixels do topo',
                    ),
                    onTap: () => _showTooltip(context, 'Posição vertical inicial da janela em pixels'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 3,
                  child: TextFormField(
                    controller: _windowWidthController,
                    decoration: const InputDecoration(
                      labelText: 'Largura',
                      hintText: '800',
                      border: OutlineInputBorder(),
                      helperText: 'Pixels de largura',
                    ),
                    onTap: () => _showTooltip(context, 'Largura inicial da janela em pixels'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 3,
                  child: TextFormField(
                    controller: _windowHeightController,
                    decoration: const InputDecoration(
                      labelText: 'Altura',
                      hintText: '600',
                      border: OutlineInputBorder(),
                      helperText: 'Pixels de altura',
                    ),
                    onTap: () => _showTooltip(context, 'Altura inicial da janela em pixels'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações Avançadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _timeLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Limite de tempo (s)',
                      hintText: 'Ex: 120',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-encerramento',
                    ),
                    onTap: () => _showTooltip(context, 'Encerra automaticamente após X segundos'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _screenOffTimeoutController,
                    decoration: const InputDecoration(
                      labelText: 'Timeout da tela (s)',
                      hintText: 'Ex: 300',
                      border: OutlineInputBorder(),
                      helperText: 'Desligar tela após inatividade',
                    ),
                    onTap: () => _showTooltip(context, 'Desliga tela do dispositivo após X segundos de inatividade'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _verbosity.isEmpty ? '' : _verbosity,
                    decoration: const InputDecoration(
                      labelText: 'Nível de log',
                      border: OutlineInputBorder(),
                      helperText: 'Detalhes do log',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Padrão')),
                      DropdownMenuItem(value: 'quiet', child: Text('Silencioso')),
                      DropdownMenuItem(value: 'verbose', child: Text('Verboso')),
                      DropdownMenuItem(value: 'debug', child: Text('Debug')),
                    ],
                    onChanged: (v) => setState(() => _verbosity = v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: Autocomplete<InstalledApp>(
                    displayStringForOption: (app) => app.appName,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _installedApps.take(10);
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return _installedApps.where((app) {
                        return app.appName.toLowerCase().contains(query) ||
                               app.packageName.toLowerCase().contains(query);
                      }).take(10);
                    },
                    onSelected: (app) {
                      _startAppController.text = app.packageName;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      // Sincronizar com o controller principal
                      if (_startAppController.text != controller.text) {
                        controller.text = _startAppController.text;
                      }
                      
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'App para iniciar',
                          hintText: _selectedDevice?.isOnline == true 
                            ? 'Digite para buscar apps instalados...'
                            : 'com.android.settings',
                          border: const OutlineInputBorder(),
                          helperText: 'Package do app',
                          suffixIcon: _isLoadingApps
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _selectedDevice?.isOnline == true
                              ? IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _refreshInstalledApps,
                                  tooltip: 'Atualizar lista de apps',
                                )
                              : const Icon(Icons.apps),
                        ),
                        onChanged: (value) {
                          _startAppController.text = value;
                        },
                        onTap: () {
                          if (_selectedDevice?.isOnline != true) {
                            _showTooltip(context, 'Conecte um dispositivo online para ver os aplicativos instalados.');
                          } else if (_installedApps.isEmpty && !_isLoadingApps) {
                            _refreshInstalledApps();
                          }
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final app = options.elementAt(index);
                                return ListTile(
                                  leading: Icon(
                                    app.isSystemApp ? Icons.android : Icons.apps,
                                    color: app.isSystemApp ? Colors.green : Colors.blue,
                                  ),
                                  title: Text(
                                    app.appName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () => onSelected(app),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: DropdownButtonFormField<String>(
                    value: _pauseOnExit.isEmpty ? '' : _pauseOnExit,
                    decoration: const InputDecoration(
                      labelText: 'Pausar ao sair',
                      border: OutlineInputBorder(),
                      helperText: 'Comportamento ao fechar',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Padrão')),
                      DropdownMenuItem(value: 'if-error', child: Text('Se houver erro')),
                      DropdownMenuItem(value: 'always', child: Text('Sempre')),
                    ],
                    onChanged: (v) => setState(() => _pauseOnExit = v ?? ''),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 4,
                  child: TextFormField(
                    controller: _renderDriverController,
                    decoration: const InputDecoration(
                      labelText: 'Driver de renderização',
                      hintText: 'opengl, vulkan',
                      border: OutlineInputBorder(),
                      helperText: 'Driver gráfico',
                    ),
                    onTap: () => _showTooltip(context, 'Especifica driver de renderização específico (ex: opengl, vulkan, software)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveRow(
              horizontalSpacing: 16,
              runSpacing: 16,
              children: [
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _v4l2SinkController,
                    decoration: const InputDecoration(
                      labelText: 'V4L2 Sink (Linux)',
                      hintText: '/dev/video2',
                      border: OutlineInputBorder(),
                      helperText: 'Dispositivo de vídeo virtual',
                    ),
                    onTap: () => _showTooltip(context, 'Envia vídeo para dispositivo V4L2 no Linux (para usar como webcam)'),
                  ),
                ),
                ResponsiveColumn(
                  xxs: 12,
                  sm: 6,
                  md: 6,
                  child: TextFormField(
                    controller: _v4l2BufferController,
                    decoration: const InputDecoration(
                      labelText: 'Buffer V4L2 (ms)',
                      hintText: 'Ex: 300',
                      border: OutlineInputBorder(),
                      helperText: 'Delay para V4L2',
                    ),
                    onTap: () => _showTooltip(context, 'Adiciona buffering para stream V4L2'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Opções de Controle Avançadas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Sem reprodução'),
                  selected: _noPlayback,
                  onSelected: (v) => setState(() => _noPlayback = v),
                  tooltip: 'Não reproduz vídeo/áudio (útil para gravação)',
                ),
                FilterChip(
                  label: const Text('Sem reprodução de vídeo'),
                  selected: _noVideoPlayback,
                  onSelected: (v) => setState(() => _noVideoPlayback = v),
                  tooltip: 'Não mostra vídeo na tela (mas pode gravar)',
                ),
                FilterChip(
                  label: const Text('Sem vídeo'),
                  selected: _noVideo,
                  onSelected: (v) => setState(() => _noVideo = v),
                  tooltip: 'Desabilita completamente o vídeo (só áudio)',
                ),
                FilterChip(
                  label: const Text('Sem janela'),
                  selected: _noWindow,
                  onSelected: (v) => setState(() => _noWindow = v),
                  tooltip: 'Executa sem interface gráfica',
                ),
                FilterChip(
                  label: const Text('Não limpar'),
                  selected: _noCleanup,
                  onSelected: (v) => setState(() => _noCleanup = v),
                  tooltip: 'Não remove arquivos temporários',
                ),
                FilterChip(
                  label: const Text('Não sincronizar clipboard'),
                  selected: _noClipboardAutosync,
                  onSelected: (v) => setState(() => _noClipboardAutosync = v),
                  tooltip: 'Desabilita sincronização automática da área de transferência',
                ),
                FilterChip(
                  label: const Text('Não redimensionar em erro'),
                  selected: _noDownsizeOnError,
                  onSelected: (v) => setState(() => _noDownsizeOnError = v),
                  tooltip: 'Não reduz resolução automaticamente se codificação falhar',
                ),
                FilterChip(
                  label: const Text('Não repetir teclas'),
                  selected: _noKeyRepeat,
                  onSelected: (v) => setState(() => _noKeyRepeat = v),
                  tooltip: 'Não envia eventos repetidos de teclas pressionadas',
                ),
                FilterChip(
                  label: const Text('Sem mipmaps'),
                  selected: _noMipmaps,
                  onSelected: (v) => setState(() => _noMipmaps = v),
                  tooltip: 'Desabilita mipmaps (pode melhorar performance)',
                ),
                FilterChip(
                  label: const Text('Sem hover do mouse'),
                  selected: _noMouseHover,
                  onSelected: (v) => setState(() => _noMouseHover = v),
                  tooltip: 'Não envia eventos de movimento do mouse sem clique',
                ),
                FilterChip(
                  label: const Text('Não ligar tela'),
                  selected: _noPowerOn,
                  onSelected: (v) => setState(() => _noPowerOn = v),
                  tooltip: 'Não liga a tela do dispositivo na conexão',
                ),
                FilterChip(
                  label: const Text('Não destruir conteúdo VD'),
                  selected: _noVdDestroyContent,
                  onSelected: (v) => setState(() => _noVdDestroyContent = v),
                  tooltip: 'Move apps para display principal ao fechar display virtual',
                ),
                FilterChip(
                  label: const Text('Sem decorações VD'),
                  selected: _noVdSystemDecorations,
                  onSelected: (v) => setState(() => _noVdSystemDecorations = v),
                  tooltip: 'Desabilita decorações do sistema no display virtual',
                ),
                FilterChip(
                  label: const Text('Colar legado'),
                  selected: _legacyPaste,
                  onSelected: (v) => setState(() => _legacyPaste = v),
                  tooltip: 'Usa método antigo de colar (para dispositivos problemáticos)',
                ),
                FilterChip(
                  label: const Text('Preferir texto'),
                  selected: _preferText,
                  onSelected: (v) => setState(() => _preferText = v),
                  tooltip: 'Injeta letras como eventos de texto (quebra jogos)',
                ),
                FilterChip(
                  label: const Text('Eventos de tecla raw'),
                  selected: _rawKeyEvents,
                  onSelected: (v) => setState(() => _rawKeyEvents = v),
                  tooltip: 'Força eventos de tecla raw em vez de eventos de texto',
                ),
                FilterChip(
                  label: const Text('Mostrar FPS'),
                  selected: _printFps,
                  onSelected: (v) => setState(() => _printFps = v),
                  tooltip: 'Mostra contador de FPS no console',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documentação e Ajuda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Para mais informações sobre todas as opções do scrcpy, consulte a documentação oficial:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openDocumentation(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Documentação Oficial do scrcpy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'https://github.com/Genymobile/scrcpy/blob/master/README.md',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.open_in_new, color: Colors.blue[700], size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDocumentation() async {
    const url = 'https://github.com/Genymobile/scrcpy/blob/master/README.md';
    
    try {
      // Tentar abrir com o comando start no Windows (cmd /c start)
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', url], runInShell: true);
      } else {
        // Para outros sistemas, tentar xdg-open (Linux) ou open (macOS)
        if (Platform.isLinux) {
          await Process.start('xdg-open', [url]);
        } else if (Platform.isMacOS) {
          await Process.start('open', [url]);
        }
      }
    } catch (e) {
      // Se falhar, copiar URL para clipboard
      await Clipboard.setData(const ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o navegador. URL copiada para a área de transferência!'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showTooltip(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
