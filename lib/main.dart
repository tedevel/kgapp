import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'amplify_outputs.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const KgFoodJournalApp());
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([AmplifyAuthCognito(), AmplifyAPI()]);
    await Amplify.configure(amplifyConfig);
    safePrint('Amplify configured');
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify was already configured.');
  } catch (e, stackTrace) {
    safePrint('Amplify configuration failed: $e');
    safePrint(stackTrace.toString());
  }
}
