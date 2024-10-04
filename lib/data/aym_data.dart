//Aym bilgilendirme sayfasi için tutulan veriler
final List<Map<String, String>> aymData = [
  {
    'title': 'Etkileşimli Dil Düzenleyici',
    'description':
        'Kullanıcı, metinde dil (örneğin İngilizce) ifadesi geçen metine tıkladığında bir diyalog açılır ve bu diyalogda mevcut dili düzenleyebilir. Örneğin, [Dil: İngilizce] kısmı üzerinde düzenleme yaparak başka bir dil girebilir. Bu işlem sonrasında metin anında güncellenir ve kullanıcıya yaptığı değişikliği hemen görme imkanı sunar.',
    'subtitle': 'Kullanım Kılavuzu',
    'subtitle2': 'Etkileşimli Dil Düzenleyici Entegre Etme:',
    'description2':
        'İtem ekleme kısmında, eğer bir dil girmek istiyorsanız başta bu dili [Dil: İngilizce] şeklinde giriniz.',
    'subtitle3': 'Dili düzenleme:',
    'description3':
        'Eklediğiniz metin ana sayfada sadece bir dil (İngilizce) olarak gözükecektir. Metnin üzerine tıklayarak dili değiştirebilirsiniz.',
    'sample': "Örnek:\n Bugün [Dil:ingilizce] dilbilgisi üzerine çalışıyorum.",
  },
  {
    'title': 'Etkileşimli İsim Düzenleyici',
    'description':
        'Kullanıcı, metinde isim (örneğin Mehmet) ifadesi geçen metine tıkladığınızda bir diyalog açılır ve bu diyalogda mevcut ismi düzenleyebilir. Örneğin, [İsim: Mehmet] kısmı üzerinde düzenleme yaparak başka bir isim girebilir. Bu işlem sonrasında metin anında güncellenir ve kullanıcıya yaptığı değişikliği hemen görme imkanı sunar.',
    'subtitle': 'Kullanım Kılavuzu',
    'subtitle2': 'Etkileşimli İsim Düzenleyici Entegre Etme:',
    'description2':
        'İtem ekleme kısmında, eğer bir isim girmek istiyorsanız başta bu ismi [İsim: Mehmet] şeklinde giriniz.',
    'subtitle3': 'İsmi düzenleme:',
    'description3':
        'Eklediğiniz metin ana sayfada sadece bir isim (Mehmet) olarak gözükecektir. Metnin üzerine tıklayarak ismi değiştirebilirsiniz.',
    'sample': "Örnek:\n[İsim:Mehmet], bugün yeni bir spor rutini deniyor.",
  },
  {
    'title': 'Etkileşimli Seçenek Düzenleyici',
    'description':
        'Kullanıcı, metinde [Seçenekler:] ifadesi geçen metine tıkladığınızda bir diyalog açılır ve bu diyalogda mevcut seçeneklerden birini seçebilir. Örneğin, [Seçenekler:Seçenek1|Seçenek2|Seçenek3] ifadesinde varsayılan olarak Seçenek1 gösterilir, ancak kullanıcı diğer seçenekleri seçebilir.',
    'subtitle': 'Kullanım Kılavuzu',
    'subtitle2': 'Seçenek Düzenleyici Entegre Etme:',
    'description2':
        'İtem ekleme kısmında, [Seçenekler:Seçenek1|Seçenek2|Seçenek3] formatında seçenekler tanımlayabilirsiniz. Seçeneklerin her biri "|" işareti ile ayrılmalıdır.',
    'subtitle3': 'Seçenek Düzenleme:',
    'description3':
        'Metinde Seçenek1 gibi varsayılan bir seçenek gösterilir. Bu metin üzerine tıklayarak diyalog açılır ve buradan farklı bir seçenek seçilebilir. Bu seçim sonrası sadece display text güncellenir, kaynak metin değişmez.',
    'sample':
        "Örnek:\nGörev Durumu: [Seçenekler:Başlamadı|Devam Ediyor|Tamamlandı]",
  },
  {
    'title': 'Resim Kopyalama ve Seçme',
    'description':
        'Kullanıcı, bir itemde resim yoksa resim ikonunun üzerine basılı tutarak bir pencere açar. Bu pencerede galerisinden bir resim seçebilir. Seçilen resim diyalogda görüntülenir ve kopyalama işlemi yapılabilir. Ancak, resim item\'e eklenmez, sadece panoya kopyalanır.',
    'subtitle': 'Kullanım Kılavuzu',
    'subtitle2': 'Resim Kopyalama ve Seçme Entegre Etme:',
    'description2': 'Otamatik olarak entegre edilmiştir',
    'subtitle3': 'Resim Seçme ve Kopyalama:',
    'description3':
        'İtem ekleme kısmında, bir iteme resim eklenmediğinde ana sayfada itemin resmi olmadığı için bu bir ikonla gösterilir. Bu ikona uzun süre basılı tutunca  bir pencere açılır. Bu peencerede ise Kullanıcı galerisinden bir resim seçip kopyalayabilir, fakat bu resim item\'e eklenmez.',
    'sample': "",
  },
  {
    'title': 'Toplu Metin Kopyalama',
    'description':
        'Kullanıcı, bir tablodaki itemlerin içinde bulunan metni kopyalamak istediğinde, itemlere ait olan başlığa (title) tıklayarak itemdeki her bir metin ayrı ayrı panoya kopyalanır. Ardından Kopyalama işleminin tamamlandığına dair bir bildirim gösterilir.',
    'subtitle': 'Kullanım Kılavuzu',
    'subtitle2': 'Metin Kopyalama Entegre Etme:',
    'description2':
        'Opsiyonel olarak tabloya item ekleme esnasında metin yazarken "||" kullanarak itemi "||" ile parçalara ayırabilirsiniz. Böylece diğer item alanlarını tek tek doldurmak zorunda kalmadan bir alanda tüm itemleri tanımlayabileceksiniz.',
    'subtitle3': 'Kopyalama İşlemi:',
    'description3':
        'Başlığa (title) tıklayarak itemdeki her bir metin ayrı ayrı panoya kopyalanabilir. Tablodaki her bir metin, sırasıyla panoya kopyalanır. Kopyalama tamamlandıktan sonra bir bildirim gösterilir.',
    'sample': "",
  },

  //  {
  //   'title': '',
  //   'description': '',
  //   'subtitle': '',
  //   'subtitle2': '',
  //   'description2': '',
  //   'subtitle3': '',
  //   'description3': '',
  // 'sample':"",
  // },
];
