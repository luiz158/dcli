/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:path/path.dart';
import 'package:scope/scope.dart';

import '../../dcli.dart';
import '../commands/install.dart';
import '../shell/shell_detection.dart';
import '../version/version.g.dart';

///
/// Installs dart on an apt base system.abstract
///

class LinuxDCliInstaller {
  /// returns true if it needed to install dart.
  bool install({required bool installDart}) {
    var installedDart = false;

    if (installDart) {
      installedDart = _installDart();
    }

    // now activate dcli.
    if (Scope.hasScopeKey(InstallCommand.activateFromSourceKey) &&
        Scope.use(InstallCommand.activateFromSourceKey) == true) {
      // If we are called from a unit test we do it from source
      PubCache().globalActivateFromSource(DartProject.self.pathToProjectRoot);
    } else {
      /// activate from pub.dev
      PubCache().globalActivate('dcli', version: packageVersion);
    }
    // // also need to install it for the root user
    // // as root must have its own copy of .pub-cache otherwise
    // // if it updates .pub-cache of a user the user won't be able
    // // to use pub-get any more.
    // '/usr/lib/dart/bin/pub global activate dcli'.run;

    return installedDart;
  }

  bool _installDart() {
    var installedDart = false;
    // first check that dart isn't already installed
    if (which('dart').notfound) {
      print('Installing Dart');

      var pathUpdated = false;
      // add dart to bash path
      if (!(isOnPATH('/usr/bin/dart') || isOnPATH('/usr/lib/dart/bin'))) {
        final shell = ShellDetection().identifyShell();
        verbose(() => 'Found shell: $shell');

        // we need to add it.
        join(HOME, '.bashrc')
          ..append(r'''export PATH="$PATH":"/usr/lib/dart/bin"''')
          ..append('''export PATH="\$PATH":"${PubCache().pathToBin}"''')
          ..append('''export PATH="\$PATH":"${Settings().pathToDCliBin}"''');

        if (shell.loggedInUser != 'root') {
          // add dart to root path.
          // The tricks we have to play to get dart on the root users path.
          r'echo export PATH="$PATH":/usr/lib/dart/bin | sudo tee -a /root/.bashrc'
              .run;
          // give root its own pub-cache
          r'echo export PATH="$PATH":/root/.pub-cache/bin | sudo tee -a /root/.bashrc'
              .run;
          pathUpdated = true;
        }
      }

      final dartInstallDir =
          DartSdk().installFromArchive('/usr/lib/dart', askUser: false);
      print('Installed Dart to: $dartInstallDir');

      if (pathUpdated) {
        print('You will need to restart your shell for dart to be available');
      }

      installedDart = true;
    } else {
      // dart is already installed.

      verbose(
        () => "Found dart at: ${which('dart').path ?? "<not found>"} "
            'and as such will not install dart.',
      );
    }

    return installedDart;
  }

  /// Installs dart from the apt repos.
  void installDartWithApt() {
    Shell.current.withPrivileges(() {
      'apt update'.run;
      'apt install apt-transport-https'.run;

      "sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'"
          .run;

      "sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'"
          .run;
      'apt update'.run;
      'apt install dart'.run;
    });
  }
}
