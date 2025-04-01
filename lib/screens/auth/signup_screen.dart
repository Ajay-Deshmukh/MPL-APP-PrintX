import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'dart:math';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  bool _isCaptchaVerified = false;
  String _captchaText = '';

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    _captchaText = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    setState(() {});
  }

  bool _isValidVesEmail(String email) {
    return email.endsWith('@ves.ac.in');
  }

  void _verifyCaptcha() {
    if (_captchaController.text.toUpperCase() == _captchaText) {
      setState(() => _isCaptchaVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CAPTCHA verified successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid CAPTCHA. Please try again.')),
      );
      _generateCaptcha();
      _captchaController.clear();
    }
  }

  void _signUp(BuildContext context) async {
    if (!_isValidVesEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please use your VES email (@ves.ac.in)')),
      );
      return;
    }

    if (!_isCaptchaVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please verify CAPTCHA first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signUp(
      _nameController.text, 
      _emailController.text, 
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);

    if (authProvider.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Successful! Please log in.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed! Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                helperText: 'Use your VES email (@ves.ac.in)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (!_isCaptchaVerified)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _captchaText,
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Courier',
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: _generateCaptcha,
                        ),
                      ],
                    ),
                    TextField(
                      controller: _captchaController,
                      decoration: InputDecoration(
                        labelText: 'Enter CAPTCHA',
                        helperText: 'Case sensitive',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _verifyCaptcha,
                      child: Text('Verify CAPTCHA'),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isCaptchaVerified ? () => _signUp(context) : null,
                    child: Text('Sign Up'),
                  ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              ),
              child: Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }
}
