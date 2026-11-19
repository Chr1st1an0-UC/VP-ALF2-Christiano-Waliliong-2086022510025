# TCG Vault — Panduan Arsitektur Ringkas

TCG Vault adalah aplikasi Flutter sederhana untuk melihat kartu TCG, mencari
kartu berdasarkan nama atau pemilik, serta menyimpan kartu favorit. Daftar
kartu dan ilustrasinya dibundel sebagai asset lokal. Nama kartu favorit
disimpan di perangkat agar tetap tersedia setelah aplikasi ditutup dan dibuka
kembali.

Dokumen ini merangkum cara kerja aplikasi, tanggung jawab setiap lapisan,
hubungan kelas, state, istilah teknis, dan batasan desain. Untuk uraian yang
lebih panjang, lihat [README.md](README.md).

## 1. Gambaran MVVM

MVVM adalah singkatan dari **Model–View–ViewModel**. Pola ini memisahkan
bentuk data, tampilan, dan pengelola state/aksi agar satu bagian tidak
mengambil alih tanggung jawab bagian lain.

- **Model/domain** mendeskripsikan data dan kontrak aplikasi. `TcgCard`
  menggambarkan sebuah kartu; kontrak repository mendeskripsikan operasi data
  yang dibutuhkan aplikasi.
- **View** menggambar UI berdasarkan state dan meneruskan aksi pengguna.
  View tidak membaca JSON, memanggil service data, atau menyimpan favorit.
- **ViewModel** menerima aksi View, meminta data melalui repository domain,
  menghitung hasil pencarian/filter, dan menerbitkan state baru. Di proyek ini
  `VaultViewModel` memakai Cubit untuk mengelola state.
- **Data** menyediakan implementasi repository dan service yang berbicara
  dengan sumber data konkret seperti asset JSON atau penyimpanan lokal.

Alur komunikasi dan dependency:

```text
Pengguna
   │ mengetik, memilih filter, menekan favorit
   ▼
Views/VaultView ── aksi ──> ViewModels/VaultViewModel (Cubit)
   ▲                             │
   │ render state                │ panggil kontrak domain
   │                             ▼
   └──────────────────── domain/repositories/TcgCardRepository
                                  ▲
                                  │ implementasi
                      data/repositories/TcgCardRepositoryImpl
                          ├── data/services/TcgCardAssetService
                          │       └── asset JSON → TcgCard
                          └── data/services/FavoriteStorageService
                                  └── SharedPreferences
```

ViewModel bergantung pada kontrak repository, bukan pada JSON atau plugin
penyimpanan. `TcgCardRepositoryImpl` menghubungkan kontrak tersebut ke service
konkret. `main.dart` adalah **composition root**, yaitu tempat objek konkret
dibuat dan dirangkai. Karena itulah entry point boleh mengenal implementasi
data, tetapi View dan ViewModel tidak perlu mengimpornya.

## 2. Struktur folder dan file

```text
lib/
├── main.dart
├── assets/
│   └── cards/                         # Gambar kartu lokal
├── data/
│   ├── cards.json                     # Data nama, gambar, dan pemilik
│   ├── repositories/
│   │   └── tcg_card_repository_impl.dart
│   └── services/
│       ├── favorite_storage_service.dart
│       └── tcg_card_asset_service.dart
├── domain/
│   ├── entities/
│   │   └── tcg_card.dart
│   └── repositories/
│       └── tcg_card_repository.dart
├── ViewModels/
│   ├── vault_state.dart
│   └── vault_view_model.dart
└── Views/
    ├── vault_view.dart
    └── widgets/
        └── tcg_card_tile.dart
```

Nama folder `Views` dan `ViewModels` saat ini menggunakan huruf kapital.
Folder `core/` tidak dibuat karena belum ada kode bersama lintas fitur yang
memerlukan tempat tersebut. `core/` bukan kewajiban MVVM; menambahkannya tanpa
kebutuhan hanya akan menambah lapisan.

### Tanggung jawab tiap direktori

| Direktori | Isi dan tanggung jawab |
| --- | --- |
| `domain/entities/` | Model inti aplikasi yang tidak bergantung pada sumber data
  atau UI. |
| `domain/repositories/` | Kontrak operasi data yang dipakai ViewModel. |
| `data/services/` | Akses ke sumber konkret, satu service untuk satu jenis
  pekerjaan data. |
| `data/repositories/` | Implementasi kontrak domain dan penghubung ke service. |
| `ViewModels/` | Cubit/ViewModel dan tipe state presentasi. |
| `Views/` | Widget layar serta widget kartu. |
| `assets/cards/` | Gambar kartu yang dibundel bersama aplikasi. |

## 3. Kelas dan hubungan antar-kelas

### `TcgCard`

