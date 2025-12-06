import 'dart:io'; // Para lidar com arquivos
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Pacote de imagem
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;
  
  // Variáveis para Imagem
  File? _imageFile; // O arquivo da imagem no celular
  final ImagePicker _picker = ImagePicker();

  // Lista de categorias
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isCreatingNewCategory = false;

  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final companyData = await Supabase.instance.client
        .from('companies')
        .select('id')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (companyData != null) {
      final data = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('company_id', companyData['id']);
      
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
        });
      }
    }
  }

  // --- 1. FUNÇÃO PARA ESCOLHER IMAGEM DA GALERIA ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Abre a galeria
        imageQuality: 80, // Comprime um pouco para não ficar pesado
        maxWidth: 800, // Redimensiona se for muito grande
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao pegar imagem: $e")));
    }
  }

  // --- 2. FUNÇÃO PARA FAZER UPLOAD NO SUPABASE ---
  Future<String?> _uploadImage(String companyId) async {
    if (_imageFile == null) return null;

    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$companyId/$fileName'; // Organiza por pasta da empresa

      // Upload
      await Supabase.instance.client.storage
          .from('products') // Nome do Bucket que criamos lá atrás
          .upload(filePath, _imageFile!, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      // Pegar URL Pública
      final imageUrl = Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception("Erro no upload: $e");
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null && !_isCreatingNewCategory) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione uma categoria")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final companyData = await Supabase.instance.client
        .from('companies')
        .select('id')
        .eq('owner_id', user!.id)
        .single();
      
      final companyId = companyData['id'];
      dynamic finalCategoryId = _selectedCategoryId;

      // Cria categoria nova se precisar
      if (_isCreatingNewCategory) {
        final newCategory = await Supabase.instance.client.from('categories').insert({
          'company_id': companyId,
          'name': _categoryController.text.trim(),
        }).select().single();
        finalCategoryId = newCategory['id'];
      }

      // --- FAZ O UPLOAD DA IMAGEM SE TIVER ---
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(companyId);
      } else {
        // Fallback se não escolher foto (opcional, ou pode obrigar)
        imageUrl = 'https://placehold.co/600x400/orange/white?text=${_nameController.text.trim()}';
      }

      final priceClean = _priceController.text.replaceAll(',', '.');

      // Salva Produto com a URL da imagem
      await Supabase.instance.client.from('products').insert({
        'company_id': companyId,
        'category_id': finalCategoryId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(priceClean),
        'is_available': true,
        'image_url': imageUrl, // AQUI ESTÁ A URL REAL!
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produto salvo!")));
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Novo Produto", style: myFontStyle.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ÁREA DE SELEÇÃO DE IMAGEM ---
              GestureDetector(
                onTap: _pickImage, // Abre a galeria ao clicar
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) 
                      : null,
                  ),
                  child: _imageFile == null 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text("Toque para adicionar foto", style: myFontStyle.copyWith(color: Colors.grey[500])),
                        ],
                      )
                    : null, // Se tiver foto, mostra ela no DecorationImage acima
                ),
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: TextButton(
                      onPressed: _pickImage,
                      child: const Text("Trocar Foto", style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              CustomTextField(
                label: "Nome do Produto",
                icon: Icons.fastfood,
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Preço (R\$)",
                      icon: Icons.attach_money,
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Descrição",
                icon: Icons.description,
                controller: _descController,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),

              Text("Categoria", style: myFontStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              if (_isCreatingNewCategory)
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: "Nova Categoria", 
                        icon: Icons.category, 
                        controller: _categoryController
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _isCreatingNewCategory = false),
                    )
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text("Selecione uma categoria", style: myFontStyle),
                      value: _selectedCategoryId,
                      items: [
                        ..._categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat['id'].toString(),
                            child: Text(cat['name'], style: myFontStyle),
                          );
                        }),
                        const DropdownMenuItem(
                          value: 'new',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text("Criar Nova...", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'new') {
                          setState(() => _isCreatingNewCategory = true);
                        } else {
                          setState(() => _selectedCategoryId = value);
                        }
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("SALVAR PRODUTO", style: myFontStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}