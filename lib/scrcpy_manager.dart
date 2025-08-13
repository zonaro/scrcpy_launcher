import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'config_manager.dart';

class ScrcpyRelease {
  final String tagName;
  final String name;
  final String publishedAt;
  final List<ScrcpyAsset> assets;
  final bool prerelease;

  ScrcpyRelease({
    required this.tagName,
    required this.name,
    required this.publishedAt,
    required this.assets,
    required this.prerelease,
  });

  factory ScrcpyRelease.fromMap(Map<String, dynamic> map) {
    return ScrcpyRelease(
      tagName: map['tag_name'] ?? '',
      name: map['name'] ?? '',
      publishedAt: map['published_at'] ?? '',
      prerelease: map['prerelease'] ?? false,
      assets: (map['assets'] as List<dynamic>?)
              ?.map((asset) => ScrcpyAsset.fromMap(asset))
              .toList() ??
          [],
    );
  }

  String get version => tagName.replaceFirst('v', '');
}

class ScrcpyAsset {
  final String name;
  final String downloadUrl;
  final int size;

  ScrcpyAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory ScrcpyAsset.fromMap(Map<String, dynamic> map) {
    return ScrcpyAsset(
      name: map['name'] ?? '',
      downloadUrl: map['browser_download_url'] ?? '',
      size: map['size'] ?? 0,
    );
  }
}

class ScrcpyManager {
  static const String _githubApiUrl = 'https://api.github.com/repos/Genymobile/scrcpy/releases';
  static const String _installedVersionKey = 'scrcpy_installed_version';
  static const String _installPathKey = 'scrcpy_install_path';

