import 'package:flutter/material.dart';
import 'dart:io';
import 'scrcpy_profile.dart';
import 'scrcpy_manager.dart';
import 'config_manager.dart';

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
  
  // Status do scrcpy
  bool _isCheckingVersion = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _installedVersion;
  String? _latestVersion;
  bool _hasUpdate = false;
  
  // Configurações principais
  final TextEditingController _videoBitrateController = TextEditingController(text: '8M');
  final TextEditingController _maxSizeController = TextEditingController();
  bool _alwaysOnTop = false;
  bool _fullscreen = false;
  bool _showTouches = false;
  bool _noControl = false;
  String _orientation = '0';

  @override
  void dispose() {
    _scrcpyPathController.dispose();
    _videoBitrateController.dispose();
    _maxSizeController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadLastConfig();
    _initializeScrcpy();
  }

  Future<void> _initializeScrcpy() async {
    await _checkScrcpyInstallation();
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
    _scrcpyPathController.text = config['scrcpyPath'] ?? '';
    _videoBitrateController.text = config['videoBitrate'] ?? '8M';
    _maxSizeController.text = config['maxSize'] ?? '';
    setState(() {
      _alwaysOnTop = config['alwaysOnTop'] ?? false;
      _fullscreen = config['fullscreen'] ?? false;
      _showTouches = config['showTouches'] ?? false;
      _noControl = config['noControl'] ?? false;
      _orientation = config['orientation'] ?? '0';
    });
  }

  Future<void> _saveLastConfig() async {
    final config = {
      'scrcpyPath': _scrcpyPathController.text,
      'videoBitrate': _videoBitrateController.text,
      'maxSize': _maxSizeController.text,
      'alwaysOnTop': _alwaysOnTop,
      'fullscreen': _fullscreen,
      'showTouches': _showTouches,
      'noControl': _noControl,
      'orientation': _orientation,
      'scrcpy_installed_version': _installedVersion ?? '',
      'scrcpy_install_path': _scrcpyPathController.text,
    };
    await ConfigManager.saveMainConfig(config);
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
    );
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
    });
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
    
    // Configurações básicas
    if (_videoBitrateController.text.isNotEmpty) {
      args.add('--video-bit-rate=${_videoBitrateController.text}');
    }
    if (_maxSizeController.text.isNotEmpty) {
      args.add('--max-size=${_maxSizeController.text}');
    }
    if (_alwaysOnTop) args.add('--always-on-top');
    if (_fullscreen) args.add('--fullscreen');
    if (_showTouches) args.add('--show-touches');
    if (_noControl) args.add('--no-control');
    if (_orientation != '0') args.add('--orientation=$_orientation');

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
              _buildScrcpyStatusSection(),
              const SizedBox(height: 16),
              _buildProfileSection(),
              const SizedBox(height: 16),
              // Configurações básicas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações básicas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
}
