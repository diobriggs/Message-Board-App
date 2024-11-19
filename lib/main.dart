import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message Board App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Message Board App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MessageBoardListScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Log In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationScreen()),
                );
              },
              child: const Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  String _selectedRole = 'User'; // Default role
  bool _isLoading = false;
  
  final List<String> _roles = ['User', 'Moderator', 'Admin'];

  void _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user account in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Get the user ID from the newly created account
      final String uid = userCredential.user!.uid;

      // Create a new document in Firestore with additional user information
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fName': _firstNameController.text.trim(),
        'lName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'date-time': FieldValue.serverTimestamp(),
        'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      });

      // Navigate to the message board screen after successful registration
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MessageBoardListScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: _roles.map((String role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Creating Account...'),
                      ],
                    )
                  : Text('Register'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}

// Message Board List Screen
class MessageBoardListScreen extends StatefulWidget {
  @override
  _MessageBoardListScreenState createState() => _MessageBoardListScreenState();
}

class _MessageBoardListScreenState extends State<MessageBoardListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userDisplayName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDisplayName();
  }

  _fetchUserDisplayName() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userDisplayName = userDoc['first_name'] + ' ' + userDoc['last_name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Boards'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text('Menu'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                        );
                      },
                      child: Text('Profile'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                      child: Text('Settings'),
                    ),
                    SimpleDialogOption(
                      onPressed: () async {
                        await _auth.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('boards').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final boards = snapshot.data?.docs ?? [];

          if (boards.isEmpty) {
            return Center(
              child: Text('No boards available.'),
            );
          }

          return ListView.builder(
            itemCount: boards.length,
            itemBuilder: (context, index) {
              final board = boards[index];
              final title = board['title'] ?? 'No Title';
              final description = board['description'] ?? 'No Description';
              final imageUrl = board['imageUrl'] ?? '';

              return ListTile(
                leading: imageUrl.isEmpty
                    ? Icon(Icons.forum)
                    : Image.network(imageUrl),
                title: Text(title),
                subtitle: Text(description),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(boardId: board.id, boardTitle: title),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class ChatScreen extends StatefulWidget {
  final String boardId;
  final String boardTitle;

  ChatScreen({required this.boardId, required this.boardTitle});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
  }

  // Send a message with user's first and last name
  _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final user = _auth.currentUser;
    if (user != null) {
      // Fetch user's first name and last name
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String firstName = userDoc['fName'] ?? 'Unknown';
      String lastName = userDoc['lName'] ?? 'User';

      await _firestore
          .collection('boards')
          .doc(widget.boardId)
          .collection('messages')
          .add({
        'content': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'fName': firstName,
        'lName': lastName,
      });

      // Clear the message input field after sending
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardTitle),
      ),
      body: Column(
        children: [
          // Messages Display
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('boards')
                  .doc(widget.boardId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true, // Newest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final content = message['content'];
                    final timestamp = message['timestamp'] as Timestamp;
                    final firstName = message['fName'] ?? 'Unknown';
                    final lastName = message['lName'] ?? 'User';

                    // Abbreviate last name (e.g., 'Dio B.')
                    final abbreviatedName = '$firstName ${lastName.isNotEmpty ? lastName[0] + '.' : ''}';

                    return ListTile(
                      title: Text(content),
                      subtitle: Text(
                          '$abbreviatedName • ${timestamp.toDate().toLocal().toString()}'),
                    );
                  },
                );
              },
            ),
          ),
          // Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userId = '';
  String firstName = '';
  String lastName = '';
  String email = '';
  String role = '';
  String displayName = '';
  DateTime? joinDate;

  final TextEditingController _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          firstName = userDoc['fName'] ?? '';
          lastName = userDoc['lName'] ?? '';
          email = user.email ?? '';
          role = userDoc['role'] ?? 'User';
          displayName = userDoc['displayName'] ?? '';
          joinDate = userDoc['date-time']?.toDate();
          _displayNameController.text = displayName;
        });
      }
    }
  }

  // Update display name
  Future<void> _updateDisplayName() async {
    if (userId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'displayName': _displayNameController.text,
        });
        setState(() {
          displayName = _displayNameController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Display name updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('First Name: $firstName', style: TextStyle(fontSize: 18)),
            Text('Last Name: $lastName', style: TextStyle(fontSize: 18)),
            Text('Email: $email', style: TextStyle(fontSize: 18)),
            Text('Role: $role', style: TextStyle(fontSize: 18)),
            Text('Joined: ${joinDate != null ? joinDate.toString() : 'Unknown'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateDisplayName,
              child: const Text('Update Display Name'),
            ),
          ],
        ),
      ),
    );
  }
}


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  User? currentUser;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Load current user data
  Future<void> _loadCurrentUser() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      userId = currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _emailController.text = currentUser!.email ?? '';
          _firstNameController.text = userDoc['fName'] ?? '';
          _lastNameController.text = userDoc['lName'] ?? '';
        });
      }
    }
  }

  // Update user's email
  Future<void> _updateEmail() async {
    try {
      await currentUser!.updateEmail(_emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Update user's password
  Future<void> _updatePassword() async {
    try {
      await currentUser!.updatePassword(_passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Update user's personal information
  Future<void> _updatePersonalInfo() async {
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fName': _firstNameController.text,
          'lName': _lastNameController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Personal information updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Update Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Update Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateEmail,
              child: const Text('Update Email'),
            ),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Update Password'),
            ),
            ElevatedButton(
              onPressed: _updatePersonalInfo,
              child: const Text('Update Personal Info'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