`lib/domain/entities/tcg_card.dart` mendefinisikan satu kartu dengan tiga
properti: `name`, `image`, dan `owner`. Semua properti `final`, jadi objek
kartu tidak diubah setelah dibuat. `TcgCard` memakai `Equatable`, dengan ketiga
properti tersebut di `props`; dua kartu bernilai sama apabila nama, path gambar,
dan pemiliknya sama.

Favorit saat ini menggunakan nama kartu sebagai identitas. Karena itu nama
sebaiknya unik dan tidak berubah. Jika kelak kartu dapat memiliki nama sama
atau namanya dapat diedit, tambahkan ID stabil dan simpan favorit berdasarkan
ID.

### `TcgCardRepository`

`lib/domain/repositories/tcg_card_repository.dart` adalah interface/kontrak.
Ia tidak menentukan apakah penyimpanan berupa JSON, API, atau database.
Operasinya:

- `getCards()` mengambil daftar `TcgCard`.
- `getFavoriteNames()` membaca kumpulan nama favorit sebagai `Set<String>`.
- `saveFavoriteNames(names)` menyimpan kumpulan favorit terbaru.

Ketiganya asynchronous dan menghasilkan `Future`, karena akses asset atau
penyimpanan mungkin belum selesai saat method dipanggil.

### `TcgCardRepositoryImpl`

`lib/data/repositories/tcg_card_repository_impl.dart` mengimplementasikan
kontrak domain. `getCards()` meneruskan pekerjaan ke `TcgCardAssetService`;
pembacaan dan penyimpanan favorit diteruskan ke `FavoriteStorageService`.
Repository menghubungkan sumber data ke kontrak, bukan menggambar UI atau
menghitung filter kartu.

### Services

`TcgCardAssetService` di `lib/data/services/tcg_card_asset_service.dart`
membaca `lib/data/cards.json` menggunakan `rootBundle.loadString()`. Teks JSON
diubah oleh `jsonDecode()` menjadi nilai Dart. Service memvalidasi bahwa hasil
berupa daftar objek dengan field `name`, `image`, dan `owner` bertipe teks,
lalu membentuk `TcgCard`. Format tidak valid menghasilkan
`FormatException`. Service tidak memastikan nama kartu unik ataupun bahwa
setiap path gambar benar-benar menunjuk ke file yang tersedia.

`FavoriteStorageService` di
`lib/data/services/favorite_storage_service.dart` memakai
`SharedPreferences` untuk membaca dan menyimpan nama favorit. Key yang
digunakan adalah `tcg_vault_favorites`. Jika belum pernah ada nilai tersimpan,
`loadFavorites()` menghasilkan set kosong. Saat menyimpan, set diubah menjadi
daftar string yang diurutkan; jika penulisan gagal, service melempar
`StateError`.

### `VaultState` dan variannya

`lib/ViewModels/vault_state.dart` mendefinisikan state yang dapat diterbitkan
oleh ViewModel. `VaultState` adalah `sealed`, sehingga turunannya terbatas dan
View dapat menangani seluruh state secara exhaustif. Semua state menggunakan
`Equatable`, sehingga perubahan dapat dibandingkan berdasarkan nilai.

| State | Makna dan UI |
| --- | --- |
| `VaultLoading` | Data sedang dimuat; View menampilkan spinner. |
| `VaultLoaded` | Data tersedia: kartu, query, filter, favorit, status simpan,
  dan notice opsional. |
| `VaultFailure` | Pemuatan awal gagal; View menampilkan pesan dan tombol retry. |

`VaultLoaded` membungkus daftar kartu dan set favorit sebagai koleksi yang
tidak dapat dimodifikasi. `copyWith()` membuat state baru sambil
mempertahankan nilai yang tidak berubah. Getter `visibleCards` menghitung
kecocokan query terhadap nama atau pemilik, lalu menerapkan filter favorit
jika aktif. Pencarian tidak peka huruf besar/kecil dan mengabaikan spasi di
awal/akhir query. `favoriteCount` menghitung kartu yang sedang dimuat dan
favorit; `isFavorite(card)` memeriksa apakah nama kartu terdapat dalam set.

### `VaultViewModel`

`lib/ViewModels/vault_view_model.dart` adalah ViewModel dan Cubit aplikasi.
Cubit adalah mekanisme dari `flutter_bloc` yang menerima pemanggilan method dan
menerbitkan state dengan `emit()`. Ini tetap MVVM: ViewModel menjadi
perantara antara View dan repository/domain.

- `loadCards()` menerbitkan `VaultLoading`, mengambil kartu dan nama favorit
  melalui repository, lalu menerbitkan `VaultLoaded`. Kegagalan menghasilkan
  `VaultFailure`.
- `setSearchQuery(query)` membuat state loaded baru dengan query baru.
- `setFavoritesOnly(value)` mengubah filter tampilan; method ini tidak menulis
  penyimpanan.
