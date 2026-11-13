import '../story/story.dart';
import 'l10n.dart';

const _e = Spk.essen, _so = Spk.soun, _ts = Spk.tsuru, _ho = Spk.hotaru;
const _re = Spk.rendo, _ma = Spk.masakage, _hi = Spk.hint, _un = Spk.unknown;

const storyAz = StoryText(
  s: {
    'tagline': 'Dəmirdən doğulan kölgə',
    'ch1.title': 'Dumanın külü',
    'ch2.title': 'Bambukda pıçıltılar',
    'ch3.title': 'Polad ləçəklər',
    'ch4.title': 'Dəmir Əjdahanın qalası',
    'c1.o1': 'Kasumi kəndinə qayıt',
    'c1.o2': 'Dəmir Əjdaha talançılarını Kasumidən qov',
    'c1.o3': 'Uçmuş dojonun yanında Usta Sounu tap',
    'c2.o1': 'Bambuk meşəsində Dəmir Əjdahanın hərbi düşərgəsini tap',
    'c2.o2': 'Düşərgə keşikçilərini susdur',
    'c2.o3': 'Komandirin masasından hərbi əmrləri oğurla',
    'c3.o1': 'Vergi yığanları Hanamuradan qov',
    'c3.o2': 'Evində Tsuru nənə ilə danış',
    'c3.o3': 'Hotarunun izi ilə get — gizlətdiyi qeydləri tap',
    'c3.o4': 'Sakura məbədində General Takeşi Rendo ilə üz-üzə gəl',
    'c4.o1': 'Dəmir Əjdahanın qalasına yaxınlaş',
    'c4.o2': 'Darvaza keşikçilərini yarıb keç',
    'c4.o3': 'Hotarunu qəfəsdən azad et',
    'c4.o4': 'Hökmdar Tetsuryu Masakageni məğlub et',
    'ending.mercy.title': 'Mərhəmətli əl',
    'ending.vengeance.title': 'Kölgənin ədaləti',
    'codex.essen.title': 'Essen',
    'codex.essen.text':
        'Kasumi-gakurenin iyirmi bir yaşlı şinobisi. Xarici gəmi qəzasından sonra körpə ikən tapılıb; üzərində "ESSEN" sözü tikilmiş bir parçaya bükülmüşdü və Usta Soun ona bu adı verdi. Solğun, dəniz-boz gözlərinə görə kənd uşaqları onu "balaca ruh" çağırırdılar. Bütün ömrünü dənizin övladının da dumana aid ola biləcəyini sübut etməyə həsr edib.',
    'codex.kasumi.title': 'Kasumi-gakure',
    'codex.kasumi.text':
        'Dumanda gizlənən kənd — bacarıqlarını yalnız zəifləri qoruyanlara satan kiçik şinobi klanının yurdu. Qurucuları "Fənər andı" içmişdilər: yatmış kəndə heç vaxt hücum etməmək, tarlaları yandıran hökmdara heç vaxt xidmət etməmək. Bir gecədə Dəmir Əjdaha klanı tərəfindən yerlə-yeksan edildi.',
    'codex.soun.title': 'Kiriya Soun',
    'codex.soun.text':
        'Kasumi-gakurenin ustası və Essenin ögey atası. Sakit, səbirli, durnaları və pis şeirləri sevən adam. İyirmi bir il əvvəl kəndə bir körpə ilə, keçmişi olmadan gəldi və onun ən böyük müəllimi oldu. Bir zamanlar kim olduğunu etiraf edə bilmədən öldü.',
    'codex.masakage.title': 'Tetsuryu Masakage',
    'codex.masakage.text':
        'Tetsuryu — Dəmir Əjdaha klanının daymiosu. Parlaq zəkalı, səbirli və tamamilə mərhəmətsizdir; inanır ki, müharibə dövrünü cəsarət yox, dəmir və od qazanacaq. İyirmi ildir xarici "ildırım silahlarını" gizlicə düzəltməyə çalışır və hər dəfə uğursuz olur.',
    'codex.irondragon.title': 'Dəmir Əjdaha klanı',
    'codex.irondragon.text':
        'Homuranın dəmir mədənlərindən yüksələn samuray klanı. Döyüşçüləri qırmızı laklı zireh və qara əjdaha gerbi daşıyır. Masakagenin dövründə klan qalanın altındakı gizli dəmirçixananı doyurmaq üçün vilayəti vergilərlə soyub.',
    'codex.rendo.title': 'Takeşi Rendo',
    'codex.rendo.text':
        'Masakagenin generalı, "Əyilməz qılınc" adlanır. Qaçan adamı heç vaxt vurmaması və sözünü heç vaxt pozmaması ilə bütün vilayətdə tanınır. Sadiq döyüşçülərindən ibarət kiçik dəstə ilə məbəd yolunu qoruyur.',
    'codex.rendo2.title': 'Rendonun utancı',
    'codex.rendo2.text':
        'On yeddi yaşında Rendo Morgenrotun batdığı gecə Kurogane sahilində dayanmış və hökmdarı sağ qalanları qırarkən heç nə etməmişdi. O vaxtdan bəri Masakageyə xidmət edir, tutulan andın vicdana tabe olmaqdan daha qiymətli olduğuna inanırdı. Essenin məbəddəki mərhəməti bu inamı qırdı.',
    'codex.tsuru.title': 'Tsuru nənə',
    'codex.tsuru.text':
        'Hanamuralı balıqçı dul qadını, səksən yaşını keçib. Qəza gecəsi Sounu və körpə Esseni daldalandırdı və iyirmi bir il bu sirri saxladı. Samuraylardan qorxmaq üçün çox qoca olduğunu deyir. Görünür, bu, doğrudur.',
    'codex.wreck.title': 'Morgenrotun qəzası',
    'codex.wreck.text':
        'Uzaq qərb dənizlərindən gələn xarici ticarət gəmisi tayfunda Kurogane qayalarına çırpılaraq batdı. Gəmidə Essen şəhərindən olan usta dəmirçi Heinrich, həyat yoldaşı Marqarete və yeni doğulmuş oğulları var idi. Masakage Heinrichin polad hazırlama dəftərini ələ keçirdi, lakin son səhifələri heç vaxt tapılmadı — onlar körpənin bələyinə tikilmişdi.',
    'codex.note1.title': 'Hotarunun I qeydi',
    'codex.note1.text':
        'Qolundan qopardığı zolağa kömürlə yazılıb: "Məni qalaya aparırlar. Qırx atlı saydım. Masakage mənə düyü çəkən tacir kimi baxdı."',
    'codex.note2.title': 'Hotarunun II qeydi',
    'codex.note2.text':
        '"Masakagenin qalanın altında dəmirçixanası var. Hanamuranın kişiləri orada zəncirlə işləyir, ildırım silahları düzəldir. Amma lülələr çatlayır. Deyir ki, son sirr yadellinin parçasındadır. SƏNİN parçanda."',
    'codex.note3.title': 'Hotarunun III qeydi',
    'codex.note3.text':
        '"Bu, tələdir. Mənim dalımca gəlmə. ...Amma gələcəksən. Həmişə gəlirsən, balaca ruh. Onda səssiz gəl."',
    'codex.hotaru.title': 'Hotaru',
    'codex.hotaru.text':
        'Kasumi kəndxudasının qızı və Essenin and içmiş bacısı. Nəslinin ən yaxşı kunoiçisi — cəld, dili iti və qorxmaz. Kənddə Essenə ilk "qardaş" deyən uşaq o idi və buna ilk gülənin burnunu sındırdı.',
    'codex.letter.title': 'Heinrichin məktubu',
    'codex.letter.text':
        'Parçanın içində, tigel sobasının çertyojlarının altında yad dildə məktub qatlanmışdı. Bir gün paytaxtda portuqaliyalı bir keşiş onu tərcümə edəcəkdi: "Oğlum, polad nə yaxşıdır, nə pis. O, yalnız onu tutan əldir. Əgər bunu nə vaxtsa oxusan, mərhəmətli əl ol. Atan, Heinrich."',
  },
  p: {
    'ch1.intro': [
      'Homura vilayəti, döyüşən knyazlıqlar dövrü.',
      'İyirmi bir qış əvvəl xarici bir gəmi Kurogane sahilinin qara qayalarında parçalandı. Dəniz yalnız bir sağ qalanı geri verdi: yeganə yad sözün tikildiyi parçaya bükülmüş körpəni.',
      'ESSEN.',
      'Kasumi-gakurenin — Dumanda gizlənən kəndin şinobiləri uşağı öz balaları kimi böyütdülər. Ona səssiz yeriməyi, eşidilmədən nəfəs almağı, iki fənər arasındakı kölgəyə çevrilməyi öyrətdilər.',
      'Bu gecə Essen şimaldakı tapşırıqdan qayıdır. Küləkdə tüstü iyi duyur.',
    ],
    'ch1.outro': [
      'Usta Soun sübhə hələ saatlar qalmış, son sözlərini deyə bilmədən dünyasını dəyişdi.',
      'Essen onu kənd uşaqlarının ilk düyünlərini öyrəndiyi xatirə daşının altında dəfn etdi. Köhnə parçanı biləyinə doladı — adını daşıyan, dənizin ona verdiyi yeganə şeyi.',
      'Bambuk meşəsinin o tayında bir yerdə Dəmir Əjdaha Hotarunu öz qalasına sürükləyirdi.',
      'Şinobi yas tutmur. Şinobi izi izləyir.',
    ],
    'ch2.intro': [
      'Sübh vadiyə boz və səssiz süründü — kül rəngində.',
      'Atların və zirehli adamların izləri şərqə, Dəmir Əjdahanın Homura yollarını boğmaq üçün hərbi düşərgə qurduğu böyük bambuk meşəsinə aparırdı.',
      'Düşərgə varsa, komandir var. Komandir varsa, əmrlər var. Əmrlər isə Hotarunun hara aparıldığını deyəcək.',
    ],
    'ch2.outro': [
      'Əmrlərin üzərində qan-qırmızı lakla Dəmir Əjdahanın möhürü vardı.',
      '"Kunoiçi qalaya diri çatdırılmalıdır. Yadelli uşaq onun ardınca gələcək — qoy gəlsin. Dəmirçixana yeni aya qədər doydurulmalıdır. Məbəd yolunu General Rendo saxlayır."',
      'Yadelli uşaq. Essen sözləri üç dəfə oxudu və yalnız sonra onların özü haqqında olduğunu anladı.',
      'Bir də dəmirçixana. Hansı dəmirçixanaya o lazım ola bilərdi?',
    ],
    'ch3.intro': [
      'Çayın o tayında Hanamura — müharibə illərində belə albalı ağaclarının çiçək açdığı Çiçəklər kəndi yerləşir.',
      'Orada qoca Tsuru yaşayır — balıqçı dul qadın; deyilənə görə, bir vaxtlar böyük fırtına gecəsi bir samurayı və ağlayan körpəni daldalandırıb.',
      'Daha şərqdə, Sakura məbədinin təpəsində General Takeşi Rendo gözləyir. Deyirlər, onun qılıncı heç vaxt namussuzluqla qınından çıxmayıb.',
    ],
    'ch3.outro': [
      'Essen gözdən itənə qədər Rendo yerindən qalxmadı. Albalı ləçəkləri qar kimi zirehinin üstünə qonurdu.',
      'Essen cənuba, qalaya doğru getdi; ürəyində istənilən qılıncdan ağır bir həqiqət daşıyırdı: onu böyüdən usta bir zamanlar Dəmir Əjdahanın gerbini taxmışdı, valideynlərini isə dəniz almamışdı.',
      'Bir insan almışdı.',
    ],
    'ch4.intro': [
      'Günəş qərb dağlarına qan kimi axır. Cənub təpələrinin üstündə Dəmir Əjdahanın qalası qırmızı səmanın fonunda qapqara dayanıb; daşın altındakı dəmirçixanaları tüstü püskürür.',
      'Toranlıqda Hotaru öləcək.',
      'Essen biləyindəki parçanı bərk sıxır — anasının tikişləri, atasının sirri, ustasının günahı — və darvazaya doğru yeriyir.',
    ],
    'ch4.outro': [],
    'ending.mercy': [
      'Essen qılıncını endirdi.',
      '"Ustam ömrünü bir gecəlik itaətin əvəzini ödəməyə sərf etdi. Mən öz ömrümü bir gecəlik qəzəbin əvəzini ödəməyə sərf etməyəcəyəm."',
      'General Rendo toranlıqda döyüşçüləri ilə gəldi — döyüşmək üçün yox, öz hökmdarını zəncirləyib Şoqunun mühakiməsinə təhvil vermək üçün.',
      'O gecə soyumuş dəmirçixananın yanında Essen nəhayət anasının parçasının tikişlərini sökdü. İçində dua kimi xırda qatlanmış, oxuya bilmədiyi dildə bir məktub və dağları çatladacaq polad çertyojları vardı.',
      'Məktubu saxladı. Çertyojları yandırdı.',
      'Yazda Kasumi yenidən tikildi; meydanında yan-yana iki ad həkk olunmuş yeni bir daş ucalır: Kiriya Soun və Essenli Heinrich.',
      'Kölgə mərhəməti seçdi. Duman isə bunu unutmadı.',
    ],
    'ending.vengeance': [
      'Qılınc bir dəfə endi və Dəmir Əjdaha artıq yox idi.',
      'Qala üç gün yandı. Rendo külün qarşısında diz çökdü və and içdi ki, daha heç bir hökmdar onun qılıncına əmr verməyəcək.',
      'O gecə soyumuş dəmirçixananın yanında Essen anasının parçasının tikişlərini sökdü. İçində oxuya bilmədiyi dildə bir məktub və dağları çatladacaq polad çertyojları vardı.',
      'İkisini də yandırdı — məktubun sözləri bilinmədən tüstüyə qarışdı.',
      'Hotaru Kasumini yenidən tikdi. Essen hər tirin qaldırılmasına kömək etdi, sonra isə dumanlı bir səhər sadəcə yoxa çıxdı.',
      'Şimal yollarının yolçuları hələ də güclülər zəiflərə zülm edəndə peyda olan və təşəkkür eşitməmiş yoxa çıxan açıq gözlü bir kölgədən danışırlar.',
      'Kölgə ədaləti seçdi. Qalanını duman daşımalı olacaqdı.',
    ],
  },
  d: {
    'c1.o1.before': [
      DialogLine(_e, 'Təpənin üstündəki o parıltı... ay deyil. Kasumi yanır.'),
      DialogLine(_hi, 'Hərəkət üçün ekranın sol tərəfində sürüşdür — qaçmaq üçün çubuğu sona qədər it. Kameranı Essenin ətrafında fırlatmaq üçün sağ tərəfdə sürüşdür.'),
    ],
    'c1.o1.after': [
      DialogLine(_e, 'Duman darvazası... sınıb. Tanıdığım hər ev közə dönüb.'),
      DialogLine(_e, 'Dəmir Əjdaha gerbləri. Tetsuryu klanının samurayları — hələ də buradadırlar, ölülərimizi eşələyirlər.'),
    ],
    'c1.o2.before': [
      DialogLine(_hi, 'Görünmədən hərəkət etmək üçün ÇÖMƏL düyməsini bas. Samurayın başı üstündə fırlanan sarı daş onun şübhələndiyini, qırmızı "!" isə səni tapdığını bildirir.'),
      DialogLine(_hi, 'Xəbərsiz düşmənə arxadan vur — KÖLGƏ ZƏRBƏSİ onu dərhal öldürür. Uzaqdan ŞURİKEN at. TÜSTÜ bombası ətrafdakı bütün düşmənləri kor edir.'),
    ],
    'c1.o2.after': [
      DialogLine(_e, 'Heç biri bu kəndin kimliyinə tay deyildi. Çoxluqla, gecə, oğru kimi gəldilər.'),
      DialogLine(_un, '...Essen... bu sənin... addımlarındır? Həmişəki kimi yüngül...'),
      DialogLine(_e, 'Usta! Usta Soun — dojonun yanında!'),
    ],
    'c1.o3.after': [
      DialogLine(_e, 'Usta, tərpənmə. Yaraya baxım—'),
      DialogLine(_so, 'Burax. Qoca durna qışın sonuncu olduğunu bilir.'),
      DialogLine(_so, 'Toranlıqda gəldilər. Tetsuryu Masakagenin özü də onlarla idi. Qızıl üçün yox, torpaq üçün yox... sənin üçün gəldilər, Essen.'),
      DialogLine(_e, 'Mənim üçün? Mən dənizin yetimiyəm. Dəmir Əjdaha adsız birindən nə istəyə bilər—'),
      DialogLine(_so, 'Sən adsız deyilsən. Bunu heç vaxt demə.'),
      DialogLine(_so, 'Paltarımdan bu parçanı götür. Dəniz səni gətirən gecə ona bükülmüşdün. O hərfləri anan tikib. "Essen." Bu, atanın gəldiyi yerin adıdır, dünyanın o başında.'),
      DialogLine(_so, 'Masakage Hotarunu apardı. O, on nəfərimiz kimi vuruşdu. Onu diri saxlayır, çünki bilir ki, sən gələcəksən.'),
      DialogLine(_e, 'Onda gələcəyəm. Və o, kölgənin nəyə başa gəldiyini öyrənəcək.'),
      DialogLine(_so, 'Qulaq as... sənə çoxdan deməli olduğum bir şey var. O sahil gecəsi haqqında. Dumandan əvvəl... kim olduğum haqqında...'),
      DialogLine(_so, 'Bağışla... məni...'),
      DialogLine(_e, 'Usta? ...Usta Soun!'),
      DialogLine(_e, '...'),
      DialogLine(_e, 'Dincəl. Onu tapacağam. Mənə geri qaytardığın ada and içirəm.'),
    ],
    'c2.o1.before': [
      DialogLine(_e, 'Bambuk şinobini istənilən gecədən yaxşı gizlədir. Gövdələrdəki külək addımlarımı örtəcək.'),
    ],
    'c2.o1.after': [
      DialogLine(_e, 'Döyüş pərdələri, qırmızı bayraqlar, postlarında mürgüləyən keşikçilər. Təkəbbürlüdürlər. Kasumidən kiminsə sağ qaldığına inanmırlar.'),
    ],
    'c2.o3.after': [
      DialogLine(_e, 'Möhürlü məktub... qalanın özündən.'),
      DialogLine(_e, '"Kunoiçi diri çatdırılmalıdır. Yadelli uşaq onun ardınca gələcək — qoy gəlsin."'),
      DialogLine(_e, '"Dəmirçixana yeni aya qədər doydurulmalıdır. Məbəd yolunu General Rendo öz döyüşçüləri ilə saxlayır."'),
      DialogLine(_e, 'Məni ovlamırlar. Məni qovurlar. Yaxşı, Masakage. Kölgə sənin yolunla gedəcək — amma gözlədiyin kimi yox.'),
    ],
    'c3.o1.before': [
      DialogLine(_e, 'Hanamurada samuraylar anbarlardan düyü kisələrini sürüyür. Kəndlilər palçıqda diz çöküb heç nə demirlər.'),
    ],
    'c3.o2.after': [
      DialogLine(_ts, 'O açıq gözlər... qışda dənizin rəngi. Deməli, balaca sağ qalıb. Gəl, otur. Dizlərim bu kənddən qocadır.'),
      DialogLine(_e, 'Məni tanıyırsan, nənə?'),
      DialogLine(_ts, 'Səni bu torpaqda hamıdan əvvəl qucağıma almışam. İyirmi bir il əvvəl xarici gəmi qara qayalara çırpıldı. Adı yanına yazılmışdı — "Morgenrot". Səhər qırmızısı.'),
      DialogLine(_ts, 'Çoxu sahilə sağ çıxdı. Dənizçilər. Saçları saman kimi bir qadın. Və əlləri yanıq, iri, mülayim bir kişi — dəmirçi. Ona Heinrich deyirdilər.'),
      DialogLine(_ts, 'Sonra gənc ağa Masakage adamları ilə sahilə endi. Yadellilərin od silahlarını istəyirdi. İstəyirdi ki, dəmirçi onun dəmirçixanalarına polad sirrini öyrətsin.'),
      DialogLine(_ts, 'Dəmirçi rədd etdi. Dedi ki, onun dəmiri kəndləri yandırmaq üçün işlədilməyəcək. Onda Masakage çertyoj kitabını aldı... və sahildəki hər kəsin qılıncdan keçirilməsini əmr etdi.'),
      DialogLine(_e, '...Atam. Anam.'),
      DialogLine(_ts, 'Anan səni qucağında saxlaya-saxlaya öldü. Bir samuraya uşağı da öldürmək əmr olundu. O, uzun müddət yağışda dayandı. Sonra səni götürüb qaçdı.'),
      DialogLine(_ts, 'Fırtına keçənə qədər mənim daxmamda gizləndi. Qolunda Dəmir Əjdahanın gerbi vardı və uşaq kimi ağlayırdı.'),
      DialogLine(_ts, 'Onun adı Kiriya Soun idi.'),
      DialogLine(_e, '...Ustam. O da onlardan biri idi.'),
      DialogLine(_ts, 'İdi. Sonra isə olmadı. İnsan utandığı o bir gecədən daha böyükdür, balam. Mühakimə etməzdən əvvəl bunu yadda saxla.'),
      DialogLine(_ts, 'Apardıqları qız iki gün əvvəl atın üstündə bağlı halda buradan keçdi. Yolun kənarına qəsdən nəsə atdı — bunu edəndə gülümsədiyini gördüm. Məbədə gedən yolla get.'),
    ],
    'note1': [
      DialogLine(_ho, '"Qardaş — bunları kimsə tapacaqsa, o sənsən. Məni qalaya aparırlar. Qırx atlı saydım. Masakage mənə düyü çəkən tacir kimi baxdı."'),
    ],
    'note2': [
      DialogLine(_ho, '"Çayın yanında danışdıqlarını eşitdim. Masakagenin qalanın altında dəmirçixanası var. Hanamuranın kişiləri orada zəncirlə işləyir, ildırım silahları düzəldir — yüz addımdan öldürən yadelli silahları."'),
      DialogLine(_ho, '"Amma lülələr çatlayır. Həmişə çatlayır. Deyir ki, son sirr yadellinin parçasındadır. SƏNİN parçanda, Essen."'),
    ],
    'note3': [
      DialogLine(_ho, '"Bu, tələdir. Mənim dalımca gəlmə. ...Amma gələcəksən. Həmişə gəlirsən, balaca ruh. Onda səssiz gəl."'),
    ],
    'c3.o3.after': [
      DialogLine(_e, 'Parça... Masakage Kasumini biləyimdəki bir tikə parça üçün yandırdı.'),
      DialogLine(_e, 'Onda parça məndə qalır. Cənuba yeganə yol isə məbəd yoludur.'),
    ],
    'c3.o4.before': [
      DialogLine(_re, 'Deməli, Kasuminin kölgəsi. Yaxşı hərəkət edirsən — keşikçilərim, deyəsən, hələ də otun içində yatırlar, boğazları salamat. Bu, bir mərhəmət idi.'),
      DialogLine(_e, 'Yol ver, General. Səninlə davam yoxdur.'),
      DialogLine(_re, 'Səninlə mənim davam yoxdur. Amma mənim hökmdarım və andım var. Keçmək istəyirsənsə, qılıncımın içindən keç. Çək.'),
    ],
    'c3.o4.after': [
      DialogLine(_re, 'Bəsdir... təslim oluram. İyirmi ildə ilk dəfə.'),
      DialogLine(_re, 'İstəyirsənsə, işi bitir. Bu, sənin haqqındır.'),
      DialogLine(_e, 'Mən buraya namuslu adamların canını almağa gəlməmişəm.'),
      DialogLine(_re, '...Namuslu. Mən o sahildə idim, oğlan. On yeddi yaşında əlimdə məşəl tutmuşdum, hökmdarım isə gəmisi batmış dənizçiləri doğrayırdı. Heç nə etmədim.'),
      DialogLine(_re, 'Kiriya Sounun əmri yerə atıb səni fırtınaya apardığını gördüm. Masakage onu xain elan etdi. Mən onu axmaq adlandırdım. Axmaq mən idim.'),
      DialogLine(_re, 'Andım qılıncımı bağlayır — gözlərimi yox, dilimi yox. Bacın qalanın həyətində qəfəsdədir. Masakage parçanı ona verəsən deyə onu toranlıqda gözünün qabağında edam etmək istəyir.'),
      DialogLine(_re, 'Şimal darvazasında adamlarımı sənə qarşı qaldırmayacağam. Məndə olan xəyanətin hamısı budur. Get.'),
    ],
    'c4.o1.after': [
      DialogLine(_e, 'Şimal darvazası. Rendo sözünü tutdu — yalnız qalanın öz keşikçiləri növbədədir. Onlar kifayət etməli olacaq.'),
    ],
    'c4.o3.after': [
      DialogLine(_ho, 'Çox gecikdin, balaca ruh. Sənə kor öküzün də izləyə biləcəyi bir iz qoymuşdum.'),
      DialogLine(_e, 'Qeydlərin çox... ruhlandırıcı idi. "Gəlmə."'),
      DialogLine(_ho, 'Və yenə də gəldin. Axmaq.'),
      DialogLine(_ho, 'Qulaq as — Hanamuranın kişiləri aşağıdakı dəmirçixanada zəncirdədir. Masakage səninlə məşğul olarkən onları azad edə bilərəm. O gəlir. Bütün ömrü boyu bunu gözləyib.'),
      DialogLine(_ma, 'Elədir.'),
    ],
    'c4.o4.before': [
      DialogLine(_ma, 'Dənizin balaca hədiyyəsi. Biləyindəki o parçanı nə qədər axtardığımı bilirsənmi? İyirmi bir il çatlamış lülələr və hədər gedən dəmir.'),
      DialogLine(_e, 'Bunun üçün uşaqlarla dolu bir kəndi yandırdın.'),
      DialogLine(_ma, 'Mən oğru yuvasını yandırdım. Sənin Sounun səni məndən oğurladı. Parçanı ver, bacının yanında tez ölərsən.'),
    ],
    'c4.o4.mid': [
      DialogLine(_ma, 'Ha... onun kimi vuruşursan. Soun kimi. Vicdanı oyanmamışdan əvvəl o sahildə nə etdiyini sənə heç danışıbmı?'),
      DialogLine(_ma, 'Atanın üç dənizçisini öz əlləri ilə qılıncdan keçirdi. Mənim ən yaxşı qılıncım idi — o küçük ağlayana qədər.'),
      DialogLine(_e, 'Onda iyirmi bir il bunun əvəzini ödədi. Sən nə ödəmisən, Masakage?'),
    ],
    'c4.o4.after': [
      DialogLine(_ma, 'Mümkün deyil... yadelli bir küçükdən məğlub oldum... öz həyətimdə...'),
      DialogLine(_ma, 'Haydı. İntiqamını al. Bu dünyada qalan yeganə dürüst şey odur.'),
      DialogLine(_ho, 'Essen! Dəmirçixana açıqdır — kişilər azaddır! ...Qardaş? Nə edəcəksən?'),
      DialogLine(_e, '...', choices: ['Bağışla — qoy Şoqun mühakimə etsin', 'Sonunu gətir — Kasumi üçün']),
    ],
  },
);
