// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/Category.dart';
import 'package:http/http.dart' as http;
import 'Product.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
      title: 'Network',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

Future<List<Product>> fetchProduct() async {
  final res = await http.get(Uri.parse(
      'http://192.168.0.104:8000/api/product')); // UBAH IP sesuai IP device (ipconfig buat liatnya)
  if (res.statusCode == 200) {
    var data = jsonDecode(res.body);
    var parsed = data['list'].cast<Map<String, dynamic>>();
    return parsed.map<Product>((json) => Product.fromJson(json)).toList();
  } else {
    throw Exception('Failed');
  }
}

Future<List<Category>> fetchCategory() async {
  final res = await http.get(Uri.parse(
      'http://192.168.0.104:8000/api/category')); // UBAH IP sesuai IP device (ipconfig buat liatnya)
  if (res.statusCode == 200) {
    var data = jsonDecode(res.body);
    var parsed = data['list'].cast<Map<String, dynamic>>();
    return parsed.map<Category>((json) => Category.fromJson(json)).toList();
  } else {
    throw Exception('Failed');
  }
}

Future<Map<String, dynamic>> addProduct(
    _name, _price, _desc, _categoryId) async {
  final res = await http
      .post(Uri.parse('http://192.168.0.104:8000/api/product'), body: {
    'name': _name,
    'description': _desc,
    'price': _price,
    'category_id': _categoryId,
  });
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Failed');
  }
}

class _MyAppState extends State<MyApp> {
  late Future<List<Product>> products;
  late Future<List<Category>> categories;
  int? selectedCategoryId;

  final _formKey = GlobalKey<FormState>();

  var nameInput = TextEditingController();
  var descInput = TextEditingController();
  var priceInput = TextEditingController();

  String formatPrice(dynamic price) {
    final number = double.tryParse(price) ?? 0.0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 2)
        .format(number);
  }

  @override
  void initState() {
    super.initState();
    products = fetchProduct();
    categories = fetchCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada data',
                        style: TextStyle(color: Colors.teal, fontSize: 28),
                      ),
                    );
                  }
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Card(
                            color: Colors.white,
                            child: InkWell(
                              child: Container(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 15),
                                margin: const EdgeInsets.only(
                                    bottom: 40, left: 10, top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snapshot.data![index].name,
                                      style: const TextStyle(
                                          color: Colors.blue, fontSize: 28),
                                    ),
                                    Text(
                                      formatPrice(snapshot.data![index].price),
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ));
                      });
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              })),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: const Text('Add New Product'),
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Name',
                                  contentPadding: EdgeInsets.all(10),
                                  hintText: 'Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                              controller: nameInput,
                            ),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Description',
                                  contentPadding: EdgeInsets.all(10),
                                  hintText: 'Description'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                              controller: descInput,
                            ),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Price',
                                  contentPadding: EdgeInsets.all(10),
                                  hintText: 'Price'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                              controller: priceInput,
                            ),
                            FutureBuilder<List<Category>>(
                              future: categories,
                              builder: (context, catSnapshot) {
                                if (catSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (catSnapshot.hasError) {
                                  return const Text(
                                      "Failed to load categories");
                                } else {
                                  return DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                        labelText: 'Categories',
                                        contentPadding: EdgeInsets.all(10),
                                        hintText: 'Categories'),
                                    value: selectedCategoryId,
                                    validator: (value) => value == null
                                        ? 'Please select a category'
                                        : null,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategoryId = value;
                                      });
                                    },
                                    items: catSnapshot.data!
                                        .map((cat) => DropdownMenuItem<int>(
                                              value: cat.id,
                                              child: Text(cat.name),
                                            ))
                                        .toList(),
                                  );
                                }
                              },
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    var res = await addProduct(
                                      nameInput.text,
                                      priceInput.text,
                                      descInput.text,
                                      selectedCategoryId
                                          .toString(), // make sure it's a string
                                    );
                                    if (res['error']) {
                                    } else {
                                      setState(() {
                                        products = fetchProduct();
                                      });
                                    }
                                    Navigator.of(context).pop();
                                    var snackBar = SnackBar(
                                      content: Text(res['message']),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                  }
                                },
                                child: const Text('Save'))
                          ],
                        ),
                      )
                    ],
                  );
                });
          }),
    );
  }
}
