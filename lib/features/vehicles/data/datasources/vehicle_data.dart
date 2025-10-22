// Araç marka listesi (Türkiye'de popüler markalar)
class VehicleData {
  static const List<String> brands = [
    'AUDI',
    'BMW',
    'CHEVROLET',
    'DACIA',
    'FIAT',
    'FORD',
    'HONDA',
    'HYUNDAI',
    'KIA',
    'MERCEDES-BENZ',
    'NISSAN',
    'OPEL',
    'PEUGEOT',
    'RENAULT',
    'SEAT',
    'SKODA',
    'TOYOTA',
    'VOLKSWAGEN',
    'VOLVO',
  ];

  // Markaya göre modeller
  static const Map<String, List<String>> modelsByBrand = {
    'Fiat': [
      'Egea',
      'Linea',
      'Doblo',
      'Fiorino',
      '500',
      'Panda',
      'Tipo',
      'Punto',
    ],
    'Renault': [
      'Clio',
      'Megane',
      'Symbol',
      'Fluence',
      'Taliant',
      'Captur',
      'Kadjar',
      'Austral',
    ],
    'Volkswagen': [
      'Polo',
      'Golf',
      'Passat',
      'Jetta',
      'Tiguan',
      'T-Roc',
      'Taigo',
      'Caddy',
    ],
    'Toyota': [
      'Corolla',
      'Yaris',
      'Camry',
      'C-HR',
      'RAV4',
      'Hilux',
      'Land Cruiser',
    ],
    'Honda': [
      'Civic',
      'CR-V',
      'HR-V',
      'Accord',
      'Jazz',
    ],
    'Hyundai': [
      'i20',
      'i10',
      'Accent',
      'Elantra',
      'Tucson',
      'Kona',
      'Santa Fe',
      'Bayon',
    ],
    'Ford': [
      'Focus',
      'Fiesta',
      'Mondeo',
      'Kuga',
      'Puma',
      'Transit',
      'Ranger',
    ],
    'Peugeot': [
      '208',
      '301',
      '308',
      '508',
      '2008',
      '3008',
      '5008',
    ],
    'Dacia': [
      'Duster',
      'Sandero',
      'Logan',
      'Spring',
      'Jogger',
    ],
  };

  // Araç sınıfları (HGS/OGS için)
  static const List<Map<String, String>> vehicleClasses = [
    {
      'id': '1',
      'name': 'Sınıf 1',
      'description': 'Otomobil, Minibüs (9 koltuk ve altı)',
      'icon': '🚗',
    },
    {
      'id': '2',
      'name': 'Sınıf 2',
      'description': 'Minibüs (10-17 koltuk), Kamyonet',
      'icon': '🚐',
    },
    {
      'id': '3',
      'name': 'Sınıf 3',
      'description': 'Otobüs, Kamyon (2 aks)',
      'icon': '🚌',
    },
    {
      'id': '4',
      'name': 'Sınıf 4',
      'description': 'Kamyon (3 aks)',
      'icon': '🚚',
    },
    {
      'id': '5',
      'name': 'Sınıf 5',
      'description': 'Kamyon (4+ aks)',
      'icon': '🚛',
    },
  ];

  // Yakıt türleri
  static const List<String> fuelTypes = [
    'Benzin',
    'Dizel',
    'LPG',
    'Elektrik',
    'Hibrit',
  ];

  // Renkler
  static const List<Map<String, dynamic>> colors = [
    {'name': 'Beyaz', 'hex': '#FFFFFF'},
    {'name': 'Siyah', 'hex': '#000000'},
    {'name': 'Gri', 'hex': '#808080'},
    {'name': 'Gümüş', 'hex': '#C0C0C0'},
    {'name': 'Mavi', 'hex': '#0000FF'},
    {'name': 'Kırmızı', 'hex': '#FF0000'},
    {'name': 'Yeşil', 'hex': '#00FF00'},
    {'name': 'Sarı', 'hex': '#FFFF00'},
    {'name': 'Turuncu', 'hex': '#FFA500'},
    {'name': 'Kahverengi', 'hex': '#A52A2A'},
  ];

  // Yıl listesi (son 30 yıl)
  static List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(30, (index) => currentYear - index);
  }

  // Marka için modelleri getir
  static List<String> getModelsForBrand(String brand) {
    return modelsByBrand[brand] ?? [];
  }
}
