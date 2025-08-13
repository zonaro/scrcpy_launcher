import 'dart:convert';

class ScrcpyProfile {
  final String name;
  final String scrcpyPath;
  
  // Vídeo
  final String videoBitrate;
  final String maxSize;
  final String maxFps;
  final String videoCodec;
  final String videoEncoder;
  final String videoSource;
  final String videoBuffer;
  final String angle;
  final String crop;
  
  // Áudio
  final String audioBitrate;
  final String audioBuffer;
  final String audioOutputBuffer;
  final String audioCodec;
  final String audioEncoder;
  final String audioSource;
  final bool audioDup;
  final bool noAudio;
  final bool noAudioPlayback;
  final bool requireAudio;
  
  // Display
  final String orientation;
  final String displayOrientation;
  final String captureOrientation;
  final String recordOrientation;
  final String displayId;
  final String displayImePolicy;
  final String newDisplay;
  
  // Controle
  final bool alwaysOnTop;
  final bool fullscreen;
  final bool showTouches;
  final bool noControl;
  final bool stayAwake;
  final bool turnScreenOff;
  final bool powerOffOnClose;
  final bool disableScreensaver;
  final String keyboard;
  final String mouse;
  final String gamepad;
  final String mouseBind;
  final bool otg;
  
  // Câmera
  final String cameraId;
  final String cameraSize;
  final String cameraAr;
  final String cameraFacing;
  final String cameraFps;
  final bool cameraHighSpeed;
  
  // Conexão
  final String serial;
  final bool selectUsb;
  final bool selectTcpip;
  final String tcpip;
  final String port;
  final String tunnelHost;
  final String tunnelPort;
  final bool forceAdbForward;
  final bool killAdbOnClose;
  
  // Gravação
  final String record;
  final String recordFormat;
  final String pushTarget;
  
  // Janela
  final bool windowBorderless;
  final String windowTitle;
  final String windowX;
  final String windowY;
  final String windowWidth;
  final String windowHeight;
  
  // Configurações avançadas
  final bool noPlayback;
  final bool noVideoPlayback;
  final bool noVideo;
  final bool noWindow;
  final bool noCleanup;
  final bool noClipboardAutosync;
  final bool noDownsizeOnError;
  final bool noKeyRepeat;
  final bool noMipmaps;
  final bool noMouseHover;
  final bool noPowerOn;
  final bool noVdDestroyContent;
  final bool noVdSystemDecorations;
  final bool legacyPaste;
  final bool preferText;
  final bool rawKeyEvents;
  final bool printFps;
  final String pauseOnExit;
  final String timeLimit;
  final String screenOffTimeout;
  final String shortcutMod;
  final String startApp;
  final String verbosity;
  final String renderDriver;
  final String v4l2Sink;
  final String v4l2Buffer;

