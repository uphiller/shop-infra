CREATE SCHEMA IF NOT EXISTS metering
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

-- 사용자 생성
CREATE USER 'metering_user'@'%' IDENTIFIED BY 'aB3#9kL!2pQz';

-- metering 스키마에 대한 모든 권한 부여
GRANT ALL PRIVILEGES ON metering.* TO 'metering_user'@'%';