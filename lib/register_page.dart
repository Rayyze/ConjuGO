import 'dart:async';
import 'package:conjugo/list_activity.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:conjugo/authentication_service.dart';

// Création instance pour communiquer avec la base + partie authentification
FirebaseFirestore db = FirebaseFirestore.instance;
AuthenticationService auth = AuthenticationService();

//Page inscription
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  //Initialisation des champs textuels
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordController2 = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  bool obscureText1 = true;
  bool obscureText2 = true;

  // Création fonction qui vérifie si le mot de passe contient au moins 1 lettre et 1 chiffre
  bool passwordContainLetterAndNumber(String password) {
    // Vérifier la présence d'au moins une lettre
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    // Vérifier la présence d'au moins un chiffre
    bool hasNumber = password.contains(RegExp(r'[1234567890]'));
    // Retourner true si le mot de passe respecte les critères, sinon false
    return hasLetter && hasNumber;
  }

  StreamSubscription<User?>? authListener;

  @override
  void initState() {
    super.initState();
    authListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      //On regarde si un user est donc connecté, si oui, on prend son id
        if (user != null) {
          String userUid = auth.getUser();
          //Insertion des infos user dans la base firestore
          db.collection("USERDATA").doc(userUid).set({
            "userId" : userUid,
            "nom": nameController.text,
            "prenom": surnameController.text,
            "dateDeNaissance": dateController.text,
            "admin": false,
            "superAdmin": false,
            "mail": emailController.text
          });
          //Redirection vers page accueil activités
          showConfirmDialog(context);
        }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordController2.dispose();
    nameController.dispose();
    surnameController.dispose();
    dateController.dispose();
    authListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscrivez-vous"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
        child: Scrollbar(
            child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: [
            Form(
                //Formulaire contenant infos inscriptions seniors
                child: Column(children: <Widget>[
              const SizedBox(height: 20),
              TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: " Nom")),
              const SizedBox(height: 20),
              TextFormField(
                  controller: surnameController,
                  decoration: const InputDecoration(labelText: " Prénom")),
              TextFormField(
                  controller: dateController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      icon: Icon(Icons.calendar_today),
                      labelText: "Date de Naissance"),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1920),
                        lastDate: DateTime(2025),
                        locale : const Locale('fr'));
                    //On transforme la date au format souhaité
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('dd-MM-yyyy').format(pickedDate);

                      dateController.text = formattedDate;
                    }
                  }),
              const SizedBox(height: 20),
              TextFormField(
                  //Mail
                  controller: emailController,
                  toolbarOptions: const ToolbarOptions(
                    //Rendre possible les copier-coller
                    copy: true,
                    cut: true,
                    paste: true, //Peut-être pas besoin car déjà "true" de base
                    selectAll: true,
                  ),
                  decoration: const InputDecoration(labelText: " Mail")),
             
              const SizedBox(height: 20),
              TextFormField(
                  // MDP
                  obscureText: obscureText1,
                  controller: passwordController,
                  toolbarOptions: const ToolbarOptions(
                    copy: false,
                    cut: false,
                    paste: false,
                    selectAll: false,
                  ),
                  decoration: InputDecoration(
                    labelText: " Mot de Passe (minimum 8 caractères, au moins 1 lettre et 1 chiffre)",
                    suffixIcon: IconButton(
                      icon: Icon(obscureText1 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          obscureText1 = !obscureText1;
                        });
                      },
                    ),
                  )
              ),
              const SizedBox(height: 20),
              TextFormField(
                //MDP 2
                obscureText: obscureText2,
                controller: passwordController2,
                toolbarOptions: const ToolbarOptions(
                  copy: false,
                  cut: false,
                  paste: false,
                  selectAll: false,
                ),
                decoration: InputDecoration(
                  labelText: " Rentrez votre mot de passe une seconde fois",
                  suffixIcon: IconButton(
                    icon: Icon(obscureText2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        obscureText2 = !obscureText2;
                      });
                    },
                  ),
                )
              ),
            ])),
            ElevatedButton(
                //Bouton inscription
                child: const Text("S'inscrire"),
                onPressed: () //=> print(emailControler.text),
                    async {
                  //Vérifications que le mdp est dans le bon format et qu'il a bien été rédigé 2 fois
                  if (passwordController.text.length >= 8 &&
                      passwordController.text == passwordController2.text &&
                      passwordContainLetterAndNumber(passwordController.text) == true) {
                    //Vérifications que le mail a bien été rentré correctement 2 fois
                      //Inscription
                      try {
                        await auth.registerWithEmailAndPassword(emailController.text, passwordController.text);
                        // Connecte l'utilisateur après l'inscription
                        await auth.signInWithEmailAndPassword(emailController.text, passwordController.text);
                      } catch (exception) {
                        if (context.mounted) {
                          print("l'exception renvoyée est : $exception");
                          if (exception.toString()=="email-already-in-use") {
                            showErrorDialog(context, "Un compte avec la même adresse email existe déjà");
                            emailController.clear();
                          } else if (exception.toString()=="invalid-email") {
                            showErrorDialog(context, "format d'email invalide");
                            emailController.clear();
                          } else if (exception.toString()=="operation-not-allowed") {
                            showErrorDialog(context, "Opération invalide");
                          } else if (exception.toString()=="weak-password") {
                            showErrorDialog(context, "Mot de passe trop faible");
                          }
                        }
                        print("\n\n\n");
                        passwordController.clear();
                        passwordController2.clear();
                      }
                  } else {
                    //Pop up erreur mdp et on nettoie les 2 mdp
                    showErrorDialog(context, "Mot de passe trop faible");
                  }
                })
          ]),
        )),
      ),
    );
  }

//ALERTES
  showConfirmDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const ListViewHomeLayout(),
              ),
              (Route<dynamic> route) => false);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Incriptions effectuée"),
      content: const Text("Vous êtes inscrit, retour à la page d'accueil."),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }

  showErrorDialog(BuildContext context, String errorText) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () => Navigator.of(context).pop(),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Erreur"),
      content: Text(errorText),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }
//Pas implémenté + Faire aussi si le mail est pas dans le format : il se passe rien pour l'instant car erreur firebase mais y a pas de pop
  // showAlertDialogMailAlrdy(BuildContext context) {
  //   // set up the button
  //   Widget okButton = TextButton(
  //     child: Text("OK"),
  //     onPressed: () => Navigator.of(context).pop(),
  //   );

  //   // set up the AlertDialog
  //   AlertDialog alert = AlertDialog(
  //     title: Text("Erreur"),
  //     content: Text("Mail déjà existant"),
  //     actions: [
  //       okButton,
  //     ],
  //   );

  //   // show the dialog
  //   if (mounted) {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return alert;
  //       },
  //     );
  //   }
  // }

  showAlertDialogMdp(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Erreur"),
      content: const Text(
          "Mots de passes différents ou au mauvais format"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }
}