  /// Obtém a lista de releases do GitHub
  static Future<List<ScrcpyRelease>> getReleases({bool includePrerelease = false}) async {
    try {
      final response = await http.get(Uri.parse(_githubApiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final releases = data.map((release) => ScrcpyRelease.fromMap(release)).toList();
        
        if (!includePrerelease) {
          return releases.where((r) => !r.prerelease).toList();
        }
        
        return releases;
      } else {
        throw Exception('Falha ao buscar releases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com GitHub: $e');
    }
  }

  /// Obtém a última versão disponível
  static Future<ScrcpyRelease?> getLatestRelease({bool includePrerelease = false}) async {
    final releases = await getReleases(includePrerelease: includePrerelease);
    return releases.isNotEmpty ? releases.first : null;
  }

  /// Obtém a versão instalada localmente
  static Future<String?> getInstalledVersion() async {
    return await ConfigManager.getValue<String>(_installedVersionKey);
  }

  /// Salva a versão instalada
  static Future<void> setInstalledVersion(String version) async {
    await ConfigManager.setValue(_installedVersionKey, version);
  }

  /// Obtém o caminho de instalação
  static Future<String?> getInstallPath() async {
    return await ConfigManager.getValue<String>(_installPathKey);
  }

  /// Define o caminho de instalação
  static Future<void> setInstallPath(String path) async {
    await ConfigManager.setValue(_installPathKey, path);
  }

  /// Verifica se há uma nova versão disponível
  static Future<bool> hasNewVersionAvailable() async {
    try {
      final latestRelease = await getLatestRelease();
      final installedVersion = await getInstalledVersion();
      
      if (latestRelease == null || installedVersion == null) {
        return true; // Se não há versão instalada ou não conseguiu verificar, considerar que há update
      }
      
      return _compareVersions(latestRelease.version, installedVersion) > 0;
    } catch (e) {
      return false; // Em caso de erro, assumir que não há update
    }
  }

  /// Compara duas versões (retorna > 0 se v1 > v2, 0 se iguais, < 0 se v1 < v2)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    
    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    
    return 0;
  }

  /// Identifica o asset correto para a plataforma atual
  static ScrcpyAsset? _getAssetForPlatform(List<ScrcpyAsset> assets) {
    if (Platform.isWindows) {
      // Procurar por arquivo Windows (x64)
      for (final asset in assets) {
        if (asset.name.contains('win64') || 
            (asset.name.contains('windows') && asset.name.contains('x64'))) {
          return asset;
        }
      }
      // Fallback para qualquer arquivo Windows
      for (final asset in assets) {
        if (asset.name.contains('win')) {
          return asset;
        }
      }
    } else if (Platform.isLinux) {
      // Procurar por arquivo Linux
      for (final asset in assets) {
        if (asset.name.contains('linux') && asset.name.contains('x86_64')) {
          return asset;
        }
      }
    } else if (Platform.isMacOS) {
      // Procurar por arquivo macOS
      for (final asset in assets) {
        if (asset.name.contains('macos') || asset.name.contains('darwin')) {
          return asset;
        }
      }
    }
    
    return null;
  }

  /// Obtém o diretório base da aplicação para instalar o scrcpy
  static Future<String> getApplicationInstallDirectory() async {
    // Usar o diretório do executável da aplicação
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.join(executableDir, 'scrcpy');
  }

  /// Faz o download da versão especificada
  static Future<String> downloadRelease(
    ScrcpyRelease release, {
    Function(double progress)? onProgress,
  }) async {
    final asset = _getAssetForPlatform(release.assets);
    if (asset == null) {
      throw Exception('Nenhum arquivo compatível encontrado para esta plataforma');
    }

    // Usar sempre o diretório da aplicação
    final installDir = await getApplicationInstallDirectory();

    // Criar diretório se não existir
    final dir = Directory(installDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Nome do arquivo temporário para download
    final tempFileName = asset.name;
    final tempFilePath = path.join(installDir, tempFileName);

    // Fazer download do arquivo
    final response = await http.get(Uri.parse(asset.downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Falha no download: ${response.statusCode}');
    }

    // Salvar arquivo temporário
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(response.bodyBytes);

    // Extrair arquivo se for comprimido
    String scrcpyPath;
    if (tempFileName.endsWith('.zip')) {
      scrcpyPath = await _extractZip(tempFilePath, installDir);
      // Remover arquivo zip após extração
      await tempFile.delete();
    } else {
      scrcpyPath = tempFilePath;
    }

    // Salvar informações da instalação
    await setInstalledVersion(release.version);
    await setInstallPath(scrcpyPath);

    return scrcpyPath;
  }

  /// Extrai arquivo ZIP e retorna o caminho do executável scrcpy
  static Future<String> _extractZip(String zipPath, String extractDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    String? scrcpyExePath;

    for (final file in archive) {
      final filename = file.name;
      final filePath = path.join(extractDir, filename);

      if (file.isFile) {
        final data = file.content as List<int>;
        await File(filePath).create(recursive: true);
        await File(filePath).writeAsBytes(data);

        // Procurar pelo executável scrcpy
        if (filename.endsWith('scrcpy.exe') || 
            (filename.endsWith('scrcpy') && !filename.contains('.'))) {
          scrcpyExePath = filePath;
        }
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    // Procurar recursivamente pelo executável se não foi encontrado
    scrcpyExePath ??= await _findScrcpyExecutable(extractDir);

    if (scrcpyExePath == null) {
      throw Exception('Executável scrcpy não encontrado no arquivo extraído');
    }

    // No Linux/macOS, dar permissão de execução
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', scrcpyExePath]);
    }

    return scrcpyExePath;
  }

  /// Procura recursivamente pelo executável scrcpy
  static Future<String?> _findScrcpyExecutable(String dir) async {
    final directory = Directory(dir);
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final name = path.basename(entity.path);
        if (name == 'scrcpy.exe' || name == 'scrcpy') {
          return entity.path;
        }
      }
    }
    
    return null;
  }

  /// Verifica se o scrcpy está instalado no caminho especificado
  static Future<bool> isScrcpyInstalled(String scrcpyPath) async {
    if (scrcpyPath.isEmpty) return false;
    
    final file = File(scrcpyPath);
    return await file.exists();
  }

  /// Obtém a versão do scrcpy instalado executando o comando --version
  static Future<String?> getScrcpyVersion(String scrcpyPath) async {
    try {
      if (!(await isScrcpyInstalled(scrcpyPath))) {
        return null;
      }

      final result = await Process.run(scrcpyPath, ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // A saída geralmente é no formato "scrcpy 2.4"
        final match = RegExp(r'scrcpy\s+(\d+\.\d+(?:\.\d+)?)').firstMatch(output);
        return match?.group(1);
      }
    } catch (e) {
      return null;
    }
    
    return null;
  }

  /// Sugere um caminho padrão para instalação
  static Future<String> getDefaultInstallPath() async {
    final scrcpyDir = await getApplicationInstallDirectory();
    
    if (Platform.isWindows) {
      return path.join(scrcpyDir, 'scrcpy.exe');
    } else {
      return path.join(scrcpyDir, 'scrcpy');
    }
  }

  /// Auto-detecta instalações existentes do scrcpy
  static Future<List<String>> findExistingInstallations() async {
    final List<String> paths = [];
    
    if (Platform.isWindows) {
      // Procurar em locais comuns no Windows
      final commonPaths = [
        r'C:\Program Files\scrcpy\scrcpy.exe',
        r'C:\Program Files (x86)\scrcpy\scrcpy.exe',
        r'C:\scrcpy\scrcpy.exe',
      ];
      
      for (final path in commonPaths) {
        if (await File(path).exists()) {
          paths.add(path);
        }
      }
      
      // Verificar no PATH
      try {
        final result = await Process.run('where', ['scrcpy.exe']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            final path = line.trim();
            if (path.isNotEmpty && await File(path).exists()) {
              paths.add(path);
            }
          }
        }
      } catch (e) {
        // Ignorar erro
      }
    } else {
      // Procurar no PATH para Linux/macOS
      try {
        final result = await Process.run('which', ['scrcpy']);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty && await File(path).exists()) {
            paths.add(path);
          }
        }
      } catch (e) {
        // Ignorar erro
      }
    }
    
    return paths.toSet().toList(); // Remove duplicatas
  }
}
