-- phpMyAdmin SQL Dump
-- version 5.1.1deb5ubuntu1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Sep 06, 2024 at 02:59 PM
-- Server version: 10.6.18-MariaDB-0ubuntu0.22.04.1
-- PHP Version: 8.1.2-1ubuntu2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `YouthTicketing`
--

-- --------------------------------------------------------

--
-- Table structure for table `Districts`
--

CREATE TABLE `Districts` (
  `DistrictID` tinyint(3) UNSIGNED NOT NULL,
  `DistrictName` varchar(35) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TicketedEvents`
--

CREATE TABLE `TicketedEvents` (
  `EventID` int(10) UNSIGNED NOT NULL,
  `ProgramID` tinyint(3) UNSIGNED NOT NULL,
  `EventDate` date NOT NULL,
  `TicketsHeld` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TicketedPrograms`
--

CREATE TABLE `TicketedPrograms` (
  `ProgramID` tinyint(3) UNSIGNED NOT NULL,
  `ProgramName` varchar(30) NOT NULL,
  `ProgramTime` time NOT NULL,
  `ProgramDays` set('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') NOT NULL,
  `AgeRange` varchar(15) NOT NULL,
  `SecondTierMinutes` tinyint(3) UNSIGNED NOT NULL DEFAULT 5,
  `LocationID` tinyint(3) UNSIGNED NOT NULL,
  `DefaultHeld` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `Archived` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `TicketLocations`
--

CREATE TABLE `TicketLocations` (
  `LocationID` tinyint(3) UNSIGNED NOT NULL,
  `LocationDescription` varchar(30) NOT NULL,
  `LocationCapacity` tinyint(3) UNSIGNED NOT NULL,
  `GraceSpaces` tinyint(3) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Tickets`
--

CREATE TABLE `Tickets` (
  `TicketID` int(10) UNSIGNED NOT NULL,
  `EventID` int(10) UNSIGNED NOT NULL,
  `Adults` tinyint(4) NOT NULL,
  `Children` tinyint(4) NOT NULL,
  `Identifier` binary(16) NOT NULL,
  `DistrictResidentID` tinyint(3) UNSIGNED NOT NULL,
  `Language` enum('english','spanish','polish','russian','chinese','tradchinese') NOT NULL DEFAULT 'english'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `TicketedEvents`
--
ALTER TABLE `TicketedEvents`
  ADD PRIMARY KEY (`EventID`),
  ADD KEY `TEPrograms` (`ProgramID`);

--
-- Indexes for table `TicketedPrograms`
--
ALTER TABLE `TicketedPrograms`
  ADD PRIMARY KEY (`ProgramID`),
  ADD KEY `TPLocations` (`LocationID`);

--
-- Indexes for table `TicketLocations`
--
ALTER TABLE `TicketLocations`
  ADD PRIMARY KEY (`LocationID`);

--
-- Indexes for table `Tickets`
--
ALTER TABLE `Tickets`
  ADD PRIMARY KEY (`TicketID`),
  ADD UNIQUE KEY `TicketEvent` (`EventID`,`Identifier`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `TicketedEvents`
--
ALTER TABLE `TicketedEvents`
  MODIFY `EventID` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TicketedPrograms`
--
ALTER TABLE `TicketedPrograms`
  MODIFY `ProgramID` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `TicketLocations`
--
ALTER TABLE `TicketLocations`
  MODIFY `LocationID` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Tickets`
--
ALTER TABLE `Tickets`
  MODIFY `TicketID` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `TicketedEvents`
--
ALTER TABLE `TicketedEvents`
  ADD CONSTRAINT `TEPrograms` FOREIGN KEY (`ProgramID`) REFERENCES `TicketedPrograms` (`ProgramID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `TicketedPrograms`
--
ALTER TABLE `TicketedPrograms`
  ADD CONSTRAINT `TPLocations` FOREIGN KEY (`LocationID`) REFERENCES `TicketLocations` (`LocationID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Tickets`
--
ALTER TABLE `Tickets`
  ADD CONSTRAINT `TicketEvents` FOREIGN KEY (`EventID`) REFERENCES `TicketedEvents` (`EventID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
