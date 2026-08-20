// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Cosmic Wish';

  @override
  String get homeTagline => 'Trao đi điều ước, vũ trụ sẽ lắng nghe';

  @override
  String get startButton => 'BẮT ĐẦU';

  @override
  String get selectCategory => 'Chọn lĩnh vực';

  @override
  String get selectCategoryHint => 'Điều ước của bạn thuộc về đâu?';

  @override
  String get continueButton => 'TIẾP TỤC';

  @override
  String get centerYourself => 'Hãy tĩnh tâm';

  @override
  String get universeListens => 'Vũ trụ đang lắng nghe...';

  @override
  String get speakYourWish => 'Nói điều ước của bạn';

  @override
  String get sendingToUniverse => 'Đang truyền tải vào vũ trụ...';

  @override
  String get wishEngraved => 'Điều ước đã được khắc vào vũ trụ';

  @override
  String get returnHome => 'TRỞ VỀ';

  @override
  String get history => 'Hành trình điều ước';

  @override
  String get settings => 'Cài đặt';

  @override
  String get noWishesYet => 'Chưa có điều ước nào';

  @override
  String get beginYourJourney => 'Bắt đầu hành trình của bạn...';

  @override
  String get yourWish => 'Điều ước:';

  @override
  String get deleteAllConfirm => 'Xóa tất cả?';

  @override
  String get deleteAllMessage => 'Hành trình điều ước sẽ bị xóa vĩnh viễn.';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get soundEffects => 'Âm thanh';

  @override
  String get soundEffectsSubtitle => 'Nhạc nền và hiệu ứng';

  @override
  String get haptics => 'Rung phản hồi';

  @override
  String get hapticsSubtitle => 'Rung nhẹ khi tương tác';

  @override
  String get effects => 'Hiệu ứng';

  @override
  String get starDensity => 'Mật độ sao';

  @override
  String get animationSpeed => 'Tốc độ hoạt ảnh';

  @override
  String get reminder => 'Nhắc nhở';

  @override
  String get dailyReminder => 'Nhắc hàng ngày';

  @override
  String get dailyReminderSubtitle => 'Gửi thông báo mỗi ngày để nhắc điều ước';

  @override
  String get reminderTime => 'Thời gian nhắc';

  @override
  String get info => 'Thông tin';

  @override
  String get version => 'Phiên bản';

  @override
  String get aiModel => 'AI Model';

  @override
  String get purpose => 'Mục đích';

  @override
  String get purposeValue => 'Trải nghiệm tâm linh';

  @override
  String get footer => 'Cosmic Wish · gửi điều ước vào vũ trụ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Hệ thống';

  @override
  String get languageSystemSub => 'Theo thiết bị';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'Quay lại';

  @override
  String get importFile => 'Nhập từ file';

  @override
  String get exportFile => 'Xuất file';

  @override
  String get deleteAll => 'Xóa tất cả';

  @override
  String get sendWish => 'Gửi điều ước';

  @override
  String get close => 'Đóng';

  @override
  String get wishDetail => 'Chi tiết điều ước';

  @override
  String imported(int count) {
    return 'Đã nhập $count điều ước';
  }

  @override
  String get noNewData => 'Không có dữ liệu mới';

  @override
  String get ready => 'SẴN SÀNG';

  @override
  String get readySemantic => 'Tôi đã sẵn sàng, tiếp tục';

  @override
  String wishWillRespond(String time) {
    return 'Vũ trụ sẽ hồi đáp sau $time';
  }

  @override
  String get wishResponded => 'Vũ trụ đã hồi đáp';

  @override
  String get wishHistory => 'Lịch sử';

  @override
  String get historyTooltip => 'Lịch sử';

  @override
  String get settingsTooltip => 'Cài đặt';

  @override
  String get selectCategoryHeader => 'Chọn lĩnh vực';

  @override
  String get selectCategorySub => 'Điều ước của bạn thuộc về đâu?';

  @override
  String get centerYourselfHeader => 'Hãy tĩnh tâm';

  @override
  String get universeListensSub => 'Vũ trụ đang lắng nghe';

  @override
  String get enterWishEmpty => 'Hãy nhập điều ước của bạn.';

  @override
  String get tapToWriteWish => 'Chạm để viết điều ước...';

  @override
  String get sendWishButton => 'GỬI ĐIỀU ƯỚC';

  @override
  String get cameraPermissionNeeded =>
      'Camera đang tắt. Ngươi vẫn có thể nhập và gửi điều ước.';

  @override
  String get noCameraFound => 'Thiết bị không có camera.';

  @override
  String get cameraOpenError => 'Không thể mở camera.';

  @override
  String get permissionRequired => 'Cần quyền truy cập';

  @override
  String get openSettings => 'MỞ CÀI ĐẶT';

  @override
  String get openSettingsSemantic => 'Mở cài đặt hệ thống';

  @override
  String errorPrefix(String message) {
    return 'Lỗi: $message';
  }

  @override
  String get wishNotRecorded =>
      'Bạn chưa nói gì. Hãy thử lại và nói điều ước của bạn.';

  @override
  String get readySemantic2 => 'Tôi đã sẵn sàng, tiếp tục';

  @override
  String get thinkingPrompt => 'Bạn đang nghĩ gì?';

  @override
  String get weavingProphecy => 'Đan lời tiên tri…';

  @override
  String get starsAligning => 'Các vì sao đang xếp hàng';

  @override
  String get almostThere => 'Sắp tới rồi…';

  @override
  String get wishEngravedHeader => 'Điều ước đã được khắc vào vũ trụ';

  @override
  String get notifResponseTitle => 'Vũ trụ đã hồi đáp';

  @override
  String get notifResponseBody =>
      'Điều ước của bạn đang chờ được lắng nghe... Mở Cosmic Wish để xem.';

  @override
  String get notifFarewellTitle => 'Vũ trụ đã giải phóng điều ước của bạn';

  @override
  String get notifFarewellBody =>
      'Đã 30 ngày trôi qua. Điều ước ấy đã tan vào vũ trụ. Hãy gửi điều ước mới nếu bạn muốn.';

  @override
  String get wishLabel => 'Điều ước:';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String hoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String daysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get prophecy => 'Lời tiên tri';

  @override
  String get prophecySignsLabel => 'Dấu hiệu cần chú ý';

  @override
  String get prophecyActionLabel => 'Một việc nhỏ hôm nay';

  @override
  String get prophecyAffirmationLabel => 'Lời khẳng định';

  @override
  String get reflectNow => 'Suy ngẫm';

  @override
  String get reflectTitle => 'Một vài ngày đã trôi qua…';

  @override
  String get reflectNoteHint => 'Ghi lại điều ngươi nhận ra…';

  @override
  String get reflectMoodLabel => 'Ngươi đang cảm thấy thế nào?';

  @override
  String get reflectOutcomeLabel => 'Điều ước đang thành hiện chứ?';

  @override
  String get reflectSave => 'LƯU LẠI';

  @override
  String get reflectSkip => 'Để sau';

  @override
  String get reflectSaved => 'Đã lưu suy ngẫm';

  @override
  String get moodHopeful => 'Hy vọng';

  @override
  String get moodPeaceful => 'Bình an';

  @override
  String get moodRestless => 'Bồn chồn';

  @override
  String get moodSad => 'Buồn';

  @override
  String get moodGrateful => 'Biết ơn';

  @override
  String get outcomeFulfilled => 'Có, theo cách riêng';

  @override
  String get outcomePartial => 'Một phần';

  @override
  String get outcomeUnfulfilled => 'Chưa';

  @override
  String get journeyReflected => 'Đã suy ngẫm';

  @override
  String get journeyPending => 'Đang chờ';

  @override
  String reflectedNudge(int count) {
    return '$count điều ước đang chờ một khoảnh khắc lắng đọng';
  }

  @override
  String get open => 'MỞ';

  @override
  String get tryAgain => 'Hãy thử lại';

  @override
  String get categoryLove => 'Tình yêu';

  @override
  String get categoryCareer => 'Sự nghiệp';

  @override
  String get categoryHealth => 'Sức khỏe';

  @override
  String get categoryFamily => 'Gia đình';

  @override
  String get categoryOther => 'Khác';

  @override
  String get categoryLoveDesc => 'Tình yêu và mối quan hệ';

  @override
  String get categoryCareerDesc => 'Công việc và thành công';

  @override
  String get categoryHealthDesc => 'Sức khỏe thể chất và tinh thần';

  @override
  String get categoryFamilyDesc => 'Gia đình và những người thân yêu';

  @override
  String get categoryOtherDesc => 'Điều ước khác trong vũ trụ';

  @override
  String get aiReflectionEyebrow => 'TRƯỚC KHI VŨ TRỤ HỒI ĐÁP';

  @override
  String get aiReflectionHint => 'Viết điều vừa hiện lên trong tâm trí ngươi…';

  @override
  String get aiReflectionRequired => 'Hãy chia sẻ một điều trước khi tiếp tục.';

  @override
  String get aiReflectionCta => 'LẮNG NGHE LỜI TIÊN TRI';

  @override
  String get privacy => 'QUYỀN RIÊNG TƯ';

  @override
  String get shareAnonymousWishes => 'Chia sẻ điều ước với cộng đồng';

  @override
  String get shareAnonymousWishesSubtitle =>
      'Khi bật, điều ước mới sẽ được đăng công khai mà không kèm danh tính';

  @override
  String get adminLoginTitle => 'Cổng quản trị';

  @override
  String get adminPasswordHint => 'Mật khẩu quản trị';

  @override
  String get adminLoginButton => 'MỞ CỔNG';

  @override
  String get adminLoginFailed => 'Mật khẩu không đúng.';

  @override
  String get adminRateLimited => 'Đã thử quá nhiều lần. Thử lại sau 5 phút.';

  @override
  String get adminNotConfigured => 'Máy chủ chưa đặt mật khẩu quản trị.';

  @override
  String get adminTitle => 'Quản trị';

  @override
  String get adminMode => 'Nguồn cấu hình';

  @override
  String adminModeDatabase(Object time) {
    return 'Database · cập nhật $time';
  }

  @override
  String get adminModeFallback => 'Mặc định máy chủ (env)';

  @override
  String get adminPreset => 'Nhà cung cấp';

  @override
  String get adminPresetCustom => 'Tùy chỉnh';

  @override
  String get adminBaseUrl => 'Base URL';

  @override
  String get adminModel => 'Tên model';

  @override
  String get adminApiKey => 'API key';

  @override
  String adminApiKeyKeep(Object masked) {
    return 'Để trống để giữ key hiện tại ($masked)';
  }

  @override
  String get adminApiKeyNone => 'Chưa có key nào được cấu hình';

  @override
  String get adminTestConnection => 'KIỂM TRA KẾT NỐI';

  @override
  String get adminTesting => 'Đang thử kết nối…';

  @override
  String adminTestOk(Object latency) {
    return 'Kết nối OK · $latency ms';
  }

  @override
  String get adminTestFailed => 'Không kết nối được';

  @override
  String get adminSave => 'LƯU CẤU HÌNH';

  @override
  String get adminSaved => 'Đã lưu cấu hình';

  @override
  String get adminReset => 'Về mặc định máy chủ';

  @override
  String get adminResetConfirmTitle => 'Xóa cấu hình?';

  @override
  String get adminResetConfirmMessage =>
      'Quay về cấu hình mặc định trên máy chủ (env secret).';

  @override
  String get adminNetworkError => 'Lỗi mạng. Kiểm tra kết nối và thử lại.';

  @override
  String get adminSessionExpired => 'Phiên đã hết hạn. Đăng nhập lại.';

  @override
  String updateAvailableTitle(String version) {
    return 'Đã có phiên bản $version';
  }

  @override
  String get updateWhatsNew => 'Có gì mới';

  @override
  String get updateNow => 'CẬP NHẬT NGAY';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateSkipVersion => 'Bỏ qua phiên bản này';

  @override
  String updateDownloading(int percent) {
    return 'Đang tải về… $percent%';
  }

  @override
  String get updateInstallConsent =>
      'Android sẽ hỏi cho phép Cosmic Wish cài ứng dụng. Bạn chỉ cần cho phép một lần, bản cập nhật sẽ tự cài.';

  @override
  String get updateFailed => 'Tải về thất bại. Kiểm tra kết nối rồi thử lại.';

  @override
  String get updateRetry => 'Thử lại';

  @override
  String get updateUpToDate => 'Bạn đang dùng phiên bản mới nhất.';

  @override
  String get updateCheckButton => 'Kiểm tra cập nhật';
}
