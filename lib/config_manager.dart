import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'scrcpy_profile.dart';

class ConfigManager {
  static const String _configFileName = 'config.json';
  
  /// Obtém o caminho do arquivo de configuração na pasta da aplicação
  static Future<String> getConfigFilePath() async {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.join(executableDir, _configFileName);
  }

  /// Carrega as configurações do arquivo JSON
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final configPath = await getConfigFilePath();
      final configFile = File(configPath);
      
      if (await configFile.exists()) {
        final jsonString = await configFile.readAsString();
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // Silenciosamente falha se não conseguir carregar
      // Em produção, o usuário não precisa ver erros de configuração
    }
    
    // Retorna configurações padrão se não conseguir carregar
    return {};
  }

  /// Salva as configurações no arquivo JSON
  static Future<void> saveConfig(Map<String, dynamic> config) async {
    try {
      final configPath = await getConfigFilePath();
      final configFile = File(configPath);
      
      // Criar o diretório se não existir
      await configFile.parent.create(recursive: true);
      
      // Salvar as configurações formatadas
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(config);
      await configFile.writeAsString(jsonString);
    } catch (e) {
      // Silenciosamente falha se não conseguir salvar
      // Em produção, o usuário não precisa ver erros de configuração
    }
  }

  /// Obtém um valor específico da configuração
  static Future<T?> getValue<T>(String key, [T? defaultValue]) async {
    final config = await loadConfig();
    return config[key] as T? ?? defaultValue;
  }

  /// Define um valor específico na configuração
  static Future<void> setValue<T>(String key, T value) async {
    final config = await loadConfig();
    config[key] = value;
    await saveConfig(config);
  }

  /// Carrega os perfis do arquivo de configuração
  static Future<List<ScrcpyProfile>> loadProfiles() async {
    final config = await loadConfig();
    final profilesJson = config['scrcpy_profiles'] as String?;
    return ScrcpyProfile.decodeList(profilesJson);
  }

  /// Salva os perfis no arquivo de configuração
  static Future<void> saveProfiles(List<ScrcpyProfile> profiles) async {
    final config = await loadConfig();
    config['scrcpy_profiles'] = ScrcpyProfile.encodeList(profiles);
    await saveConfig(config);
  }

  /// Carrega as configurações principais
  static Future<Map<String, dynamic>> loadMainConfig() async {
    final config = await loadConfig();
    return {
      'scrcpyPath': config['scrcpyPath'] ?? '',
      'videoBitrate': config['videoBitrate'] ?? '8M',
      'maxSize': config['maxSize'] ?? '',
      'alwaysOnTop': config['alwaysOnTop'] ?? false,
      'fullscreen': config['fullscreen'] ?? false,
      'showTouches': config['showTouches'] ?? false,
      'noControl': config['noControl'] ?? false,
      'orientation': config['orientation'] ?? '0',
      'scrcpy_installed_version': config['scrcpy_installed_version'] ?? '',
      'scrcpy_install_path': config['scrcpy_install_path'] ?? '',
    };
  }

  /// Salva as configurações principais
  static Future<void> saveMainConfig(Map<String, dynamic> mainConfig) async {
    final config = await loadConfig();
    
    // Atualizar apenas as configurações principais
    config['scrcpyPath'] = mainConfig['scrcpyPath'];
    config['videoBitrate'] = mainConfig['videoBitrate'];
    config['maxSize'] = mainConfig['maxSize'];
    config['alwaysOnTop'] = mainConfig['alwaysOnTop'];
    config['fullscreen'] = mainConfig['fullscreen'];
    config['showTouches'] = mainConfig['showTouches'];
    config['noControl'] = mainConfig['noControl'];
    config['orientation'] = mainConfig['orientation'];
    config['scrcpy_installed_version'] = mainConfig['scrcpy_installed_version'];
    config['scrcpy_install_path'] = mainConfig['scrcpy_install_path'];
    
    await saveConfig(config);
  }

  /// Remove uma chave específica da configuração
  static Future<void> removeValue(String key) async {
    final config = await loadConfig();
    config.remove(key);
    await saveConfig(config);
  }

  /// Limpa todas as configurações
  static Future<void> clearConfig() async {
    final configPath = await getConfigFilePath();
    final configFile = File(configPath);
    
    if (await configFile.exists()) {
      await configFile.delete();
    }
  }

  /// Verifica se o arquivo de configuração existe
  static Future<bool> configExists() async {
    final configPath = await getConfigFilePath();
    final configFile = File(configPath);
    return await configFile.exists();
  }
}
