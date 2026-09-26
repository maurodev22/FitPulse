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

  /// Restablece el idioma por defecto tras un borrado total (art. 17 GDPR).
  void resetTrasBorrado() {
    _locale = AppLocale.es;
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

  // ---- Valores de datos (meta, sexo, cuerpo, nivel, IMC, categorías) ----
  // Los valores persistidos siguen en español; estos mapeos traducen SOLO la
  // visualización (la selección y el guardado conservan el valor original).
  String metaName(String es) => switch (es) {
        'Bajar de peso' => _t('Bajar de peso', 'Lose weight'),
        'Definir' => _t('Definir', 'Define'),
        'Aumentar de peso' => _t('Aumentar de peso', 'Gain weight'),
        'Mantener' => _t('Mantener', 'Maintain'),
        _ => es,
      };
  String sexoName(String es) => switch (es) {
        'Femenino' => _t('Femenino', 'Female'),
        'Masculino' => _t('Masculino', 'Male'),
        'Otro' => _t('Otro', 'Other'),
        _ => es,
      };
  String tipoCuerpoName(String es) => switch (es) {
        'Ectomorfo' => _t('Ectomorfo', 'Ectomorph'),
        'Mesomorfo' => _t('Mesomorfo', 'Mesomorph'),
        'Endomorfo' => _t('Endomorfo', 'Endomorph'),
        _ => es,
      };
  String nivelName(String es) => switch (es) {
        'Principiante' => _t('Principiante', 'Beginner'),
        'Intermedio' => _t('Intermedio', 'Intermediate'),
        'Avanzado' => _t('Avanzado', 'Advanced'),
        _ => es,
      };
  String imcNombre(String es) => switch (es) {
        'Bajo peso' => _t('Bajo peso', 'Underweight'),
        'Rango normal y saludable' => _t('Rango normal y saludable', 'Normal and healthy range'),
        'Sobrepeso' => _t('Sobrepeso', 'Overweight'),
        'Obesidad' => _t('Obesidad', 'Obesity'),
        _ => es,
      };
  String recetaCategoria(String es) => switch (es) {
        'Todas' => _t('Todas', 'All'),
        'Alta Proteína' => _t('Alta Proteína', 'High Protein'),
        'Low Carb' => _t('Low Carb', 'Low Carb'),
        'Pre-entreno' => _t('Pre-entreno', 'Pre-workout'),
        'Smoothies' => _t('Smoothies', 'Smoothies'),
        _ => es,
      };
  String tipsCategoria(String es) => switch (es) {
        'Todos' => _t('Todos', 'All'),
        'Nutrición' => _t('Nutrición', 'Nutrition'),
        'Recuperación' => _t('Recuperación', 'Recovery'),
        'Técnica' => _t('Técnica', 'Technique'),
        'Mentalidad' => _t('Mentalidad', 'Mindset'),
        _ => es,
      };
  String diaNombre(String es) => switch (es) {
        'Lunes' => _t('Lunes', 'Monday'),
        'Martes' => _t('Martes', 'Tuesday'),
        'Miércoles' => _t('Miércoles', 'Wednesday'),
        'Jueves' => _t('Jueves', 'Thursday'),
        'Viernes' => _t('Viernes', 'Friday'),
        'Sábado' => _t('Sábado', 'Saturday'),
        'Domingo' => _t('Domingo', 'Sunday'),
        _ => es,
      };
  List<String> get diasIniciales => _locale == AppLocale.es
      ? const ['L', 'M', 'X', 'J', 'V', 'S', 'D']
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  /// Inicial pintada de un día de entrenamiento. El VALOR guardado/seleccionado
  /// sigue siendo la inicial en español ('L', 'M', 'X', 'J', 'V', 'S', 'D').
  String diaInicial(String es) => switch (es) {
        'L' => _t('L', 'M'),
        'M' => _t('M', 'T'),
        'X' => _t('X', 'W'),
        'J' => _t('J', 'T'),
        'V' => _t('V', 'F'),
        'S' => _t('S', 'S'),
        'D' => _t('D', 'S'),
        _ => es,
      };
  /// Nombre del entrenamiento favorito. El valor persistido sigue en español.
  String favoritoName(String es) => switch (es) {
        'HIIT' => _t('HIIT', 'HIIT'),
        'Fuerza funcional' => _t('Fuerza funcional', 'Functional strength'),
        'Running' => _t('Running', 'Running'),
        _ => es,
      };
  String rachaDias(int n) => _t('$n días', '$n-day streak');
  String get listoParaEntrenar => _t('Listo para entrenar', 'Ready to train');
  String get deTuPerfil => _t('De tu perfil', 'From your profile');
  String get healthConnect => _t('Health Connect', 'Health Connect');
  String get requiereHealthConnect => _t('Requiere Health Connect', 'Requires Health Connect');

  // ---- Home ----
  String get homeResumenHoy => _t('Resumen de hoy', 'Today overview');
  String get homeVerDetalles => _t('Ver detalles', 'View details');
  String get homeCalorias => _t('Calorías', 'Calories');
  String get homePulso => _t('Pulso', 'Heart rate');
  String homeMetaKcal(int kcal) => _t('Meta: $kcal kcal', 'Goal: $kcal kcal');
  String get homeUltimaLectura => _t('Última lectura de hoy', 'Latest reading today');
  String get homeSinLectura => _t('Sin lectura de hoy', 'No reading today');
  String get homeConectaHealth => _t('Conecta Health Connect', 'Connect Health Connect');
  String get homeOrientativo =>
      _t('Solo orientativo · consulta a un médico antes de cambiar tu rutina',
          'For guidance only · consult a doctor before changing your routine');
  String get homeEntrenamientoHoy => _t('Entrenamiento de hoy', "Today's workout");
  String get homeSugerido => _t('Sugerido', 'Suggested');
  String homeHola(String nombre) => _t('Hola, $nombre', 'Hi, $nombre');
  String get homeListo => _t('¿Listo para superar tus límites hoy?', 'Ready to push your limits today?');
  String get homePasos => _t('Pasos', 'Steps');
  String get homeActivaPermiso =>
      _t('Activa el permiso de actividad en los ajustes del teléfono',
          'Enable the activity permission in your phone settings');
  String homeRecomendado(String duracion, String intensidad) => _t(
      'RECOMENDADO PARA TI • $duracion • INTENSIDAD $intensidad',
      'RECOMMENDED FOR YOU • $duracion • INTENSITY $intensidad');
  String get homeComenzar => _t('Comenzar entrenamiento', 'Start workout');
  String get homeDiaIdeal => _t('DÍA IDEAL', 'IDEAL DAY');
  String homeCompletados(int n) => _t('$n/3 completados', '$n/3 completed');
  String get homeCompletaObjetivos =>
      _t('Completa los 3 objetivos de hoy para un día perfecto.',
          'Complete today\'s 3 goals for a perfect day.');
  String get homeEntrenamiento => _t('Entrenamiento', 'Workout');
  String get homeMacros => _t('Macros', 'Macros');
  String get homeAgua => _t('Agua', 'Water');
  String homeObjetivoAgua(String litros) => _t('Objetivo: $litros L', 'Goal: $litros L');
  String get homePendiente => _t('Pendiente', 'Pending');

  // ---- Recetas ----
  String get recHeader => _t('Recetas', 'Recipes');
  String get recBuscar =>
      _t('Buscar ingredientes, calorías o platos...',
          'Search ingredients, calories or dishes...');
  String get recPlanSemanal => _t('Plan semanal de comidas', 'Weekly meal plan');
  String recPlanSemanalDesc(int kcal) => _t(
      'Según tu meta ($kcal kcal/día) + lista de la compra. Día libre el domingo 🍕',
      'Based on your goal ($kcal kcal/day) + shopping list. Free day on Sunday 🍕');
  String get recBalanceHoy => _t('BALANCE NUTRICIONAL DE HOY', "TODAY'S NUTRITION BALANCE");
  String recPorciento(int pct) => _t('$pct% completado', '$pct% completed');
  String get recProteinas => _t('Proteínas', 'Protein');
  String get recCarbos => _t('Carbos', 'Carbs');
  String get recGrasas => _t('Grasas', 'Fats');
  String get recRecomendadaDefinir => _t('Recomendada para Definir', 'Recommended to Define');
  String get recVerPlan => _t('Ver plan', 'View plan');
  String recMin(int m) => _t('$m min', '$m min');
  String recKcal(int kcal) => _t('$kcal kcal', '$kcal kcal');
  String recKcalProt(int kcal, double g) =>
      _t('$kcal kcal • ${g.round()}g Prot', '$kcal kcal • ${g.round()}g Protein');
  String recProtTag(double g) => _t('💪 ${g.round()}g Prot', '💪 ${g.round()}g Protein');
  String recGrasasTag(double g) => _t('🥑 ${g.round()}g Grasas', '🥑 ${g.round()}g Fats');
  String recCarbTag(double g) => _t('🌾 ${g.round()}g Carb', '🌾 ${g.round()}g Carbs');
  String get recRegistrarBalance => _t('Registrar en mi balance', 'Log to my balance');
  String recRegistrada(String nombre, int kcal) =>
      _t('$nombre registrada (+$kcal kcal)', '$nombre logged (+$kcal kcal)');
  String get recRegistrar => _t('Registrar', 'Log');
  String get recOpcionesRapidas => _t('Opciones Rápidas', 'Quick Options');
  String get recVerTodas => _t('Ver todas', 'See all');
  String get recTodosLosPlatos => _t('Todos los platos', 'All dishes');
  String get recBuscarCatalogo => _t('Buscar en el catálogo...', 'Search the catalog...');
  String get recSinResultados => _t('Sin resultados para tu búsqueda', 'No results for your search');

  // ---- Plan de comidas ----
  String get mpTabPlan => _t('Plan semanal', 'Weekly plan');
  String get mpTabLista => _t('Lista de la compra', 'Shopping list');
  String mpTuMeta(int kcal) => _t('Tu meta: $kcal kcal/día', 'Your goal: $kcal kcal/day');
  String mpBaseDesc(int kcal) => _t(
      'El plan base aporta $kcal kcal/día de promedio calculadas de las recetas reales. '
      'Ajusta el tamaño de las raciones para alcanzar tu meta.',
      'The base plan provides an average of $kcal kcal/day calculated from real recipes. '
      'Adjust portion sizes to reach your goal.');
  String get mpDomingoLibre => _t(
      'Domingo = día libre planificado 🍕 · no penaliza tu racha de sesiones.',
      'Sunday = planned free day 🍕 · it does not penalize your session streak.');
  String get mpTodasReales => _t(
      'Todas las comidas son recetas reales del catálogo nutricional. '
      'Los totales son la suma exacta de sus valores; nada está inventado.',
      'All meals are real recipes from the nutrition catalog. '
      'Totals are the exact sum of their values; nothing is invented.');
  String get mpDiaLibre => _t('Día libre 🍕', 'Free day 🍕');
  String get mpDesayuno => _t('Desayuno', 'Breakfast');
  String get mpAlmuerzo => _t('Almuerzo', 'Lunch');
  String get mpCena => _t('Cena', 'Dinner');
  String get mpPreEntreno => _t('Pre-entreno', 'Pre-workout');
  String get mpRecarga => _t('Recarga', 'Refuel');
  String mpIngredientes(int n) => _t(
      '$n ingredientes para toda la semana (cantidades por ración en cada receta).',
      '$n ingredients for the whole week (amounts per serving in each recipe).');

  // ---- Progreso ----
  String get prEvolucion => _t('Evolución & Rendimiento', 'Evolution & Performance');
  String prRachaNivel(int racha, int nivel) =>
      _t('Racha actual: $racha días · Nivel $nivel',
          'Current streak: $racha days · Level $nivel');
  String get prRegistraPrimero =>
      _t('Registra tu primer entrenamiento para ver datos reales',
          'Log your first workout to see real data');
  String get prGrasa => _t('Grasa Corporal', 'Body Fat');
  String get prImcIndex => _t('Índice IMC', 'BMI Index');
  String get prGastoActivo => _t('Gasto Activo', 'Active Burn');
  String get prTiempoActivo => _t('Tiempo Activo', 'Active Time');
  String get prSinDatosHoy => _t('Sin datos de hoy', 'No data today');
  String get prConcedePermiso => _t('Concede el permiso', 'Grant the permission');
  String get prSoloIOS => _t('Solo iOS · en Android no hay dato', 'iOS only · no data on Android');
  String get prFuente1 => _t(
      'Grasa y gasto activo vienen de Health Connect. Instala la app de Google '
      'para desbloquearlos (nunca mostramos datos inventados).',
      'Body fat and active burn come from Health Connect. Install Google\'s app '
      'to unlock them (we never show invented data).');
  String get prFuente2 => _t(
      'Concede los permisos en Health Connect para ver grasa y gasto activo reales.',
      'Grant permissions in Health Connect to see real body fat and active burn.');
  String prFuente3(String lista) =>
      _t('Métricas de hoy vía Health Connect: $lista.',
          'Today\'s metrics via Health Connect: $lista.');
  String get prPesoCorporal => _t('Peso Corporal', 'Body Weight');
  String get prRegistraPeso => _t('Registra tu peso cada semana', 'Log your weight every week');
  String get prRetoActual => _t('Reto actual', 'Current challenge');
  String get prCompletado => _t('¡Completado!', 'Completed!');
  String prRetoDias(int p, int o) => _t('$p/$o días', '$p/$o days');
  String prRetoCompletado(int o, int s) => _t(
      'Conseguiste $o días seguidos. Sigue para el reto de $s días (+100 pts).',
      'You reached $o consecutive days. Keep going for the $s-day challenge (+100 pts).');
  String prRetoActivo(int o) =>
      _t('Entrena $o días seguidos y gana +100 pts extra.',
          'Train $o consecutive days and earn +100 bonus pts.');
  String prNivel(int n, String nombreEs) =>
      _t('Nivel $n · $nombreEs', 'Level $n · ${nivelName(nombreEs)}');
  String prPts(int xp) => _t('$xp pts', '$xp pts');
  String prPtsParaNivel(int restantes, int siguiente) => _t(
      '+50 pts por sesión completada · $restantes pts para nivel $siguiente',
      '+50 pts per completed session · $restantes pts to level $siguiente');
  String get prAnuncioRecompensado => _t('Anuncio recompensado', 'Rewarded ad');
  String prPTs(int pts) => _t('+$pts PTs', '+$pts PTs');
  String get prAnuncioGana =>
      _t('Gana puntos extra viendo un anuncio (una vez por día).',
          'Earn bonus points by watching an ad (once per day).');
  String get prAnuncioRecibida =>
      _t('Recompensa de hoy recibida. Vuelve mañana por más. 👏',
          'Today\'s reward received. Come back tomorrow for more. 👏');
  String get prVerAnuncio => _t('Ver anuncio y ganar +25', 'Watch ad and earn +25');
  String get prRecibidoHoy => _t('Recibido hoy', 'Received today');
  String prPTsGanados(int pts) => _t('¡+$pts PTs ganados!', 'You earned +$pts PTs!');
  String get prRecompensaYaRecibida => _t('Recompensa de hoy ya recibida.', 'Today\'s reward already received.');
  String get prSemana => _t('Semana de entrenamiento', 'Training week');
  String prSemanaDias(int e, int t) => _t('$e/$t días', '$e/$t days');
  String prMinSemana(int m) => _t('$m min entrenados esta semana', '$m min trained this week');
  String get prSinSesionesSemana => _t('Sin sesiones registradas esta semana', 'No sessions logged this week');
  String get prSesionesRecientes => _t('Sesiones Recientes', 'Recent Sessions');
  String get prVerTodo => _t('Ver todo', 'See all');
  String get prSinSesiones => _t('Aún no hay sesiones registradas', 'No sessions logged yet');
  String get prSinSesionesHint =>
      _t('Completa tu primer entrenamiento desde Inicio para registrarlo aquí.',
          'Complete your first workout from Home to log it here.');
  String get prInsignias => _t('Insignias & Logros', 'Badges & Achievements');
  String get prPrimeraSesion => _t('Primera Sesión', 'First Session');
  String get prCompletada => _t('Completada', 'Completed');
  String get prRacha3 => _t('Racha 3 Días', '3-Day Streak');
  String get prConstancia => _t('Constancia', 'Consistency');
  String get prRacha7 => _t('Racha 7 Días', '7-Day Streak');
  String get prDisciplina => _t('Disciplina', 'Discipline');
  String prInsigniaNivel(int n) => _t('Nivel $n', 'Level $n');
  String prInsigniaReto(int n) => _t('Reto $n Días', '$n-Day Challenge');
  String get prDesbloqueaInsignias =>
      _t('Completa tu primer entrenamiento para desbloquear insignias',
          'Complete your first workout to unlock badges');
  String get prDiaCompletado => _t('¡Día completado!', 'Day completed!');
  String get prPeriodoSemanal => _t('Semanal', 'Weekly');
  String get prPeriodoMensual => _t('Mensual', 'Monthly');
  String get prPeriodoAno => _t('Año', 'Year');
  String get prHoy => _t('Hoy', 'Today');
  String get prAyer => _t('Ayer', 'Yesterday');
  String prHaceDias(int n) => _t('Hace $n días', '$n days ago');

  // ---- Consejos ----
  String get tipsPlanPersonalizado => _t('Plan Personalizado', 'Personalized Plan');
  String tipsTuMetaDe(String metas) => _t('tu meta de $metas', 'your $metas goal');
  String get tipsConsejosBienestar => _t('Consejos & Bienestar', 'Tips & Wellness');
  String tipsRecomendaciones(String metasPart) => metasPart.isEmpty
      ? _t('Recomendaciones para ti', 'Recommendations for you')
      : _t('Recomendaciones $metasPart para ti', 'Recommendations $metasPart for you');
  String get tipsBuscar => _t('Buscar consejos...', 'Search tips...');
  String get tipsHoyRecuperacion => _t('HOY • RECUPERACIÓN', 'TODAY • RECOVERY');
  String tipsMin(int m) => _t('$m min', '$m min');
  String get tipsArticulo1Titulo =>
      _t('La importancia de los descansos activos para no perder masa muscular',
          'The importance of active rest to avoid losing muscle mass');
  String get tipsArticulo1Cuerpo => _t(
      'Caminar ligero o realizar estiramientos dinámicos en tus días libres '
      'promueve la eliminación de lactato y acelera la síntesis proteica sin fatiga adicional.',
      'Walking lightly or doing dynamic stretches on your rest days promotes '
      'lactate clearance and speeds up protein synthesis without extra fatigue.');
  String get tipsLeerArticulo => _t('Leer artículo completo', 'Read full article');
  String get tipsAltoImpacto => _t('Tips de Alto Impacto', 'High-Impact Tips');
  String get tipsDesliza => _t('Desliza para ver más', 'Swipe for more');
  String get tipsTip1Titulo => _t('Hidratación Óptima', 'Optimal Hydration');
  String get tipsTip1Sub => _t('Pre-entreno', 'Pre-workout');
  String get tipsTip1Desc => _t(
      'Bebe 500ml de agua 30 min antes de entrenar para mantener la volemia y potencia muscular.',
      'Drink 500ml of water 30 min before training to maintain blood volume and muscle power.');
  String get tipsTip2Titulo => _t('Ventana Anabólica', 'Anabolic Window');
  String get tipsTip2Sub => _t('Post-HIIT', 'Post-HIIT');
  String get tipsTip2Desc => _t(
      'Consume 25-30g de proteína de rápida asimilación tras tus sesiones HIIT para frenar el catabolismo.',
      'Have 25-30g of fast-absorbing protein after your HIIT sessions to curb catabolism.');
  String get tipsTip3Titulo => _t('Sueño Profundo', 'Deep Sleep');
  String get tipsTip3Sub => _t('Regeneración', 'Recovery');
  String get tipsTip3Desc => _t(
      'Garantiza 7-8 horas de reposo; la hormona de crecimiento nocturna maximiza la quema lipídica.',
      'Ensure 7-8 hours of rest; night-time growth hormone maximizes fat burning.');
  String get tipsArticulosRecomendados => _t('Artículos Recomendados', 'Recommended Articles');
  String tipsVerTodos(int n) => _t('Ver todos ($n)', 'See all ($n)');
  String get tipsArt1Titulo =>
      _t('5 Errores comunes al calcular tu déficit calórico',
          '5 Common mistakes when calculating your calorie deficit');
  String get tipsArt1Cuerpo => _t('No pesas los aceites o subestimas las salsas.',
      'You do not weigh oils or underestimate sauces.');
  String get tipsArt2Titulo =>
      _t('Cómo mejorar tu técnica de sentadilla profunda',
          'How to improve your deep squat technique');
  String get tipsArt2Cuerpo =>
      _t('Alineación del fémur, movilidad de tobillos.',
          'Femur alignment, ankle mobility.');
  String get tipsArt3Titulo =>
      _t('Respiración diafragmática para bajar el cortisol',
          'Diaphragmatic breathing to lower cortisol');
  String get tipsArt3Cuerpo =>
      _t('Técnica box-breathing de 4 tiempos.', '4-count box-breathing technique.');
  String get tipsAvisoSalud => _t(
      'Estos contenidos son orientativos y no sustituyen el consejo de un profesional de la salud.',
      'These contents are for guidance only and do not replace the advice of a health professional.');

  // ---- Perfil (resto) ----
  String get pfPremium => _t('FitPulse Premium', 'FitPulse Premium');
  String get pfPremiumActivo =>
      _t('Premium activo: los anuncios están desactivados. 🎉',
          'Premium active: ads are off. 🎉');
  String get pfPremiumQuitar =>
      _t('Quita los anuncios de por vida con una compra única.',
          'Remove ads for life with a one-time purchase.');
  String get pfAnunciosHabilitados => _t('Anuncios habilitados', 'Ads enabled');
  String get pfAnunciosSub =>
      _t('Banners y recompensados con IDs de prueba de AdMob',
          'Banners and rewarded ads with AdMob test IDs');
  String get pfDesactivarPremium =>
      _t('Desactivar Premium (modo prueba)', 'Disable Premium (test mode)');
  String get pfActivarPremium =>
      _t('Activar Premium (modo prueba)', 'Enable Premium (test mode)');
  String get pfPremiumNota => _t(
      'El cobro real requiere Google Play con una cuenta fuera de Cuba (ver PLAN.md, Fase 3). '
      'Este botón activa Premium localmente para probar que los anuncios se ocultan.',
      'Real billing requires Google Play with an account outside Cuba (see PLAN.md, Phase 3). '
      'This button enables Premium locally to test that ads are hidden.');
  String get pfMetasActividad => _t('Metas de Actividad', 'Activity Goals');
  String get pfPasosDiarios => _t('Pasos diarios', 'Daily steps');
  String get pfCaloriasActivas => _t('Calorías activas', 'Active calories');
  String get pfCardioSemanal => _t('Cardio semanal', 'Weekly cardio');
  String get pfDiasEntrenamiento => _t('Días de entrenamiento', 'Training days');
  String pfDiasSemana(int n) => _t('$n días / semana', '$n days / week');
  String get pfDatosSalud => _t('Datos de salud', 'Health data');
  String get pfInstalaHealth =>
      _t('Instala la app Google Health Connect para sincronizar',
          'Install the Google Health Connect app to sync');
  String get pfSinHealth => _t(
      'Sin Health Connect, pulso, sueño y grasa se muestran como "—" (nunca inventados).',
      'Without Health Connect, heart rate, sleep and body fat show as "—" (never invented).');
  String get pfConcediendoPermisos => _t(
      'Concediendo permisos en la pantalla de Health Connect…',
      'Granting permissions on the Health Connect screen…');
  String get pfConectado => _t('Health Connect conectado', 'Health Connect connected');
  String get pfDisponible => _t('Health Connect disponible', 'Health Connect available');
  String get pfGrasaPermiso => _t('Grasa', 'Body fat');
  String get pfSuenio => _t('Sueño', 'Sleep');
  String get pfAbrirPermisos =>
      _t('Abrir permisos de Health Connect', 'Open Health Connect permissions');
  String get pfNombreCompleto => _t('Nombre completo', 'Full name');
  String get pfNivelCondicion => _t('Nivel de condición física', 'Fitness level');
  String get pfTipoEntrenamiento => _t('Tipo de entrenamiento preferido', 'Preferred training type');
  String get pfHIIT => _t('HIIT', 'HIIT');
  String get pfFuerzaFuncional => _t('Fuerza funcional', 'Functional strength');
  String get pfRunning => _t('Running', 'Running');
  String get pfSeleccionaFavorito => _t('Selecciona tu próximo entrenamiento favorito', 'Select your next favorite workout');
  String get pfPreferencias => _t('Preferencias & Sincronización', 'Preferences & Sync');
  String get pfRecordatoriosHidratacion => _t('Recordatorios de hidratación', 'Hydration reminders');
  String get pfCadaHora => _t('Cada hora · notificación local', 'Every hour · local notification');
  String get pfAvisoRacha => _t('Aviso de racha en riesgo', 'Streak-at-risk alert');
  String get pfDiario20 => _t('Diario a las 20:00 con tu racha real', 'Daily at 8:00 PM with your real streak');
  String get pfHealthKit => _t('HealthKit / Smartwatch', 'HealthKit / Smartwatch');
  String get pfSincronizacion => _t('Sincronización en segundo plano', 'Background sync');
  String get pfVibracion => _t('Vibración háptica', 'Haptic vibration');
  String get pfAvisosIntervalo => _t('Avisos de cambio de intervalo', 'Interval change alerts');
  String get pfCompartirActividad => _t('Compartir actividad', 'Share activity');
  String get pfVisibleAmigos => _t('Visible solo para amigos seguidos', 'Visible only to followed friends');
  String get pfTemaApp => _t('Tema de la app', 'App theme');
  String get pfSeAplicaTema => _t('Se aplica al instante y queda guardado.', 'Applies instantly and is saved.');
  String get pfIdioma => _t('Idioma / Language', 'Idioma / Language');
  String get pfIdiomaEs => _t('Español', 'Spanish');
  String get pfIdiomaEn => _t('English', 'English');
  String get pfSeAplicaIdioma => _t('El idioma se aplica al instante.', 'The language applies instantly.');
  String get pfGuardarCambios => _t('Guardar cambios', 'Save changes');
  String get pfVersion => _t('FitPulse v1.0.0 (Build 1)', 'FitPulse v1.0.0 (Build 1)');
  String get pfAjustesGuardados => _t('¡Ajustes guardados en tu dispositivo!', 'Settings saved on your device!');
  String get pfMiPerfil => _t('Mi Perfil', 'My Profile');
  String get pfSuperaLimites => _t('Supera tus límites hoy', 'Push your limits today');
  String get pfConfiguracionProx => _t('Configuración general disponible próximamente', 'General settings coming soon');
  String get pfFotoGuardada => _t('Foto de perfil actualizada', 'Profile photo updated');
  String get pfErrorFoto => _t('No se pudo cargar la foto', 'Could not load the photo');
  String pfRachaEnRacha(int n) => _t('$n días en racha', '$n-day streak');
  String get pfPlan => _t('Plan: ', 'Plan: ');
  String get pfGrasaPct => _t('% Grasa', '% Fat');
  String get pfImc => _t('IMC', 'BMI');
  String get pfOptimo => _t('Óptimo', 'Optimal');
  String get pfAnadir => _t('Añadir', 'Add');
  String pfProgresoPasos(String pasos) =>
      _t('Progreso de hoy: $pasos pasos', 'Today\'s progress: $pasos steps');
  String get pfActivaDatos =>
      _t('Activa los datos de actividad para seguir tus pasos',
          'Enable activity data to track your steps');

  // ---- Registro (resto) ----
  String get regFotoTitulo => _t('Foto de perfil', 'Profile photo');
  String get regFotoOpcional => _t('Opcional', 'Optional');
  String get regFotoHint => _t('Añade una foto para identificarte (puedes saltar este paso)', 'Add a photo to identify yourself (you can skip this step)');
  String get regSubirImagen => _t('Subir imagen', 'Upload image');
  String get regNameHint => _t('Escribe tu nombre', 'Enter your name');
  String get regEligeMetas => _t('Elige hasta 2 metas', 'Choose up to 2 goals');
  String get regMetaLimite => _t('Máximo 2 metas seleccionadas', 'Maximum 2 goals selected');
  String get regTipoCuerpoHint =>
      _t('Ayuda a personalizar la perspectiva visual (informativo)',
          'Helps personalize the visual perspective (informational)');
  String get regSexoHint => _t('Selecciona', 'Select');
  String regImcEnVivo(double v) => _t('IMC en vivo: ${v.toStringAsFixed(1)}', 'Live BMI: ${v.toStringAsFixed(1)}');
  String get regImcEnVivoDash => _t('IMC en vivo —', 'Live BMI —');
  String get regImcGira => _t('Gira las ruedas de peso y altura', 'Spin the weight and height wheels');
  String get regImcBajo => _t('Bajo peso', 'Underweight');
  String get regImcRango => _t('Rango normal y saludable', 'Normal and healthy range');
  String get regImcSobrepeso => _t('Sobrepeso', 'Overweight');
  String get regImcObesidad => _t('Obesidad', 'Obesity');
  String get regImcBadgeBajo => _t('BAJO', 'LOW');
  String get regImcBadgeAlto => _t('ALTO', 'HIGH');
  String get regImcBadgeMuyAlto => _t('MUY ALTO', 'VERY HIGH');
  String get regCreaPerfil => _t('CREA TU PERFIL', 'CREATE YOUR PROFILE');
  String get regMetaAtLeast => _t('Selecciona al menos una meta principal', 'Select at least one main goal');
  List<String> get regSexos => const ['Femenino', 'Masculino', 'Otro'];

  // ---- Reproductor de entrenamiento ----
  String wpSesionCompletada(String nombre) =>
      _t('Sesión completada: $nombre (+50 pts)', 'Workout complete: $nombre (+50 pts)');
  String get wpDescanso => _t('DESCANSO', 'REST');
  String get wpEjercicio => _t('EJERCICIO', 'EXERCISE');
  String get wpCorregirPostura => _t('Corregir postura con cámara', 'Fix posture with camera');
  String get wpSaltar => _t('Saltar', 'Skip');
  String get wpReanudar => _t('Reanudar', 'Resume');
  String get wpPausar => _t('Pausar', 'Pause');
  String get wpTerminar => _t('Terminar sesión', 'End workout');

  // ---- Entrenador de postura ----
  String get pcEncendiendo => _t('Encendiendo la cámara…', 'Turning on the camera…');
  String get pcColocaEncuadre => _t('Coloca tu cuerpo en el encuadre', 'Place your body in the frame');
  String get pcNoModelo => _t(
      'El modelo de IA de Google no está disponible ahora (requiere Play Services '
      'y una descarga única). Sin él no se puede activar el entrenador con cámara.',
      'Google\'s AI model is not available right now (requires Play Services and '
      'a one-time download). Without it the camera coach cannot run.');
  String get pcTitulo => _t('Entrenador con cámara', 'Camera coach');
  String get pcTerminar => _t('Terminar', 'Finish');
  String get pcPermisoTitulo => _t('Permiso de cámara necesario', 'Camera permission needed');
  String get pcPermisoDetalle => _t(
      'La cámara se usa solo para analizar tu postura EN TU MÓVIL: nada se graba ni se sube. '
      'Concede el permiso y vuelve a intentarlo.',
      'The camera is only used to analyze your posture ON YOUR PHONE: nothing is '
      'recorded or uploaded. Grant the permission and try again.');
  String get pcAbrirAjustes => _t('Abrir ajustes', 'Open settings');
  String get pcSinCamaraTitulo => _t('No se encontró la cámara', 'No camera found');
  String get pcSinCamaraDetalle =>
      _t('Revisa que el dispositivo tenga una cámara disponible.',
          'Check that your device has a camera available.');
  String get pcNoDisponibleTitulo => _t('Entrenador con cámara no disponible ahora', 'Camera coach not available right now');
  String pcReps(int n) => _t('$n reps', '$n reps');
  String get pcPreparando => _t('Preparando el análisis de postura…', 'Preparing posture analysis…');
  String get pcNoActivo => _t('El entrenador con cámara no está activo.', 'The camera coach is not active.');
  // Aviso formal de IA (Ley de IA de la UE, art. 50): transparencia sobre el
  // uso de un modelo de IA en el dispositivo.
  String get pcAvisoIA => _t(
      'Este módulo usa un modelo de IA en tu dispositivo (ML Kit): el análisis es '
      'local y la cámara no graba ni sube nada.',
      'This module uses an on-device AI model (ML Kit): analysis is local and the '
      'camera records or uploads nothing.');

  // ---- EULA (Fase 8): cláusulas nuevas de la versión v2 ----
  String get eulaSection5 => _t('5. Datos de salud y edad mínima', '5. Health data and minimum age');
  String get eulaSection5Body => _t(
      'La app puede acceder a métricas de salud de tu dispositivo (pasos, pulso, '
      'peso, sueño) únicamente con tu consentimiento, que puedes revocar en '
      'cualquier momento desde los ajustes. Son datos de categoría especial '
      '(art. 9 del RGPD) y se tratan solo en tu móvil. FitPulse está pensada para '
      'mayores de 16 años; si eres menor, no uses la app sin el consentimiento de '
      'tu representante legal.',
      'The app may access health metrics from your device (steps, heart rate, '
      'weight, sleep) only with your consent, which you can revoke at any time '
      'from settings. These are special-category data (Art. 9 GDPR) processed '
      'only on your phone. FitPulse is intended for people aged 16 or older; if '
      'you are younger, do not use the app without the consent of your legal '
      'guardian.');
  String get eulaSection6 => _t('6. Publicidad, compras y comerciante', '6. Advertising, purchases and merchant');
  String get eulaSection6Body => _t(
      'La app puede mostrar publicidad de terceros; puedes desactivarla en Perfil '
      'y, si resides en la Unión Europea o el Reino Unido, se te pedirá '
      'consentimiento antes de mostrar anuncios personalizados. Las compras '
      'dentro de la app (si existieran) se gestionan a través de Google Play, que '
      'otorga el derecho de desistimiento de 14 días. Datos del comerciante: '
      'desarrollador independiente; se publicarán cuando exista una entidad '
      'legal.',
      'The app may show third-party advertising; you can disable it in Profile '
      'and, if you reside in the European Union or the United Kingdom, you will '
      'be asked for consent before personalised ads are shown. In-app purchases '
      '(if any) are handled through Google Play, which grants the 14-day '
      'withdrawal right. Merchant details: independent developer; they will be '
      'published once a legal entity exists.');

  // ---- Perfil (Fase 8): privacidad y datos ----
  String get pfPrivacidadDatos => _t('Privacidad y datos', 'Privacy & data');
  String get pfExportarDatos => _t('Exportar mis datos', 'Export my data');
  String get pfExportarDatosSub =>
      _t('Genera tu backup en JSON y compártelo donde quieras (portabilidad)',
          'Generates your JSON backup and lets you share it anywhere (portability)');
  String get pfImportarBackup => _t('Importar un backup', 'Import a backup');
  String get pfImportarBackupSub =>
      _t('Restaura tus datos desde un fichero de backup guardado',
          'Restores your data from a saved backup file');
  String get pfPoliticaPrivacidad => _t('Política de privacidad', 'Privacy policy');
  String get pfPoliticaPrivacidadSub => _t('Cómo tratamos tus datos (RGPD compatible)', 'How we handle your data (GDPR-aligned)');
  String get pfBorrarTodosLosDatos => _t('Borrar todos mis datos', 'Delete all my data');
  String get pfBorrarSub => _t('Derecho al olvido: borra todo del dispositivo', 'Right to erasure: deletes everything on this device');
  String get pfCompartirBackupTexto =>
      _t('Backup de FitPulse (JSON con tus datos).', 'FitPulse backup (JSON with your data).');
  String get pfBackupError => _t('No se pudo exportar el backup. Inténtalo de nuevo.', 'Could not export the backup. Try again.');
  String get pfSinBackups => _t('No hay backups guardados en este dispositivo.', 'No backups are saved on this device.');
  String get pfImportOk => _t('¡Backup importado! Tus datos se han restaurado.', 'Backup imported! Your data has been restored.');
  String get pfImportError => _t('El fichero no es un backup válido de FitPulse.', 'The file is not a valid FitPulse backup.');
  String get pfBorradoHecho => _t('Todos tus datos se han borrado del dispositivo.', 'All your data has been deleted from this device.');
  String get pfConfirmarBorradoTitulo => _t('¿Borrar todos tus datos?', 'Delete all your data?');
  String get pfConfirmarBorradoCuerpo => _t(
      'Esta acción elimina tu perfil, historial, balance y ajustes de este '
      'dispositivo. Es irreversible. Considera exportar un backup antes.',
      'This deletes your profile, history, balance and settings on this device. '
      'It is irreversible. Consider exporting a backup first.');
  String get pfConfirmarBorradoCuerpo2 => _t(
      'Esta es la última confirmación. Se borrará todo y volverás al inicio.',
      'This is the final confirmation. Everything will be deleted and you will '
      'return to the start.');
  String get pfCancelar => _t('Cancelar', 'Cancel');
  String get pfBorrarAhora => _t('Sí, borrar todo', 'Yes, delete everything');
  String get pfElegirBackup => _t('Elige un backup', 'Choose a backup');
  String get pfBackupVacio => _t('El backup no contiene datos.', 'The backup contains no data.');

  // ---- Política de privacidad (Fase 8) ----
  String get pvTitle => _t('Política de privacidad', 'Privacy policy');
  String get pvIntro => _t(
      'FitPulse funciona 100 % en tu dispositivo: no hay cuentas, no hay servidores '
      'y tus datos no salen del móvil salvo que tú los compartas. Esta política '
      'explica qué se guarda, por qué y qué derechos tienes (RGPD/UE).',
      'FitPulse runs 100 % on your device: no accounts, no servers, and your data '
      'never leaves your phone unless you share it. This policy explains what is '
      'stored, why, and what rights you have (GDPR/EU).');
  String get pvVigencia => _t('Vigencia: 25 de septiembre de 2026', 'Effective: 25 September 2026');
  String get pvSec1 => _t('1. Responsable y comerciante', '1. Controller and merchant');
  String get pvSec1Body => _t(
      'Responsable: desarrollador independiente de FitPulse. Cuando exista una '
      'entidad legal para publicar en Europa, aquí se publicarán su nombre, '
      'dirección y contacto (obligación de la Directiva 2011/83/UE y del '
      'Reglamento UE 2017/2394).',
      'Controller: independent developer of FitPulse. When a legal entity exists '
      'to publish in Europe, its name, address and contact will be published here '
      '(obligation under Directive 2011/83/EU and Regulation EU 2017/2394).');
  String get pvSec2 => _t('2. Qué datos se guardan', '2. What data is stored');
  String get pvSec2Body => _t(
      'Perfil del atleta (nombre, edad, sexo, peso, altura, metas), balance '
      'nutricional diario, historial de entrenamientos, puntos/rachas, recetas '
      'favoritas y ajustes. Todo se almacena localmente con shared_preferences.',
      'Athlete profile (name, age, sex, weight, height, goals), daily nutrition '
      'balance, workout history, points/streaks, favourite recipes and settings. '
      'All of it is stored locally with shared_preferences.');
  String get pvSec3 => _t('3. Qué NO se transmite', '3. What is NOT transmitted');
  String get pvSec3Body => _t(
      'Nada. FitPulse no recopila, no envía ni comparte tus datos con servidores '
      'o terceros. El único acceso a red es opcional (anuncios, si los habilitas) '
      'y nunca incluye tus datos de salud.',
      'Nothing. FitPulse does not collect, send or share your data with servers '
      'or third parties. The only network access is optional (ads, if you enable '
      'them) and never includes your health data.');
  String get pvSec4 => _t('4. Datos de salud (categoría especial)', '4. Health data (special category)');
  String get pvSec4Body => _t(
      'Si lo autorizas, la app lee métricas de salud (pasos, pulso, peso, sueño) '
      'de tu dispositivo o Health Connect. Es la base legal del consentimiento '
      '(art. 9 del RGPD): puedes conceder o revocar cada permiso en cualquier '
      'momento desde los ajustes del sistema. Estos datos solo se procesan en tu '
      'móvil.',
      'If you authorise it, the app reads health metrics (steps, heart rate, '
      'weight, sleep) from your device or Health Connect. Consent is the legal '
      'basis (Art. 9 GDPR): you can grant or revoke each permission at any time '
      'from system settings. This data is only processed on your phone.');
  String get pvSec5 => _t('5. Edad mínima', '5. Minimum age');
  String get pvSec5Body => _t(
      'Destinada a mayores de 16 años (art. 8 del RGPD). Si eres menor de 16, '
      'necesitas el consentimiento de tu representante legal para usar la app.',
      'Intended for people aged 16 or older (Art. 8 GDPR). If you are under 16, '
      'you need the consent of your legal guardian to use the app.');
  String get pvSec6 => _t('6. Tus derechos', '6. Your rights');
  String get pvSec6Body => _t(
      'Acceso (ver en pantalla), rectificación (editar tu perfil), portabilidad '
      '(Exportar mis datos, art. 20), borrado (Borrar todos mis datos, art. 17) '
      'y oposición al uso de tus datos para publicidad. En Perfil → Privacidad y '
      'datos tienes exportar, importar y borrar.',
      'Access (view on screen), rectification (edit your profile), portability '
      '(Export my data, Art. 20), erasure (Delete all my data, Art. 17) and '
      'objection to the use of your data for advertising. In Profile → Privacy & '
      'data you can export, import and delete.');
  String get pvSec7 => _t('7. Publicidad', '7. Advertising');
  String get pvSec7Body => _t(
      'Puedes desactivar los anuncios desde Perfil. Si resides en el EEE o Reino '
      'Unido, la app usa mecánicas de consentimiento para la publicidad '
      '(personalizada o no personalizada) antes de mostrar el primer anuncio.',
      'You can disable ads from the Profile. If you reside in the EEA or UK, the '
      'app uses consent mechanisms for advertising (personalised or '
      'non-personalised) before showing the first ad.');
  String get pvSec8 => _t('8. IA en tu dispositivo', '8. On-device AI');
  String get pvSec8Body => _t(
      'El entrenador con cámara usa un modelo de IA local (ML Kit de Google). El '
      'análisis ocurre en tu móvil: la cámara no graba ni sube nada (transparencia '
      'según la Ley de IA de la UE, art. 50).',
      'The camera coach uses a local AI model (Google ML Kit). Analysis happens '
      'on your phone: the camera records or uploads nothing (transparency under '
      'the EU AI Act, Art. 50).');
  String get pvSec9 => _t('9. Contacto', '9. Contact');
  String get pvSec9Body => _t(
      'Para ejercer tus derechos o resolver dudas, use la sección Ayuda de la app '
      'o los datos del comerciante cuando estén publicados.',
      'To exercise your rights or ask questions, use the Help section of the app '
      'or the merchant details once published.');

  // ---- Ayuda (encabezado) ----
  String get helpHeaderTitle => _t('Ayuda y Soporte', 'Help & Support');
  String get helpHeaderSubtitle =>
      _t('Manual de usuario y preguntas frecuentes', 'User manual and frequently asked questions');

  // ---- Consejos / reproductor (textos sin getter previo) ----
  String get tipsBasadasEn => _t('basadas en', 'based on');
  String get tipsCatFuerza => _t('Fuerza', 'Strength');
  String get tipsCatBienestar => _t('Bienestar', 'Wellness');
  String wpIntensidad(String es) => switch (es) {
        'Baja' => _t('BAJA', 'LOW'),
        'Media' => _t('MEDIA', 'MEDIUM'),
        'Alta' => _t('ALTA', 'HIGH'),
        _ => es.toUpperCase(),
      };
  String wpMin(int m) => _t('$m min', '$m min');
  /// Traduce solo la visualización de la etiqueta de repeticiones del catálogo
  /// de workouts (el dato guardado sigue en español).
  String wpRepeticiones(String es) => switch (es) {
        '3 rondas' => _t('3 rondas', '3 rounds'),
        '2 rondas' => _t('2 rondas', '2 rounds'),
        'Mantener' => _t('Mantener', 'Hold'),
        '10 por pierna' => _t('10 por pierna', '10 per leg'),
        '30 s por lado' => _t('30 s por lado', '30 s per side'),
        'Respira' => _t('Respira', 'Breathe'),
        'Suave' => _t('Suave', 'Gentle'),
        'Ritmo fácil' => _t('Ritmo fácil', 'Easy pace'),
        'Recupera' => _t('Recupera', 'Recover'),
        'Ritmo cómodo' => _t('Ritmo cómodo', 'Comfortable pace'),
        'Vuelta a la calma' => _t('Vuelta a la calma', 'Cool down'),
        'Fluido' => _t('Fluido', 'Smooth'),
        _ => es,
      };

  // ---- Progreso: nota de fuente de métricas y banner de constancia ----
  String get prMetricaGrasa => _t('grasa', 'body fat');
  String get prMetricaGastoActivo => _t('gasto activo', 'active burn');
  String get prConsistenciaTitulo => _t('¡Consistencia Imparable!', 'Unstoppable consistency!');
  String get prEmpiezaRacha => _t('Empieza tu racha', 'Start your streak');
  String prConsistenciaPct(int pct) => _t(
      'Completaste el $pct% de tu entrenamiento programado esta semana.',
      'You completed $pct% of your scheduled training this week.');
  String get prActivaRacha => _t(
      'Completa tu primer entrenamiento esta semana para activar tu racha.',
      'Complete your first workout this week to activate your streak.');
}