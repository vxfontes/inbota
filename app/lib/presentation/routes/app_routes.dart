class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const root = '/root/';
  static const auth = '/auth/';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const settings = '/settings/';
  static const components = '/components';
  static const settingsComponents = '/settings/components';

  // root children (full paths)
  static const rootHome = '/root/home/';
  static const rootReminders = '/root/reminders/';
  static const rootCreate = '/root/create/';
  static const rootShopping = '/root/shopping/';
  static const rootEvents = '/root/events/';

  // root children (module/child routes)
  static const home = '/home/';
  static const reminders = '/reminders/';
  static const create = '/create/';
  static const shopping = '/shopping/';
  static const events = '/events/';
}
