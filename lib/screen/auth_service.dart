import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String email = '';
  String password = '';
  bool isSignUp = true;

  Future<void> _submitAuthForm() async {
    try {
      UserCredential userCredential;
      if (isSignUp) {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      //      // Store user data in Firestore after sign-up
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userCredential.user!.uid)
      //     .set({
      //   'email': email,
      //   'createdAt': Timestamp.now(),
      //    });
      } else {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      }

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isSignUp ? 'Sign Up' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => email = value,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              onChanged: (value) => password = value,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitAuthForm,
              child: Text(isSignUp ? 'Sign Up' : 'Login'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isSignUp = !isSignUp;
                });
              },
              child: Text(isSignUp ? 'Already have an account? Login' : 'Create new account'),
            ),
          ],
        ),
      ),
    );
  }
}