- `toggleFavorite(card)` menambah atau menghapus nama dari favorit, menerbitkan
  state dengan penanda sedang menyimpan, lalu meminta repository menyimpan
  data. Jika simpan gagal, nilai sebelumnya dipulihkan dan notice ditampilkan.

Setiap `await` di Cubit diikuti pemeriksaan `isClosed`. Ini mencegah Cubit
menerbitkan state setelah provider menutupnya. Operasi yang sudah dikirim ke
plugin tidak selalu dibatalkan; hasilnya hanya tidak boleh memperbarui Cubit
yang sudah ditutup.

### Views dan widget

`VaultView` di `lib/Views/vault_view.dart` menampilkan judul, kolom pencarian,
dan `BlocBuilder`. Switch state-nya menangani `VaultLoading`, `VaultLoaded`,
dan `VaultFailure`.

Widget private `_LoadedVault` menampilkan `FilterChip`, notice jika ada, pesan
kosong, atau grid kartu. `_LoadFailure` menampilkan pesan pemuatan dan tombol
coba lagi. `_Notice` menampilkan kegagalan simpan dan menandainya dengan
`Semantics(liveRegion: true)` agar teknologi bantu dapat mengumumkan pesan.

`TcgCardTile` di `lib/Views/widgets/tcg_card_tile.dart` hanya menampilkan
gambar, nama, pemilik, dan bintang. Ia menerima status favorit, status
penyimpanan, dan callback dari parent; tile tidak mengetahui repository atau
cara menyimpan favorit. Tombol bintang dinonaktifkan selama penulisan sedang
berlangsung.

`VaultView` adalah `StatelessWidget` dan tidak memakai `setState` untuk
business state. `BlocBuilder` mengelola pendengaran state UI. Aplikasi tidak
membuat `StreamSubscription` atau `TextEditingController` sendiri. `BlocProvider`
mengelola penutupan Cubit yang dibuatnya.

## 4. Alur data

### Saat aplikasi dimulai

1. `main()` membuat service kartu, service favorit, dan
   `TcgCardRepositoryImpl`.
2. Repository konkret diberikan ke `TcgVaultApp` sebagai
   `TcgCardRepository`.
3. `BlocProvider` membuat `VaultViewModel` dan memulai `loadCards()`.
4. Cubit menerbitkan `VaultLoading`, yang membuat View menampilkan spinner.
5. ViewModel meminta kartu. Repository meneruskan permintaan ke
   `TcgCardAssetService`, yang membaca, memvalidasi, lalu membuat model kartu.
6. ViewModel meminta favorit. Repository meneruskan permintaan ke
   `FavoriteStorageService`, yang membaca `SharedPreferences`.
7. ViewModel menerbitkan `VaultLoaded`. View menampilkan grid atau pesan kosong.

Jika membaca JSON atau preferensi gagal, ViewModel menerbitkan `VaultFailure`
dengan pesan pengguna: “Kartu belum dapat dimuat. Periksa data lokal, lalu
coba lagi.” Tombol coba lagi mengulang `loadCards()`. Pesan internal exception
tidak ditampilkan mentah kepada pengguna. Implementasi saat ini belum memasang
logger untuk merekam exception.

### Pencarian dan filter

Kolom `TextField` mengirim teks melalui `setSearchQuery()`. `FilterChip`
mengirim pilihan melalui `setFavoritesOnly()`. ViewModel membuat state baru;
`BlocBuilder` membangun ulang layar. Filter hasil disediakan oleh getter
`visibleCards` pada `VaultLoaded`, sehingga widget tidak melakukan pencocokan
nama atau pemilik.

Query dan pilihan filter hanya berada di memori state. Keduanya tidak disimpan
dan kembali ke nilai awal setelah aplikasi dimulai ulang. Input ketika state
bukan `VaultLoaded` tidak mengubah state kartu.

### Mengubah favorit

1. Ketukan pada bintang memanggil callback di tile.
2. Callback meminta `VaultViewModel.toggleFavorite(card)`.
3. ViewModel membuat set baru dan menerbitkan state dengan
   `isSavingFavorites: true`.
4. Repository meneruskan penulisan ke `FavoriteStorageService`.
5. Jika berhasil, ViewModel menandai simpan selesai. Jika gagal, favorit lama
   dipulihkan dan pesan berikut ditampilkan: “Favorit belum tersimpan. Periksa
   penyimpanan, lalu coba lagi.”
6. Saat aplikasi berikutnya dibuka, nama favorit dibaca kembali dari
   `SharedPreferences`.

Keadaan kosong tetap merupakan `VaultLoaded`, bukan error: data berhasil
dimuat, tetapi tidak ada kartu yang cocok. Spinner hanya untuk `VaultLoading`;
kegagalan memiliki tampilan retry sendiri.