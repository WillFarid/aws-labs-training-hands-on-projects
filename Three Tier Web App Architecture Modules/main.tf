# ==========================================
# 1. VPC MODULE (الشبكة متعددة النطاقات Multi-AZ)
# ==========================================
module "my_vpc" {
  source = "./modules/vpc"

  env_prefix            = var.env_prefix
  vpc_cidr              = "10.100.0.0/16"
  azs                   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  private_subnet_cidrs  = ["10.100.10.0/24", "10.100.11.0/24", "10.100.12.0/24"]
  database_subnet_cidrs = ["10.100.20.0/24", "10.100.21.0/24", "10.100.22.0/24"]
}


# ==========================================
# 2. SECURITY MODULE (الفايرول وصلاحيات IAM)
# ==========================================
module "my_security" {
  source = "./modules/security"

  env_prefix = var.env_prefix
  vpc_id     = module.my_vpc.vpc_id # ربط تلقائي برقم الشبكة الرئيسية
}


# ==========================================
# 3. STORAGE MODULE (سلة الملفات المؤمنة S3)
# ==========================================
module "my_storage" {
  source = "./modules/storage"

  env_prefix = var.env_prefix
}


# ==========================================
# 4. COMPUTE MODULE (الـ Load Balancer والسيرفرات)
# ==========================================
module "my_compute" {
  source = "./modules/compute"

  env_prefix                = var.env_prefix
  vpc_id                    = module.my_vpc.vpc_id
  public_subnet_ids         = module.my_vpc.public_subnet_ids        # تزويد الواجهة بالـ Public Subnets
  private_subnet_ids        = module.my_vpc.private_subnet_ids       # تزويد السيرفرات بالـ Private Subnets
  alb_sg_id                 = module.my_security.alb_sg_id           # ربط فايرول الواجهة
  app_sg_id                 = module.my_security.app_sg_id           # ربط فايرول السيرفرات
  app_instance_profile_name = module.my_security.app_instance_profile_name # صلاحيات سحب اللوجز
  instance_type             = "t3.micro"
}


# ==========================================
# 5. DATABASE MODULE (قاعدة البيانات المعزولة RDS)
# ==========================================
module "my_database" {
  source = "./modules/database"

  env_prefix          = var.env_prefix
  vpc_id              = module.my_vpc.vpc_id
  database_subnet_ids = module.my_vpc.database_subnet_ids    # تزويد الداتا بيز بالـ Isolated Subnets
  db_sg_id            = module.my_security.database_sg_id    # ربط فايرول الداتا بيز (مسموح للسيرفرات فقط)
  
  db_name             = "companyappdb"
  db_username         = "dbadmin"
  db_password         = var.db_password                      # كلمة المرور الحساسة
  instance_class      = "db.t3.micro"
}