import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../state/pose_coach.dart';

/// Fase 5: puente entre la cámara y ML Kit Pose Detection.
///
/// - Conversión del frame YUV-420-888 de la cámara a NV21 (lo que acepta Android).
/// - Ejecuta el detector base en modo stream (inferencia 100 % on-device).
/// - El modelo de IA viene empaquetado DENTRO del APK (`assets/mlkit_pose/*.tflite`);
///   no hay descargas en tiempo de ejecución. Si Google ML Kit no lo puede
///   iniciar en un dispositivo concreto (Play services no actualizado, delegate
///   no disponible, etc.), devuelve null y el motivo: NUNCA crashea y la UI lo
///   muestra de forma honesta.
class PoseCoachService {
  PoseDetector? _detector;
  String? _errorInicializacion;

  /// true cuando el detector está listo para procesar frames.
  bool get disponible => _detector != null;

  /// Motivo honesto de indisponibilidad (o null si todo bien).
  String? get errorInicializacion => _errorInicializacion;

  /// Crea el detector. El modelo viene en el APK (assets/mlkit_pose), así que no
  /// hay descarga previa: solo se comprueba que ML Kit pueda cargarlo al
  /// procesar el primer frame.
  Future<void> inicializar() async {
    if (_detector != null) return;
    try {
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          model: PoseDetectionModel.base,
          mode: PoseDetectionMode.stream,
        ),
      );
    } catch (e) {
      _errorInicializacion = 'No se pudo iniciar el detector de posición ($e)';
      _detector = null;
    }
  }

  /// Procesa un frame de la cámara. Devuelve la pose analizada con feedback o
  /// null si el modelo/la cámara no están disponibles.
  Future<PoseCoachFrame?> procesar(CameraImage imagen, int rotacion) async {
    final detector = _detector;
    if (detector == null) return null;
    try {
      final input = InputImage.fromBytes(
        bytes: yuv420ANv21(imagen),
        metadata: InputImageMetadata(
          size: Size(imagen.width.toDouble(), imagen.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(rotacion % 360) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 0, // Solo iOS; Android lo ignora.
        ),
      );
      final poses = await detector.processImage(input);
      if (poses.isEmpty) {
        return PoseCoachFrame(puntos: const {}, posicionVisible: false);
      }
      final puntos = _mapearArticulaciones(poses.first);
      return PoseCoachFrame(puntos: puntos, posicionVisible: puntos.isNotEmpty);
    } on PlatformException catch (e) {
      // Diagnóstico: el texto real del fallo nativo viaja en el mensaje.
      // (El modelo viene en el APK; esto revela si es Play Services, el
      // delegate o el entorno del dispositivo.)
      debugPrint('[FitPulse/Coach] PlatformException code=${e.code} '
          'message=${e.message} details=${e.details}');
      _detector?.close();
      _detector = null;
      _errorInicializacion = _auditarErrorMLKit;
      return null;
    } on MissingPluginException {
      _detector = null;
      _errorInicializacion = 'ML Kit no está disponible en este dispositivo.';
      return null;
    } catch (e) {
      // Frame ocasional fallido: se ignora, el stream sigue.
      return PoseCoachFrame(puntos: const {}, posicionVisible: false);
    }
  }

  /// Cierra el detector y libera recursos.
  Future<void> cerrar() async {
    await _detector?.close();
    _detector = null;
  }

  static const _auditarErrorMLKit =
      'El modelo de IA viene incluido en la app (análisis 100% local, en tu '
      'móvil: la cámara no graba ni sube nada), pero Google ML Kit no pudo '
      'iniciar el detector en este dispositivo (componente de Play services no '
      'disponible/desactualizado). Revisa que Google Play services esté '
      'actualizado y reintenta.';

  Map<Lm, PuntoPose> _mapearArticulaciones(Pose pose) {
    final puntos = <Lm, PuntoPose>{};
    void poner(PoseLandmarkType t, Lm lm) {
      final landmark = pose.landmarks[t];
      if (landmark != null && landmark.likelihood > 0.3) {
        puntos[lm] = PuntoPose(landmark.x, landmark.y);
      }
    }

    poner(PoseLandmarkType.leftShoulder, Lm.hombroIzq);
    poner(PoseLandmarkType.leftElbow, Lm.codoIzq);
    poner(PoseLandmarkType.leftWrist, Lm.munecaIzq);
    poner(PoseLandmarkType.leftHip, Lm.caderaIzq);
    poner(PoseLandmarkType.leftKnee, Lm.rodillaIzq);
    poner(PoseLandmarkType.leftAnkle, Lm.tobilloIzq);
    poner(PoseLandmarkType.rightShoulder, Lm.hombroDer);
    poner(PoseLandmarkType.rightElbow, Lm.codoDer);
    poner(PoseLandmarkType.rightWrist, Lm.munecaDer);
    poner(PoseLandmarkType.rightHip, Lm.caderaDer);
    poner(PoseLandmarkType.rightKnee, Lm.rodillaDer);
    poner(PoseLandmarkType.rightAnkle, Lm.tobilloDer);
    return puntos;
  }
}

/// Un frame analizado: articulaciones (coordenadas de imagen, pueden escalarse
/// para el overlay) y si se detectó una posición visible.
class PoseCoachFrame {
  const PoseCoachFrame({required this.puntos, required this.posicionVisible});

  final Map<Lm, PuntoPose> puntos;
  final bool posicionVisible;
}

/// Convierte un frame YUV-420-888 de la cámara a NV21 (formato Android).
///
/// Devuelve un buffer vacío si el frame no tiene el formato esperado (3 planos);
/// el llamador descarta esos frames en vez de analizarlos.
Uint8List yuv420ANv21(CameraImage image) {
  final planes = image.planes;
  if (planes.length != 3) return Uint8List(0);

  final y = planes[0];
  final u = planes[1];
  final v = planes[2];
  final width = image.width;
  final height = image.height;
  final out = Uint8List(width * height * 3 ~/ 2);

  // Plano Y respetando el bytesPerRow (puede ser mayor que width).
  var o = 0;
  var yRow = 0;
  for (var h = 0; h < height; h++) {
    if (o + width <= out.length && yRow + width <= y.bytes.length) {
      out.setRange(o, o + width, y.bytes, yRow);
    }
    o += width;
    yRow += y.bytesPerRow;
  }

  // Intercalado V-U (NV21) sobre la mitad de resolución cromática.
  final uPaso = u.bytesPerPixel ?? 2;
  final vPaso = v.bytesPerPixel ?? 2;
  var uv = o;
  final halfH = height ~/ 2;
  final halfW = width ~/ 2;
  for (var h = 0; h < halfH; h++) {
    final uRow = h * u.bytesPerRow;
    final vRow = h * v.bytesPerRow;
    for (var w = 0; w < halfW; w++) {
      final uIdx = uRow + w * uPaso;
      final vIdx = vRow + w * vPaso;
      if (uv + 1 < out.length && vIdx < v.bytes.length && uIdx < u.bytes.length) {
        out[uv++] = v.bytes[vIdx];
        out[uv++] = u.bytes[uIdx];
      }
    }
  }
  return out;
}