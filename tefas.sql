-- ============================================================
-- TEFAS DATABASE SCHEMA 
-- ============================================================

-- ------------------------------------------------------------
-- 1. tefas_category
-- ------------------------------------------------------------
CREATE TABLE `tefas_category` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255) NOT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_category_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 2. tefas_periods
-- ------------------------------------------------------------
CREATE TABLE `tefas_periods` (
  `id`          INT(11)     NOT NULL,
  `period_name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `tefas_periods` (`id`, `period_name`) VALUES
(0, 'YTD'),
(1, '1 Aylık'),
(3, '3 Aylık'),
(6, '6 Aylık'),
(12, '1 Yıllık'),
(13, 'Haftalık'),
(36, '3 Yıllık'),
(60, '5 Yıllık');

-- ------------------------------------------------------------
-- 3. tefas_funds
-- ------------------------------------------------------------
CREATE TABLE `tefas_funds` (
  `id`                          INT(11)        NOT NULL AUTO_INCREMENT,
  `code`                        VARCHAR(20)    NOT NULL,
  `name`                        VARCHAR(255)   NOT NULL,
  `category_id`                 INT(11)        DEFAULT NULL,
  `isin_code`                   VARCHAR(20)    DEFAULT NULL,
  `platform_status`             VARCHAR(100)   DEFAULT NULL,
  `start_time`                  VARCHAR(10)    DEFAULT '00:00',
  `end_time`                    VARCHAR(10)    DEFAULT '17:30',
  `buy_valor`                   INT(11)        DEFAULT 0,
  `sell_valor`                  INT(11)        DEFAULT 0,
  `min_buy_amount`              DECIMAL(18,4)  DEFAULT 0.0000,
  `min_sell_amount`             DECIMAL(18,4)  DEFAULT 0.0000,
  `max_buy_amount`              DECIMAL(25,4)  DEFAULT 0.0000,
  `max_sell_amount`             DECIMAL(25,4)  DEFAULT 0.0000,
  `entry_commission`            DECIMAL(10,4)  DEFAULT 0.0000,
  `exit_commission`             DECIMAL(10,4)  DEFAULT 0.0000,
  `interest_content`            VARCHAR(255)   DEFAULT NULL,
  `risk_value`                  INT(11)        DEFAULT 0,
  `fon_varlık_dagılım_list`     TEXT           DEFAULT NULL,
  `fon_varlık_dagılım_degerler` TEXT           DEFAULT NULL,
  `updated_at`                  TIMESTAMP      NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_fund_code` (`code`),
  KEY `fk_fund_category` (`category_id`),
  CONSTRAINT `fk_fund_category` FOREIGN KEY (`category_id`) REFERENCES `tefas_category` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 4. fund_stats_history
-- ------------------------------------------------------------
CREATE TABLE `fund_stats_history` (
  `code`               VARCHAR(50)   NOT NULL,
  `created_at`         DATE          NOT NULL,
  `last_price`         DECIMAL(18,6) DEFAULT NULL,
  `daily_return`       DECIMAL(10,4) DEFAULT NULL,
  `shares_outstanding` DECIMAL(25,2) DEFAULT NULL,
  `total_value`        DECIMAL(25,2) DEFAULT NULL,
  `category`           VARCHAR(100)  DEFAULT NULL,
  `category_rank`      VARCHAR(50)   DEFAULT NULL,
  `investor_count`     INT(11)       DEFAULT NULL,
  `market_share`       DECIMAL(10,4) DEFAULT NULL,
  `return_1m`          DECIMAL(10,4) DEFAULT NULL,
  `return_3m`          DECIMAL(10,4) DEFAULT NULL,
  `return_6m`          DECIMAL(10,4) DEFAULT NULL,
  `return_1y`          DECIMAL(10,4) DEFAULT NULL,
  PRIMARY KEY (`code`, `created_at`),
  CONSTRAINT `fk_fund_code_history` FOREIGN KEY (`code`)
    REFERENCES `tefas_funds` (`code`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 5. tefas_fund_details
-- ------------------------------------------------------------
CREATE TABLE `tefas_fund_details` (
  `code`             VARCHAR(20)   NOT NULL,
  `tarih`            DATE          NOT NULL,
  `BB`               DECIMAL(15,4) DEFAULT NULL,
  `BPP`              DECIMAL(15,4) DEFAULT NULL,
  `BYF`              DECIMAL(15,4) DEFAULT NULL,
  `D`                DECIMAL(15,4) DEFAULT NULL,
  `DB`               DECIMAL(15,4) DEFAULT NULL,
  `DT`               DECIMAL(15,4) DEFAULT NULL,
  `DÖT`              DECIMAL(15,4) DEFAULT NULL,
  `EUT`              DECIMAL(15,4) DEFAULT NULL,
  `FB`               DECIMAL(15,4) DEFAULT NULL,
  `FKB`              DECIMAL(15,4) DEFAULT NULL,
  `GAS`              DECIMAL(15,4) DEFAULT NULL,
  `GSYKB`            DECIMAL(15,4) DEFAULT NULL,
  `GSYY`             DECIMAL(15,4) DEFAULT NULL,
  `GYKB`             DECIMAL(15,4) DEFAULT NULL,
  `GYY`              DECIMAL(15,4) DEFAULT NULL,
  `HB`               DECIMAL(15,4) DEFAULT NULL,
  `HS`               DECIMAL(15,4) DEFAULT NULL,
  `KBA`              DECIMAL(15,4) DEFAULT NULL,
  `KH`               DECIMAL(15,4) DEFAULT NULL,
  `KHAU`             DECIMAL(15,4) DEFAULT NULL,
  `KHD`              DECIMAL(15,4) DEFAULT NULL,
  `KHTL`             DECIMAL(15,4) DEFAULT NULL,
  `KKS`              DECIMAL(15,4) DEFAULT NULL,
  `KKSD`             DECIMAL(15,4) DEFAULT NULL,
  `KKSTL`            DECIMAL(15,4) DEFAULT NULL,
  `KKSYD`            DECIMAL(15,4) DEFAULT NULL,
  `KM`               DECIMAL(15,4) DEFAULT NULL,
  `KMBYF`            DECIMAL(15,4) DEFAULT NULL,
  `KMKBA`            DECIMAL(15,4) DEFAULT NULL,
  `KMKKS`            DECIMAL(15,4) DEFAULT NULL,
  `KİBD`             DECIMAL(15,4) DEFAULT NULL,
  `OSKS`             DECIMAL(15,4) DEFAULT NULL,
  `OST`              DECIMAL(15,4) DEFAULT NULL,
  `R`                DECIMAL(15,4) DEFAULT NULL,
  `T`                DECIMAL(15,4) DEFAULT NULL,
  `TPP`              DECIMAL(15,4) DEFAULT NULL,
  `TR`               DECIMAL(15,4) DEFAULT NULL,
  `VDM`              DECIMAL(15,4) DEFAULT NULL,
  `VM`               DECIMAL(15,4) DEFAULT NULL,
  `VMAU`             DECIMAL(15,4) DEFAULT NULL,
  `VMD`              DECIMAL(15,4) DEFAULT NULL,
  `VMTL`             DECIMAL(15,4) DEFAULT NULL,
  `VİNT`             DECIMAL(15,4) DEFAULT NULL,
  `YBA`              DECIMAL(15,4) DEFAULT NULL,
  `YBKB`             DECIMAL(15,4) DEFAULT NULL,
  `YBOSB`            DECIMAL(15,4) DEFAULT NULL,
  `YBYF`             DECIMAL(15,4) DEFAULT NULL,
  `YHS`              DECIMAL(15,4) DEFAULT NULL,
  `YMK`              DECIMAL(15,4) DEFAULT NULL,
  `YYF`              DECIMAL(15,4) DEFAULT NULL,
  `ÖKSYD`            DECIMAL(15,4) DEFAULT NULL,
  `ÖSDB`             DECIMAL(15,4) DEFAULT NULL,
  `BilFiyat`         DECIMAL(25,2) DEFAULT NULL,
  `FIYAT`            DECIMAL(18,6) DEFAULT NULL,
  `TEDPAYSAYISI`     DECIMAL(20,2) DEFAULT NULL,
  `KISISAYISI`       INT(11)       DEFAULT NULL,
  `PORTFOYBUYUKLUK`  DECIMAL(20,2) DEFAULT NULL,
  `BORSABULTENFIYAT` VARCHAR(20)   DEFAULT NULL,
  PRIMARY KEY (`code`, `tarih`),
  CONSTRAINT `fk_tefas_funds` FOREIGN KEY (`code`)
    REFERENCES `tefas_funds` (`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 6. tefas_best_category_rates
-- ------------------------------------------------------------
CREATE TABLE `tefas_best_category_rates` (
  `id`            INT(11)       NOT NULL AUTO_INCREMENT,
  `category_id`   INT(11)       NOT NULL,
  `period_id`     INT(11)       NOT NULL,
  `getiri`        DECIMAL(18,4) DEFAULT NULL,
  `pazarbuyukluk` DECIMAL(30,4) DEFAULT NULL,
  `fetched_at`    DATE          NOT NULL,
  `created_at`    TIMESTAMP     NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cat_period_date` (`category_id`, `period_id`, `fetched_at`),
  KEY `fk_cat_period` (`period_id`),
  CONSTRAINT `fk_cat_category` FOREIGN KEY (`category_id`)
    REFERENCES `tefas_category` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cat_period` FOREIGN KEY (`period_id`)
    REFERENCES `tefas_periods` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 7. tefas_best_fund_rates
-- ------------------------------------------------------------
CREATE TABLE `tefas_best_fund_rates` (
  `id`          INT(11)       NOT NULL AUTO_INCREMENT,
  `fund_id`     INT(11)       NOT NULL,
  `category_id` INT(11)       DEFAULT NULL,
  `period_id`   INT(11)       NOT NULL,
  `rate`        DECIMAL(18,4) DEFAULT NULL,
  `fetched_at`  DATE          NOT NULL,
  `created_at`  TIMESTAMP     NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fund_period_date` (`fund_id`, `period_id`, `fetched_at`),
  KEY `fk_rate_period` (`period_id`),
  KEY `fk_rate_category` (`category_id`),
  CONSTRAINT `fk_rate_category` FOREIGN KEY (`category_id`)
    REFERENCES `tefas_category` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rate_fund` FOREIGN KEY (`fund_id`)
    REFERENCES `tefas_funds` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rate_period` FOREIGN KEY (`period_id`)
    REFERENCES `tefas_periods` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 8. tefas_comparison_history
-- ------------------------------------------------------------
CREATE TABLE `tefas_comparison_history` (
  `id`                INT(11)     NOT NULL AUTO_INCREMENT,
  `fund_code`         VARCHAR(20) NOT NULL,
  `period_id`         INT(11)     NOT NULL,
  `comparison_names`  LONGTEXT    DEFAULT NULL,
  `comparison_values` LONGTEXT    DEFAULT NULL,
  `fetched_at`        DATE        NOT NULL,
  `created_at`        TIMESTAMP   NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fund_period_date` (`fund_code`, `period_id`, `fetched_at`),
  KEY `idx_fund_code` (`fund_code`),
  KEY `idx_period_id` (`period_id`),
  CONSTRAINT `fk_comparison_fund` FOREIGN KEY (`fund_code`)
    REFERENCES `tefas_funds` (`code`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_comparison_period` FOREIGN KEY (`period_id`)
    REFERENCES `tefas_periods` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 9. tefas_trend_checking
-- ------------------------------------------------------------
CREATE TABLE `tefas_trend_checking` (
  `id`              INT(11)       NOT NULL AUTO_INCREMENT,
  `fund_code`       VARCHAR(20)   NOT NULL,
  `period_days`     INT(11)       NOT NULL,
  `up_days_count`   INT(11)       DEFAULT 0,
  `down_days_count` INT(11)       DEFAULT 0,
  `total_return`    DECIMAL(10,4) DEFAULT NULL,
  `analysis_date`   DATE          NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fund_period_date` (`fund_code`, `period_days`, `analysis_date`),
  CONSTRAINT `fk_checking_fund` FOREIGN KEY (`fund_code`) 
    REFERENCES `tefas_funds` (`code`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 10. tefas_trend_analysis
-- ------------------------------------------------------------
CREATE TABLE `tefas_trend_analysis` (
  `id`             INT(11)       NOT NULL AUTO_INCREMENT,
  `fund_code`      VARCHAR(20)   NOT NULL,
  `period_days`    INT(11)       NOT NULL,
  `change_percent` DECIMAL(10,4) DEFAULT 0.0000,
  `last_price`     DECIMAL(18,6) NOT NULL,
  `analysis_date`  DATE          NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fund_period_date` (`fund_code`, `period_days`, `analysis_date`),
  CONSTRAINT `fk_analysis_fund` FOREIGN KEY (`fund_code`) 
    REFERENCES `tefas_funds` (`code`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
