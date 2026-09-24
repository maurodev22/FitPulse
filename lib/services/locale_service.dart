import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas oficiales de FitPulse.
enum AppLocale { es, en }

/// Servicio de idioma de la aplicación.
///
/// Ofrece los textos es/en y permite cambiar el idioma en vivo (sin
/// reiniciar) desde la sección Perfil. La selección se persiste por
/// dispositivo.
class LocaleService extends ChangeNotifier {
  static const _localeKey = 'fitpulse_locale_v1';

  SharedPreferences? _prefs;
  AppLocale _locale = AppLocale.es;

  AppLocale get locale => _locale;
  bool get isEnglish => _locale == AppLocale.en;

  AppStrings get strings => AppStrings(_locale);

  /// Cambia de idioma en vivo y lo persiste.
  Future<void> setLocale(AppLocale next) async {
    if (next == _locale) return;
    _locale = next;
    notifyListeners();
    await _prefs?.setString(_localeKey, next.name);
  }

  /// Alterna entre es/en.
  Future<void> toggle() => setLocale(
        _locale == AppLocale.es ? AppLocale.en : AppLocale.es,
      );

  /// Carga el idioma persistido.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_localeKey);
    _locale = AppLocale.values.asNameMap()[saved] ?? AppLocale.es;
    notifyListeners();
  }
}

/// Acceso a textos oficiales es/en.
class AppStrings {
  const AppStrings(this._locale);

  final AppLocale _locale;

  String _t(String es, String en) => _locale == AppLocale.es ? es : en;

  // ---- Navegación ----
  String get navHome => _t('Inicio', 'Home');
  String get navRecipes => _t('Recetas', 'Recipes');
  String get navProgress => _t('Progreso', 'Progress');
  String get navTips => _t('Consejos', 'Tips');
  String get navProfile => _t('Perfil', 'Profile');
  String get navHelp => _t('Ayuda', 'Help');

  // ---- Onboarding / Registro ----
  String get regTitle => _t('Crea tu Perfil Atlético', 'Create Your Athletic Profile');
  String get regSubtitle =>
      _t('Para calibrar tus métricas de pulso, quema calórica y planes de entrenamiento diarios.',
          'To calibrate your heart-rate metrics, calorie burn and daily workout plans.');
  String get regNameLabel => _t('Nombre Completo', 'Full Name');
  String get regAgeLabel => _t('Edad', 'Age');
  String get regSexLabel => _t('Sexo biológico', 'Biological sex');
  String get regWeightLabel => _t('Peso', 'Weight');
  String get regHeightLabel => _t('Altura', 'Height');
  String get regMetaLabel => _t('Meta Principal', 'Main Goal');
  String get regBodyTypeLabel => _t('Tipo de cuerpo', 'Body Type');
  String get regSave => _t('Guardar y Entrar al Dashboard', 'Save and Enter Dashboard');
  String get regFooterHint =>
      _t('Podrás editar estos valores en cualquier momento desde tu Perfil.',
          'You can edit these values anytime from your Profile.');
  String get regRequired => _t('Requerido', 'Required');
  String get regYears => _t('años', 'yrs');
  String get regDontKnow => _t('No lo sé', "I don't know");
  String get regInfoBanner =>
      _t('Personaliza tu experiencia', 'Personalize your experience');
  String get regImcLabel => _t('IMC Inicial Estimado', 'Estimated Initial BMI');
  String get regImcPending =>
      _t('Ingresa tu peso y altura para estimar tu IMC.', 'Enter your weight and height to estimate your IMC.');
  String get regImcPendingBadge => _t('PENDIENTE', 'PENDING');
  String get regImcOptimal => _t('ÓPTIMO', 'OPTIMAL');
  String get regImcAttention => _t('¡ATENCIÓN!', 'ATTENTION!');

  // ---- Mensajes de validación ----
  String get errNameEmpty => _t('Escribe tu nombre completo', 'Enter your full name');
  String get errNameShort => _t('El nombre debe tener al menos 3 caracteres', 'Name must be at least 3 characters');
  String get errNameLong => _t('El nombre no puede superar 60 caracteres', 'Name cannot exceed 60 characters');
  String get errNameInvalid => _t('El nombre solo admite letras y espacios', 'Name only supports letters and spaces');
  String get errSexRequired => _t('Selecciona un sexo biológico', 'Select a biological sex');
  String get errMetaRequired => _t('Selecciona una meta principal', 'Select a main goal');