  ScrcpyProfile({
    required this.name,
    required this.scrcpyPath,
    this.videoBitrate = '8M',
    this.maxSize = '',
    this.maxFps = '',
    this.videoCodec = 'h264',
    this.videoEncoder = '',
    this.videoSource = 'display',
    this.videoBuffer = '',
    this.angle = '',
    this.crop = '',
    this.audioBitrate = '128K',
    this.audioBuffer = '',
    this.audioOutputBuffer = '',
    this.audioCodec = 'opus',
    this.audioEncoder = '',
    this.audioSource = 'output',
    this.audioDup = false,
    this.noAudio = false,
    this.noAudioPlayback = false,
    this.requireAudio = false,
    this.orientation = '0',
    this.displayOrientation = '',
    this.captureOrientation = '',
    this.recordOrientation = '',
    this.displayId = '',
    this.displayImePolicy = '',
    this.newDisplay = '',
    this.alwaysOnTop = false,
    this.fullscreen = false,
    this.showTouches = false,
    this.noControl = false,
    this.stayAwake = false,
    this.turnScreenOff = false,
    this.powerOffOnClose = false,
    this.disableScreensaver = false,
    this.keyboard = '',
    this.mouse = '',
    this.gamepad = '',
    this.mouseBind = '',
    this.otg = false,
    this.cameraId = '',
    this.cameraSize = '',
    this.cameraAr = '',
    this.cameraFacing = '',
    this.cameraFps = '',
    this.cameraHighSpeed = false,
    this.serial = '',
    this.selectUsb = false,
    this.selectTcpip = false,
    this.tcpip = '',
    this.port = '',
    this.tunnelHost = '',
    this.tunnelPort = '',
    this.forceAdbForward = false,
    this.killAdbOnClose = false,
    this.record = '',
    this.recordFormat = '',
    this.pushTarget = '',
    this.windowBorderless = false,
    this.windowTitle = '',
    this.windowX = '',
    this.windowY = '',
    this.windowWidth = '',
    this.windowHeight = '',
    this.noPlayback = false,
    this.noVideoPlayback = false,
    this.noVideo = false,
    this.noWindow = false,
    this.noCleanup = false,
    this.noClipboardAutosync = false,
    this.noDownsizeOnError = false,
    this.noKeyRepeat = false,
    this.noMipmaps = false,
    this.noMouseHover = false,
    this.noPowerOn = false,
    this.noVdDestroyContent = false,
    this.noVdSystemDecorations = false,
    this.legacyPaste = false,
    this.preferText = false,
    this.rawKeyEvents = false,
    this.printFps = false,
    this.pauseOnExit = '',
    this.timeLimit = '',
    this.screenOffTimeout = '',
    this.shortcutMod = '',
    this.startApp = '',
    this.verbosity = '',
    this.renderDriver = '',
    this.v4l2Sink = '',
    this.v4l2Buffer = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'scrcpyPath': scrcpyPath,
        'videoBitrate': videoBitrate,
        'maxSize': maxSize,
        'maxFps': maxFps,
        'videoCodec': videoCodec,
        'videoEncoder': videoEncoder,
        'videoSource': videoSource,
        'videoBuffer': videoBuffer,
        'angle': angle,
        'crop': crop,
        'audioBitrate': audioBitrate,
        'audioBuffer': audioBuffer,
        'audioOutputBuffer': audioOutputBuffer,
        'audioCodec': audioCodec,
        'audioEncoder': audioEncoder,
        'audioSource': audioSource,
        'audioDup': audioDup,
        'noAudio': noAudio,
        'noAudioPlayback': noAudioPlayback,
        'requireAudio': requireAudio,
        'orientation': orientation,
        'displayOrientation': displayOrientation,
        'captureOrientation': captureOrientation,
        'recordOrientation': recordOrientation,
        'displayId': displayId,
        'displayImePolicy': displayImePolicy,
        'newDisplay': newDisplay,
        'alwaysOnTop': alwaysOnTop,
        'fullscreen': fullscreen,
        'showTouches': showTouches,
        'noControl': noControl,
        'stayAwake': stayAwake,
        'turnScreenOff': turnScreenOff,
        'powerOffOnClose': powerOffOnClose,
        'disableScreensaver': disableScreensaver,
        'keyboard': keyboard,
        'mouse': mouse,
        'gamepad': gamepad,
        'mouseBind': mouseBind,
        'otg': otg,
        'cameraId': cameraId,
        'cameraSize': cameraSize,
        'cameraAr': cameraAr,
        'cameraFacing': cameraFacing,
        'cameraFps': cameraFps,
        'cameraHighSpeed': cameraHighSpeed,
        'serial': serial,
        'selectUsb': selectUsb,
        'selectTcpip': selectTcpip,
        'tcpip': tcpip,
        'port': port,
        'tunnelHost': tunnelHost,
        'tunnelPort': tunnelPort,
        'forceAdbForward': forceAdbForward,
        'killAdbOnClose': killAdbOnClose,
        'record': record,
        'recordFormat': recordFormat,
        'pushTarget': pushTarget,
        'windowBorderless': windowBorderless,
        'windowTitle': windowTitle,
        'windowX': windowX,
        'windowY': windowY,
        'windowWidth': windowWidth,
        'windowHeight': windowHeight,
        'noPlayback': noPlayback,
        'noVideoPlayback': noVideoPlayback,
        'noVideo': noVideo,
        'noWindow': noWindow,
        'noCleanup': noCleanup,
        'noClipboardAutosync': noClipboardAutosync,
        'noDownsizeOnError': noDownsizeOnError,
        'noKeyRepeat': noKeyRepeat,
        'noMipmaps': noMipmaps,
        'noMouseHover': noMouseHover,
        'noPowerOn': noPowerOn,
        'noVdDestroyContent': noVdDestroyContent,
        'noVdSystemDecorations': noVdSystemDecorations,
        'legacyPaste': legacyPaste,
        'preferText': preferText,
        'rawKeyEvents': rawKeyEvents,
        'printFps': printFps,
        'pauseOnExit': pauseOnExit,
        'timeLimit': timeLimit,
        'screenOffTimeout': screenOffTimeout,
        'shortcutMod': shortcutMod,
        'startApp': startApp,
        'verbosity': verbosity,
        'renderDriver': renderDriver,
        'v4l2Sink': v4l2Sink,
        'v4l2Buffer': v4l2Buffer,
      };

  factory ScrcpyProfile.fromMap(Map<String, dynamic> map) => ScrcpyProfile(
        name: map['name'] ?? '',
        scrcpyPath: map['scrcpyPath'] ?? '',
        videoBitrate: map['videoBitrate'] ?? '8M',
        maxSize: map['maxSize'] ?? '',
        maxFps: map['maxFps'] ?? '',
        videoCodec: map['videoCodec'] ?? 'h264',
        videoEncoder: map['videoEncoder'] ?? '',
        videoSource: map['videoSource'] ?? 'display',
        videoBuffer: map['videoBuffer'] ?? '',
        angle: map['angle'] ?? '',
        crop: map['crop'] ?? '',
        audioBitrate: map['audioBitrate'] ?? '128K',
        audioBuffer: map['audioBuffer'] ?? '',
        audioOutputBuffer: map['audioOutputBuffer'] ?? '',
        audioCodec: map['audioCodec'] ?? 'opus',
        audioEncoder: map['audioEncoder'] ?? '',
        audioSource: map['audioSource'] ?? 'output',
        audioDup: map['audioDup'] ?? false,
        noAudio: map['noAudio'] ?? false,
        noAudioPlayback: map['noAudioPlayback'] ?? false,
        requireAudio: map['requireAudio'] ?? false,
        orientation: map['orientation'] ?? '0',
        displayOrientation: map['displayOrientation'] ?? '',
        captureOrientation: map['captureOrientation'] ?? '',
        recordOrientation: map['recordOrientation'] ?? '',
        displayId: map['displayId'] ?? '',
        displayImePolicy: map['displayImePolicy'] ?? '',
        newDisplay: map['newDisplay'] ?? '',
        alwaysOnTop: map['alwaysOnTop'] ?? false,
        fullscreen: map['fullscreen'] ?? false,
        showTouches: map['showTouches'] ?? false,
        noControl: map['noControl'] ?? false,
        stayAwake: map['stayAwake'] ?? false,
        turnScreenOff: map['turnScreenOff'] ?? false,
        powerOffOnClose: map['powerOffOnClose'] ?? false,
        disableScreensaver: map['disableScreensaver'] ?? false,
        keyboard: map['keyboard'] ?? '',
        mouse: map['mouse'] ?? '',
        gamepad: map['gamepad'] ?? '',
        mouseBind: map['mouseBind'] ?? '',
        otg: map['otg'] ?? false,
        cameraId: map['cameraId'] ?? '',
        cameraSize: map['cameraSize'] ?? '',
        cameraAr: map['cameraAr'] ?? '',
        cameraFacing: map['cameraFacing'] ?? '',
        cameraFps: map['cameraFps'] ?? '',
        cameraHighSpeed: map['cameraHighSpeed'] ?? false,
        serial: map['serial'] ?? '',
        selectUsb: map['selectUsb'] ?? false,
        selectTcpip: map['selectTcpip'] ?? false,
        tcpip: map['tcpip'] ?? '',
        port: map['port'] ?? '',
        tunnelHost: map['tunnelHost'] ?? '',
        tunnelPort: map['tunnelPort'] ?? '',
        forceAdbForward: map['forceAdbForward'] ?? false,
        killAdbOnClose: map['killAdbOnClose'] ?? false,
        record: map['record'] ?? '',
        recordFormat: map['recordFormat'] ?? '',
        pushTarget: map['pushTarget'] ?? '',
        windowBorderless: map['windowBorderless'] ?? false,
        windowTitle: map['windowTitle'] ?? '',
        windowX: map['windowX'] ?? '',
        windowY: map['windowY'] ?? '',
        windowWidth: map['windowWidth'] ?? '',
        windowHeight: map['windowHeight'] ?? '',
        noPlayback: map['noPlayback'] ?? false,
        noVideoPlayback: map['noVideoPlayback'] ?? false,
        noVideo: map['noVideo'] ?? false,
        noWindow: map['noWindow'] ?? false,
        noCleanup: map['noCleanup'] ?? false,
        noClipboardAutosync: map['noClipboardAutosync'] ?? false,
        noDownsizeOnError: map['noDownsizeOnError'] ?? false,
        noKeyRepeat: map['noKeyRepeat'] ?? false,
        noMipmaps: map['noMipmaps'] ?? false,
        noMouseHover: map['noMouseHover'] ?? false,
        noPowerOn: map['noPowerOn'] ?? false,
        noVdDestroyContent: map['noVdDestroyContent'] ?? false,
        noVdSystemDecorations: map['noVdSystemDecorations'] ?? false,
        legacyPaste: map['legacyPaste'] ?? false,
        preferText: map['preferText'] ?? false,
        rawKeyEvents: map['rawKeyEvents'] ?? false,
        printFps: map['printFps'] ?? false,
        pauseOnExit: map['pauseOnExit'] ?? '',
        timeLimit: map['timeLimit'] ?? '',
        screenOffTimeout: map['screenOffTimeout'] ?? '',
        shortcutMod: map['shortcutMod'] ?? '',
        startApp: map['startApp'] ?? '',
        verbosity: map['verbosity'] ?? '',
        renderDriver: map['renderDriver'] ?? '',
        v4l2Sink: map['v4l2Sink'] ?? '',
        v4l2Buffer: map['v4l2Buffer'] ?? '',
      );

  static List<ScrcpyProfile> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    final List<dynamic> list = List<dynamic>.from(
      (jsonDecode(json) as List<dynamic>),
    );
    return list.map((e) => ScrcpyProfile.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  static String encodeList(List<ScrcpyProfile> profiles) {
    return jsonEncode(profiles.map((e) => e.toMap()).toList());
  }
}
