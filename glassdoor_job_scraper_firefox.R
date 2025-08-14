#install.packages(c("RSelenium","wdman","binman"))
#install.packages("netstat")
#install.packages("purrr")
library(RSelenium)
library(netstat)
library(purrr)

# Cleanup existing processes (Windows)
system("taskkill /im java.exe /f /t", show.output.on.console = FALSE)
system("taskkill /im geckodriver.exe /f /t", show.output.on.console = FALSE)

tryCatch({
  # Initialize Selenium
  port_number <- free_port()
  remote_Driver <- rsDriver(
    browser = "firefox",
    chromever = NULL,
    port = port_number,
    verbose = FALSE,
    check = FALSE
  )
  remDr <- remote_Driver$client
  
  # Navigate to target page
  remDr$navigate("https://www.glassdoor.de/Job/data-analyst-jobs-SRCH_KO0,12.htm")
  
  # Expand job listings
  try({
    show_more_btn <- remDr$findElement("css", "button[data-test='show-more-cta']")
    remDr$executeScript("arguments[0].scrollIntoView({behavior: 'smooth'});", list(show_more_btn))
    remDr$executeScript("arguments[0].click();", list(show_more_btn))
    Sys.sleep(2)
  }, silent = TRUE)
  
  # Extract job titles (first 5)
  job_titles <- remDr$findElements(
    "css", 
    "a[data-test='job-title']"
  ) %>% 
    map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>%
    discard(is.null) %>%
    head(5)
  
  # Extract job employers (first 5)
  job_employers <- remDr$findElements(
    "css", 
    "span.EmployerProfile_compactEmployerName__9MGcV"
  ) %>% 
    map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>%
    discard(is.null) %>%
    head(5)
  
  # Extract job locations (first 5)
  job_locations <- remDr$findElements(
    "css", 
    "div.JobCard_location__Ds1fM[data-test='emp-location']"
  ) %>% 
    map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>%
    discard(is.null) %>%
    head(5)
  
  # Extract skills (first 5)
  job_skills <- remDr$findElements(
    "css", 
    "div.JobCard_jobDescriptionSnippet__l1tnl div:nth-of-type(2)"
  ) %>% 
    map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>%
    discard(is.null) %>%
    head(5) %>%
    gsub("Kenntnisse und Fähigkeiten: ", "", .)
  
  # Extract company ratings (first 5)
  job_ratings <- remDr$findElements(
    "css", 
    "span.rating-single-star_RatingText__XENmU"
  ) %>% 
    map_chr(~try(.x$getElementText()[[1]], silent = TRUE)) %>%
    discard(is.null) %>%
    head(5)
  
  # Ensure equal length for all vectors
  max_length <- max(length(job_titles), length(job_employers), 
                    length(job_locations), length(job_skills), length(job_ratings))
  job_ratings <- head(c(job_ratings, rep(NA, max_length)), max_length)
  
  # Combine and print results
  if(length(job_titles) > 0) {
    cat("\nFirst 5 Job Listings:\n")
    
    job_data <- data.frame(
      Title = head(job_titles, 5),
      Employer = head(job_employers, 5),
      Location = head(job_locations, 5),
      Skills = head(job_skills, 5),
      Rating = head(job_ratings, 5),
      stringsAsFactors = FALSE
    )
    
    # Print formatted results
    for(i in 1:nrow(job_data)) {
      cat(paste0("- ", job_data$Title[i], " | ", 
                 job_data$Employer[i], " | ", 
                 job_data$Location[i], "\n",
                 "  Rating: ", ifelse(is.na(job_data$Rating[i]), "N/A", job_data$Rating[i]), 
                 " | Skills: ", job_data$Skills[i], "\n\n"))
    }
    
  } else {
    message("No job listings found")
  }
  
}, error = function(e) {
  message("Script failed: ", e$message)
}, finally = {
  if(exists("remDr")) try(remDr$close(), silent = TRUE)
  if(exists("remote_Driver")) try(remote_Driver$server$stop(), silent = TRUE)
  Sys.sleep(1)
})