-- MySQL-compatible SQL Dump (reordered + charset fixed)

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `flaskshop` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `flaskshop`;

-- --------------------------------------------------------
-- Table: users
-- --------------------------------------------------------
CREATE TABLE `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` (`user_id`, `username`, `email`, `password`) VALUES
(4, 'test', 'test@test.com', 'scrypt:32768:8:1$lnaoyroesPMYe9W3$fa160bc04f4b89b4deedd8967bdcd7eb1afd59e10743b9ec03ea1c64da7a66fa5b3a5954c3d616b8d2a51a7f19ef87f0cadf325f6165ec91b297958b8ed9da90'),
(5, 'horselover123', 'ilovehorses@gmail.com', 'scrypt:32768:8:1$wyFSiAG6T4xRH2Za$4eb6c3b70a43fbf9fd39c2cd62fc1524cb0bbfc4a742ec864f43e6af6b61d84b9424b2a716189c4a23dad36d210133d03b51f2f41abf9b8d9f08728d9d29a4ac'),
(6, 'skibidi', 'skibidi@gmail.com', 'scrypt:32768:8:1$t3otECjHuZR9IeoC$c824131a4dbbe672e57a3f52d16f06f160e70386b246d319255a83ef16f1b98bf6ea4f142b2aa169cb07e6dabac53a84d6a692f5c2eacfdcab210dbe0d93108a');

-- --------------------------------------------------------
-- Table: products
-- --------------------------------------------------------
CREATE TABLE `products` (
  `product_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(6,2) DEFAULT NULL,
  PRIMARY KEY (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `products` (`product_id`, `name`, `description`, `price`) VALUES
(1, 'Classic Black Flask (32 oz)', 'A timeless classic.', 10.00),
(2, 'MITU Flask 1 (32 oz)', 'Express yourself.', 15.00),
(3, 'MITU Flask 2 (32 oz)', 'A fan favourite.', 15.00);

-- --------------------------------------------------------
-- Table: orders
-- --------------------------------------------------------
CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone_number` int(9) DEFAULT NULL,
  `order_date` date DEFAULT NULL,
  `total_amount` int(9) DEFAULT NULL,
  PRIMARY KEY (`order_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `orders` (`order_id`, `user_id`, `address`, `phone_number`, `order_date`, `total_amount`) VALUES
(6, 4, 'Testowa 9d', 485673912, '2025-01-21', 10);

-- --------------------------------------------------------
-- Table: order_items
-- --------------------------------------------------------
CREATE TABLE `order_items` (
  `order_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `price_per_unit` decimal(6,2) DEFAULT NULL,
  KEY `order_id` (`order_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;
