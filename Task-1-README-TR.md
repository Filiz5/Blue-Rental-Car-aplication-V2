# DevOps Projesi TASK-1: Terraform ve Jenkins ile AWS'de Modüler Sanal Makine Oluşturma

## Amaç
Bu proje, AWS üzerinde Terraform kullanarak modüler sanal makineler oluşturmayı ve bu süreci Jenkins ile otomatize etmeyi içermektedir. Testing, development, staging ve production gibi farklı ortamlar için workspace'leri kullanarak otomatik yapılandırmalar yapacağız.

## Gereksinimler
- AWS hesabı
- Terraform
- Jenkins
- Git ve GitHub (veya benzeri bir versiyon kontrol sistemi)

## Adım Adım Görevler

### 1. Proje Yapısının Kurulması
- **1.1.** GitHub'da bir repo oluşturun. Bu repo, Terraform konfigürasyonlarınızı ve Jenkinsfile'ınızı içerecek.
- **1.2.** Repo'yu lokal bilgisayarınıza klonlayın.

### 2. Terraform Docyalarının Oluşturulması
- **2.1.** Her ortam için (test, dev, staging, prod) bir Terraform workspace oluşturun. Bu sayede tek bir Terraform yapılandırması ile farklı ortamlar için ayrı yapılandırmalar yapabilirsiniz. 
- **2.2.** Her ortam için giriş değişkenleri tanımlayın (örn: instance tipi, boyutu, ortam adı).
- **2.3.** Oluşturulan kaynakların detaylarını vermek için çıkış değişkenleri kullanın (örn: EC2 instance'larının IP adresleri).

### 3. Jenkins Kurulumu ve Yapılandırılması
- **3.1.** Bir EC2 instance üzerinde Jenkins kurun.
- **3.2.** EC2 instance üzerinde Terraform kurun.
- **3.3.** Jenkins içinde yeni bir pipeline oluşturun ve GitHub repo'nuzla entegre edin.

### 4. Jenkins Pipeline'ının Oluşturulması
- **4.1.** `Jenkinsfile` oluşturarak pipeline'ınızı tanımlayın. Pipeline, Önce EC2 lar için projeye özel AWS CLI ile Key Pairs oluşturacak sonrasında Terraform plan ve apply komutlarını çalıştıracaktır.
- **4.2.** Pipeline içinde, Terraform'ın hangi ortam için çalıştırılacağını belirten parametreler ekleyin.
- **4.3.** Otomatik tetikleyiciler kurarak GitHub'daki değişiklikler sonrası Jenkins'in pipeline'ı çalıştırmasını sağlayın.

### 5. Test ve Doğrulama
- **5.1.** Terraform modüllerinizin çalıştığını doğrulamak için her ortam için `terraform apply` komutunu çalıştırın.
- **5.2.** EC2 instance'ların başarılı bir şekilde oluşturulup oluşturulmadığını kontrol edin.
- **5.3.** Jenkins pipeline'ının düzgün çalışıp çalışmadığını ve otomatik olarak tetiklenip tetiklenmediğini test edin.

### 6. Dokümantasyon ve Raporlama
- **6.1.** Projede kullanılan her bir adımı ve yapılandırmayı detaylı bir şekilde dokümante edin.
- **6.2.** Karşılaştığınız zorlukları ve çözümleri raporlayın.
- **6.3.** Sonuç olarak, oluşturulan kaynakların detaylarını içeren bir rapor hazırlayın.

# Adimlar sunlar:

Projeye ilk olarak bir main.tf sablonu olusturmakla basladik. Daha sonra bu sablonun lokalde calistirip sonrasinda detaylandirdik. Once kendi key.pair imizle workspace lerimizi olusturduk. Amacimizi workspace lerin saglikli bir sekilde olusup olusmadigini gorebilmekti. 
Daha sonra her bir workspace icin bir keypair olusturduk. Bunu manuel aws consoldan yaptik. Bu sekilde de istedigimiz izole ortamlari olusturabildik.
Bu main.tf dosyamizi calistiracak ve otomatize edecek bir Jenkinsfile olusturduk. Bunlari gitHub da bir repaya gonderdik.
Bize verilen main-server klasoru ile bir jenkins-server makinesi kaldirarak Jenkins arayuzunu actik.  Sonra da main.tf ve Jenkins dosyalarini calistirdik.
Bu dosyalirin pipeline saglikli sekilde calistiklarini gorduk: Yani parametreler calisdi ve her bir workspace icin bir makine kaldirabildik. 

Aslinda bize verilen task i tamamlamistik ama bir de sunu denemek istedik: jenkinsfile olmadan sadece main.tf dosyasini kullanarak manuel parametreleri
kullanmayi denedik. Ve bunu da basardik. 

# Zorluklar ve cozumleri:

Aslinda ilk asamalar cok zor olmadi. Main.tf sablonunu olusturdukdan sonra aldigimiz hatalarla duzeltmeler yaparak basit bir main.tf olusturduk. 
Daha sonrasinda jenkinsfile yazmak cok kolay oldu. Bizi ugrastiran kisim Jenkinsfile olamadan parametreleri kullanma kismi oldu. Orada execute shell de 
dogru komutlari yazmamiz gerekiyordu. Yani Jenkins file yazdigimiz otomasyon kodlarini buraya entegre etmemiz gerekiyordu. Bu bizi biraz zorladi. 
Keypair olusturan kodu jenkins calistirmiyordu. Kodda yaptigimiz duzeltmelerle bunu basardik. Sonrasinda yine bir boolean parametresi ekleyerek destroy yaptirmayi denedik.
Bu da biraz vakit aldi. execute sheel de dogru komutlari ekleyerek bu asamayida basardik. Bu kodu soyle idi:
--------
# EXECUTE SHELL KODU
WORKSPACE_NAME=$(basename "$WORKSPACE")
echo "Seçilen çalışma alanı: ${WORKSPACE_NAME}"
terraform workspace select "${WORKSPACE_NAME}" || terraform workspace new "${WORKSPACE_NAME}"

KEY_NAME="${WORKSPACE_NAME}-key"
if ! aws ec2 describe-key-pairs --key-name "$KEY_NAME" --region us-east-1 >/dev/null 2>&1; then
    echo "Key Pair '$KEY_NAME' mevcut değil, oluşturuluyor..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text --region us-east-1 > "$KEY_NAME.pem"
    chmod 400 "$KEY_NAME.pem"
else
    echo "Key Pair '$KEY_NAME' zaten mevcut, işlem atlanıyor."
fi

# Terraform'ı başlat
terraform init

# Kullanıcının yok etme isteğine göre kaynakları yok et
if [ "${DESTROY_RESOURCES}" == "true" ]; then
    echo "Kaynaklar yok ediliyor..."
    terraform destroy --auto-approve -var="ins_type=${instance_type}" -var="ins_ami=${AMI}" -var="keypair=${KEY_NAME}"
else
    echo "Kaynaklar oluşturuluyor..."
    terraform apply --auto-approve -var="ins_type=${instance_type}" -var="ins_ami=${AMI}" -var="keypair=${KEY_NAME}"
fi
---------


!!!!Burda dikkat edilecek nokta: Jenkins ara yuzundeki kullanilam parametre adlari ile execute shell de kodlarda kullanilan isimlerin birebir ayni olmasi gerekiyor!!!!


# Sonuclar ve detaylarını

Jenkins arayuzunde toplamda 5 parametre kullandik. Bunlar: workspace, ami, instance type, keypair (Choiese parametresi ile) ve destroy (boolean parametre siyle).  Bu sekilde 
istedigimiz workspace istedigimiz ami ve instance type ve keypair ile olusturabildik. Sonrasindada destroy parametresi ile olusturdugumuz bu 
makineleri sildik. Komut soyle cakkisiyor: bir if bloguyla su sarti olusturduk: Eger destroy parametresi secilmis ise o workspace direk terminate yap. 
Secilmemisse istedigimiz parametrelerde makineyi calistir. 
