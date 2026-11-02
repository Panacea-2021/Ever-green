import 'dart:math';

/// No look-alike characters (0/O, 1/l/I) so the password is easy to read
/// out or type from an email.
const _letters = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
const _digits = '23456789';
const _symbols = '@#\$%&*!';

/// A random [length]-character password (backend allows 6–20) with at least
/// one digit and one symbol, used to pre-fill onboarding forms.
String generatePassword({int length = 10, Random? random}) {
  final rng = random ?? Random.secure();
  String pick(String from) => from[rng.nextInt(from.length)];
  final all = _letters + _digits + _symbols;
  final chars = [
    pick(_letters),
    pick(_digits),
    pick(_symbols),
    for (var i = 3; i < length; i++) pick(all),
  ]..shuffle(rng);
  return chars.join();
}