  // ---- EULA ----
  String get eulaTitle => _t('Términos y Condiciones de Uso', 'Terms and Conditions of Use');
  String get eulaIntro => _t(
      'FitPulse es una aplicación de bienestar y seguimiento de actividad física. '
      'Antes de crear tu perfil, revisa y acepta los términos de uso.',
      'FitPulse is a wellness and physical-activity tracking app. '
      'Before creating your profile, please review and accept the Terms of Use.');
  String get eulaAccept => _t('He leído y acepto los Términos y el EULA', 'I have read and accept the Terms and EULA');
  String get eulaContinue => _t('Continuar', 'Continue');
  String get eulaSection1 => _t('1. Naturaleza del servicio', '1. Nature of the service');
  String get eulaSection1Body => _t(
      'FitPulse es una herramienta de bienestar y NO constituye asesoramiento médico, '
      'nutricional ni de salud profesional. Consulta siempre a un profesional de la salud.',
      'FitPulse is a wellness tool and does NOT constitute medical, nutritional or '
      'professional health advice. Always consult a health professional.');
  String get eulaSection2 => _t('2. Datos y privacidad', '2. Data and privacy');
  String get eulaSection2Body => _t(
      'Toda tu información se almacena únicamente en tu dispositivo. FitPulse no recopila, '
      'no envía ni comparte tus datos con servidores o terceros.',
      'All your information is stored only on your device. FitPulse does not collect, '
      'send or share your data with servers or third parties.');
  String get eulaSection3 => _t('3. Uso responsable', '3. Responsible use');
  String get eulaSection3Body => _t(
      'Úsala de forma segura y responsable. Detén el ejercicio ante dolor, mareo o malestar '
      'y consulta a un profesional. No uses la app durante actividades de riesgo que '
      'requieran atención total.',
      'Use it safely and responsibly. Stop exercising if you feel pain, dizziness or '
      'discomfort and consult a professional. Do not use the app during high-risk '
      'activities that require full attention.');
  String get eulaSection4 => _t('4. Licencia', '4. License');
  String get eulaSection4Body => _t(
      'Se concede una licencia personal, no transferible, para usar la aplicación. '
      'Queda prohibida su copia, modificación o distribución sin autorización.',
      'A personal, non-transferable license is granted to use the application. '
      'Copying, modifying or distributing it without authorization is prohibited.');
  String get eulaVersionLabel => _t('Versión de términos', 'Terms version');

  // ---- Perfil ----
  String get profilePersonalData => _t('Datos Personales', 'Personal Data');
  String get profileGoal => _t('Meta', 'Goal');

  // ---- Ayuda / Help ----
  String get helpManualTitle => _t('Manual de usuario', 'User manual');
  String get helpFaqTitle => _t('Preguntas frecuentes', 'Frequently asked questions');
  String get faqDataQ => _t('¿Dónde se guardan mis datos?', 'Where is my data stored?');
  String get faqDataA => _t(
      'Todos tus datos se guardan solo en tu dispositivo. FitPulse no recopila, '
      'envía ni comparte tu información con servidores o terceros.',
      'All your data is stored only on your device. FitPulse does not collect, '
      'send or share your information with servers or third parties.');
  String get faqOfflineQ => _t('¿Funciona sin internet?', 'Does it work offline?');
  String get faqOfflineA => _t(
      'Sí. El manual, las recetas, los consejos y todo el contenido de la app '
      'están incluidos en la instalación y funcionan sin conexión.',
      'Yes. The manual, recipes, tips and all app content are bundled with the '
      'installation and work offline.');
  String get faqResetQ => _t('¿Cómo borro o reinicio la app?', 'How do I clear or reset the app?');
  String get faqResetA => _t(
      'Tus datos se conservan siempre en el dispositivo: no hay cuentas ni '
      'inicio de sesión, cada móvil guarda a su único usuario. Para una '
      'limpieza total, desinstala la app.',
      'Your data is always kept on the device: there are no accounts or login, '
      'each phone keeps its single user. For a full reset, uninstall the app.');
}