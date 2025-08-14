# glassdoor-job-scraper
R script that uses RSelenium with Firefox to scrape job listings from Glassdoor, extracting titles, employers, locations, skills, and ratings.

This script is for **educational purposes only**.

# Prerequisites
**System**

- Windows 10/11 (64-bit)
- R ≥ 4.2
- Java JRE/JDK 8+ installed and on PATH (java -version must work)

**Browser & driver**

- Mozilla Firefox installed (current or ESR)
- geckodriver matching your Firefox version
- Either let RSelenium/wdman auto-download it, or put geckodriver.exe on PATH

**R packages**
- RSelenium (≥ 1.7.9)
- netstat
- purrr
- wdman and binman (for driver management)

**Script Features**
- Automates Firefox via RSelenium to open Glassdoor
- Expands job listings (clicks "Show More" if available)
- Extracts:

    - Job Title
    - Employer
    - Location
    - Skills
    - Rating

- Outputs the first 5 results in a clean format
